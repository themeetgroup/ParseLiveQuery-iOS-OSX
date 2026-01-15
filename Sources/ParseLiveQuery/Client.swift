/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation
import Network
import TMGParseCore
import BoltsSwift

/**
 This is the 'advanced' view of live query subscriptions. It allows you to customize your subscriptions
 to a live query server, have connections to multiple servers, cleanly handle disconnect and reconnect.
 */
@objc(PFLiveQueryClient)
open class Client: NSObject {
    let host: URL
    let applicationId: String
    let clientKey: String?

    // URLSession-based websocket.
    //
    // Lifecycle note: `URLSession` strongly retains its delegate (this `Client`) until
    // `invalidateAndCancel()` is called, which happens in `disconnect()`. A `Client` is therefore
    // only released after you call `disconnect()` — dropping it without disconnecting leaks the
    // client and keeps its receive loop / ping timer running. The shared `Client.shared` singleton
    // is intentionally immortal, so this does not affect the common path.
    var session: URLSession?
    var socket: URLSessionWebSocketTask?

    /// Used to track sockets/tasks that are disconnecting
    var disconnectingSockets: Set<PLQDisconnectingSocket> = Set<PLQDisconnectingSocket>()

    public var shouldPrintWebSocketLog = true
    public var shouldPrintWebSocketTrace = false
    public var userDisconnected = false
    var isConnecting = false
    /// True only after the LiveQuery `.connected` handshake completes (not merely when the socket
    /// task exists). Subscriptions sent before this are rejected by the server.
    var isConnected = false

    /// The time in milliseconds we should wait before pinging the socket
    /// when we receive no data. If nil, no timer will be used.
    public var pingTimerDelayMs: Int? = nil
    /// Timer to ping the socket if we get no data for a set period of time
    var pingTimer: DispatchSourceTimer? = nil

    /// Consecutive failure count for the reconnect backoff; reset to 0 on a successful handshake.
    var reconnectAttempts = 0
    /// Pending delayed-reconnect timer (exponential backoff). Cancelled on an immediate reconnect.
    var reconnectTimer: DispatchSourceTimer? = nil

    // This allows us to easily plug in another request ID generation scheme, or more easily change the request id type
    // if needed (technically this could be a string).
    let requestIdGenerator: () -> RequestId
    var subscriptions = [SubscriptionRecord]()

    let queue = DispatchQueue(label: "com.parse.livequery", attributes: [])

    // Receive loop control
    var isReceiving = false

    /// Monitors the system network path so the client can reconnect when connectivity is **restored**.
    /// `URLSessionWebSocketTask` gives no "connectivity came back" signal, and a silently-dropped
    /// socket's `receive`/`sendPing` can hang without erroring — so without this the client would sit
    /// on a dead socket after a network blip (e.g. Wi-Fi off/on) until something else forced a reconnect.
    private let pathMonitor = NWPathMonitor()
    /// Serial queue that delivers `pathMonitor` updates; `lastPathSignature` is only touched here.
    private let pathMonitorQueue = DispatchQueue(label: "com.parse.livequery.pathmonitor")
    /// Signature of the last observed path: reachability + the primary interface carrying traffic.
    /// `nil` until the first update. We reconnect when this changes to a usable path — covering both
    /// offline->online AND wifi<->cellular handoffs (which keep the path `.satisfied` but strand the
    /// socket on the old, now-dead interface).
    private var lastPathSignature: String?

    /**
     Creates a Client which automatically attempts to connect to the custom parse-server URL set in Parse.currentConfiguration().
     */
    public override convenience init() {
        self.init(server: Parse.validatedCurrentConfiguration().server)
    }

    /**
     Creates a client which will connect to a specific server with an optional application id and client key

     - parameter server:        The server to connect to
     - parameter applicationId: The application id to use
     - parameter clientKey:     The client key to use
     */
    @objc(initWithServer:applicationId:clientKey:)
    public init(server: String, applicationId: String? = nil, clientKey: String? = nil) {
        guard let cmpts = URLComponents(string: server) else {
            fatalError("Server should be a valid URL.")
        }
        var components = cmpts
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"

        // Simple incrementing generator - can't use ++, that operator is deprecated!
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }

        self.applicationId = applicationId ?? Parse.validatedCurrentConfiguration().applicationId!
        self.clientKey = clientKey ?? Parse.validatedCurrentConfiguration().clientKey

        self.host = components.url!

        super.init()
        startPathMonitoring()
    }

    deinit {
        pathMonitor.cancel()
    }
}

extension Client {
    // Swift is lame and doesn't allow storage to directly be in extensions.
    // So we create an inner struct to wrap it up.
    fileprivate class Storage {
        private static var __once: () = {
            sharedStorage = Storage()
        }()
        static var onceToken: Int = 0
        static var sharedStorage: Storage!
        static var shared: Storage {
            _ = Storage.__once
            return sharedStorage
        }

        let queue: DispatchQueue = DispatchQueue(label: "com.parse.livequery.client.storage", attributes: [])
        var client: Client?
    }

    /// Gets or sets shared live query client to be used for default subscriptions
    @objc(sharedClient)
    public static var shared: Client! {
        get {
            let storage = Storage.shared
            var client: Client?
            storage.queue.sync {
                client = storage.client
                if client == nil {
                    let configuration = Parse.validatedCurrentConfiguration()
                    client = Client(
                        server: configuration.server,
                        applicationId: configuration.applicationId,
                        clientKey: configuration.clientKey
                    )
                    storage.client = client
                }
            }
            return client
        }
        set {
            let storage = Storage.shared
            storage.queue.sync {
                storage.client = newValue
            }
        }
    }
}

extension Client {
    /**
     Registers a query for live updates, using the default subscription handler

     - parameter query:        The query to register for updates.
     - parameter subclassType: The subclass of PFObject to be used as the type of the Subscription.
     This parameter can be automatically inferred from context most of the time

     - returns: The subscription that has just been registered
     */
    public func subscribe<T>(
        _ query: PFQuery<T>,
        subclassType: T.Type = T.self
    ) -> Subscription<T> {
        return subscribe(query, handler: Subscription<T>())
    }

    /**
     Registers a query for live updates, using a custom subscription handler

     - parameter query:   The query to register for updates.
     - parameter handler: A custom subscription handler.

     - returns: Your subscription handler, for easy chaining.
     */
    public func subscribe<T>(
        _ query: PFQuery<T.PFObjectSubclass>,
        handler: T
    ) -> T where T: SubscriptionHandling {
        // Register on `queue` so `subscriptions`, the request-id generator, and the socket read are
        // serialized with the delegate callbacks. The handler is still returned synchronously.
        queue.async { [weak self] in
            guard let self = self else { return }

            let subscriptionRecord = SubscriptionRecord(
                query: query,
                requestId: self.requestIdGenerator(),
                handler: handler
            )
            self.subscriptions.append(subscriptionRecord)

            if self.isConnected {
                // Protocol handshake done — send the subscribe now.
                _ = self.sendOperationAsync(.subscribe(
                    requestId: subscriptionRecord.requestId,
                    query: query as! PFQuery<PFObject>,
                    sessionToken: PFUser.current()?.sessionToken
                ))
            } else if self.socket == nil && !self.userDisconnected {
                // Not connected and no socket in flight — start connecting; the `.connected`
                // handler resubscribes every record once the handshake completes.
                self.reconnectOnQueue()
            } else if self.userDisconnected {
                NSLog("ParseLiveQuery: Warning: The client was explicitly disconnected! You must explicitly call .reconnect() in order to process your subscriptions.")
            }
            // else: a socket is connecting — the `.connected` handler will resubscribe this record.
        }

        return handler
    }

    /**
     Updates an existing subscription with a new query.
     Upon completing the registration, the subscribe handler will be called with the new query

     - parameter handler: The specific handler to update.
     - parameter query:   The new query for that handler.
     */
    public func update<T>(
        _ handler: T,
        toQuery query: PFQuery<T.PFObjectSubclass>
    ) where T: SubscriptionHandling {
        // Serialize `subscriptions` mutation onto `queue` (shared with the delegate callbacks).
        queue.async { [weak self] in
            guard let self = self else { return }
            self.subscriptions = self.subscriptions.map {
                if $0.subscriptionHandler === handler {
                    // Only send on the wire when the handshake is complete; otherwise just update
                    // the local record so the `.connected` resubscribe carries the new query.
                    if self.isConnected {
                        _ = self.sendOperationAsync(.update(requestId: $0.requestId, query: query as! PFQuery<PFObject>))
                    }
                    return SubscriptionRecord(query: query, requestId: $0.requestId, handler: $0.subscriptionHandler as! T)
                }
                return $0
            }
        }
    }

    /**
     Unsubscribes all current subscriptions for a given query.

     - parameter query: The query to unsubscribe from.
     */
    @objc(unsubscribeFromQuery:)
    public func unsubscribe(_ query: PFQuery<PFObject>) {
        unsubscribe { $0.query == query }
    }

    /**
     Unsubscribes from a specific query-handler pair.

     - parameter query:   The query to unsubscribe from.
     - parameter handler: The specific handler to unsubscribe from.
     */
    public func unsubscribe<T>(_ query: PFQuery<T.PFObjectSubclass>, handler: T) where T: SubscriptionHandling {
        unsubscribe { $0.query == query && $0.subscriptionHandler === handler }
    }

    func unsubscribe(matching matcher: @escaping (SubscriptionRecord) -> Bool) {
        // Serialize `subscriptions` mutation onto `queue` (shared with the delegate callbacks).
        queue.async { [weak self] in
            guard let self = self else { return }
            var temp = [SubscriptionRecord]()
            self.subscriptions.forEach {
                if matcher($0) {
                    // Notify the server only when connected; the local record is removed regardless,
                    // so a later reconnect won't resubscribe it.
                    if self.isConnected {
                        _ = self.sendOperationAsync(.unsubscribe(requestId: $0.requestId))
                    }
                } else {
                    temp.append($0)
                }
            }
            self.subscriptions = temp
        }
    }
}

extension Client {
    /**
     Reconnects this client to the server.

     This will disconnect and resubscribe all existing subscriptions. This is not required to be called the first time
     you use the client, and should usually only be called when an error occurs.
     */
    @objc(reconnect)
    public func reconnect() {
        // Serialize onto `queue` so socket/session state isn't raced with the delegate callbacks
        // (which run on `queue`); this also collapses concurrent reconnect() calls behind the guard.
        // User-initiated, so reset backoff (only if the reconnect actually proceeds — see the guard
        // inside `reconnectOnQueue`).
        queue.async { [weak self] in self?.reconnectOnQueue(resetBackoff: true) }
    }

    /// Schedule a reconnect with exponential backoff (+ jitter, capped). Used by failure paths so a
    /// persistent failure doesn't spin in a tight reconnect/session-churn loop. Must be called on
    /// `queue`. `reconnectAttempts` is reset to 0 on a successful handshake (`.connected`).
    func scheduleReconnect() {
        guard !userDisconnected else { return }
        // A reconnect is already pending — don't stack another.
        guard reconnectTimer == nil else { return }

        let attempt = reconnectAttempts
        reconnectAttempts += 1

        // First attempt: reconnect immediately rather than via a 0-delay timer (which would add an
        // event-loop hop).
        guard attempt > 0 else {
            reconnectOnQueue()
            return
        }

        // Then 0.5s, 1s, 2s, … capped at 30s, plus up to 20% jitter.
        let delay = min(30.0, 0.5 * pow(2.0, Double(attempt - 1)))
        let total = delay + Double.random(in: 0...(delay * 0.2))

        let timer = DispatchSource.makeTimerSource(queue: queue)
        reconnectTimer = timer
        timer.schedule(wallDeadline: .now() + total)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.reconnectTimer = nil
            self.reconnectOnQueue()
        }
        timer.resume()
    }

    /// Body of `reconnect()`. Must be called on `queue`.
    /// - Parameter resetBackoff: when `true` (user-initiated reconnect), reset the backoff counter —
    ///   but only after the guard, so a no-op reconnect (already connecting) doesn't wipe it.
    func reconnectOnQueue(resetBackoff: Bool = false) {
        // We're reconnecting now — drop any pending delayed reconnect.
        reconnectTimer?.cancel()
        reconnectTimer = nil

        guard socket == nil || !isConnecting else { return }

        if resetBackoff { reconnectAttempts = 0 }

        // Mark early to prevent re-entrant reconnect storms from stale callbacks.
        isConnecting = true

        // cancel existing task (if any) but keep completion tracking consistent
        if let existing = socket {
            disconnectingSockets.insert(.init(task: existing, completion: { [weak self] disconnected in
                self?.disconnectingSockets.remove(disconnected)
            }))
            existing.cancel(with: .goingAway, reason: nil)
        }

        // Invalidate any existing session before creating a new one (prevents session/queue buildup).
        session?.invalidateAndCancel()
        session = nil

        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        // Setting `underlyingQueue = queue` means URLSession schedules BOTH delegate callbacks and
        // the send/receive/sendPing *completion handlers* on `queue` (per the URLSession docs:
        // "An operation queue for scheduling the delegate calls and completion handlers"). That's
        // what keeps all socket/session state access serialized on the single state-machine queue.
        opQueue.underlyingQueue = queue

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: opQueue)
        self.session = session

        let request = URLRequest(url: host)

        let task = session.webSocketTask(with: request)
        self.socket = task
        userDisconnected = false
        isReceiving = false
        isConnected = false
        task.resume()
    }

    /// Starts monitoring the system network path so a restored/changed connection triggers a reconnect.
    private func startPathMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }

    /// Reconnects when the network path changes to a usable state. Runs on `pathMonitorQueue`, so
    /// `lastPathSignature` needs no extra locking.
    ///
    /// The signature combines reachability with the *primary interface*, so we react not only to
    /// offline->online but also to wifi<->cellular handoffs: on a cellular-capable device, turning
    /// Wi-Fi off keeps `status == .satisfied` (traffic falls back to cellular) yet the existing
    /// socket is bound to the dead Wi-Fi connection. `URLSessionWebSocketTask` doesn't migrate
    /// interfaces, so we must reconnect. The first reading is recorded but not acted on (monitoring
    /// starts on an already-usable path during normal operation, which must not force a reconnect).
    /// - Parameter path: The current network path.
    private func handlePathUpdate(_ path: NWPath) {
        let satisfied = path.status == .satisfied
        // Primary interface = the most-preferred available one, i.e. the one carrying our traffic.
        let primaryInterface = path.availableInterfaces.first.map { String(describing: $0.type) } ?? "none"
        let signature = "\(satisfied):\(primaryInterface)"

        let previous = lastPathSignature
        lastPathSignature = signature
        // Act only on a genuine change to a usable path (offline->online or an interface handoff).
        guard let previous, previous != signature, satisfied else { return }

        queue.async { [weak self] in
            guard let self = self else { return }
            // Only reconnect if we're meant to have a live connection: not an explicit user
            // disconnect, not already mid-connect, and we actually have subscriptions to restore.
            // Reset backoff so a network change reconnects promptly instead of waiting on a pending timer.
            guard !self.userDisconnected, !self.isConnecting, !self.subscriptions.isEmpty else { return }
            if self.shouldPrintWebSocketLog {
                NSLog("ParseLiveQuery: network path changed to a usable route; reconnecting")
            }
            self.reconnectOnQueue(resetBackoff: true)
        }
    }


    /**
     Explicitly disconnects this client from the server.

     This does not remove any subscriptions - if you `reconnect()` your existing subscriptions will be restored.
     Use this if you wish to dispose of the live query client.
     */
    @objc(disconnect)
    public func disconnect() {
        disconnect(completion: nil)
    }

    /// This functions the same as disconnect except it also has a completion handler
    /// - Parameter completion: Called when disconnected
    public func disconnect(completion: (() -> Void)?) {
        // Serialize onto `queue` (shared with the delegate callbacks) to avoid racing socket state.
        queue.async { [weak self] in self?.disconnectOnQueue(completion: completion) }
    }

    /// Body of `disconnect(completion:)`. Must be called on `queue`.
    private func disconnectOnQueue(completion: (() -> Void)?) {
        isConnecting = false
        stopPingTimer()
        isReceiving = false
        isConnected = false
        reconnectTimer?.cancel()
        reconnectTimer = nil
        reconnectAttempts = 0
        // Record the explicit-disconnect intent up front, regardless of socket state, so a later
        // subscribe() won't auto-reconnect after a disconnect issued while no task was active.
        userDisconnected = true

        guard let task = socket else {
            // No active task, but a session may still linger (e.g. after a failed task) and keep
            // retaining this client — invalidate it, then finish.
            session?.invalidateAndCancel()
            session = nil
            completion?()
            return
        }

        disconnectingSockets.insert(.init(task: task, completion: { [weak self] disconnected in
            self?.disconnectingSockets.remove(disconnected)
            completion?()
        }))

        task.cancel(with: .normalClosure, reason: nil)
        socket = nil

        session?.invalidateAndCancel()
        session = nil
    }
}

/// An object that will handle disconnecting a task and notifying the owner
class PLQDisconnectingSocket: Hashable {
    /// The id of this class
    let id = UUID()
    /// The task to match close/completion callbacks by object identity (taskIdentifier is only
    /// unique within a session, so it can't disambiguate tasks across reconnect's new sessions).
    let task: URLSessionTask
    /// The completion handler to notify when the socket is closed
    let completion: ((PLQDisconnectingSocket) -> Void)

    init(task: URLSessionTask, completion: @escaping ((PLQDisconnectingSocket) -> Void)) {
        self.task = task
        self.completion = completion
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PLQDisconnectingSocket, rhs: PLQDisconnectingSocket) -> Bool {
        lhs.id == rhs.id
    }
}
