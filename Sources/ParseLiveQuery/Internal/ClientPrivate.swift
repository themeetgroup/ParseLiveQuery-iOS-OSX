/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation
import TMGParseCore
import BoltsSwift

private func parseObject<T: PFObject>(_ objectDictionary: [String:AnyObject]) throws -> T {
    guard let _ = objectDictionary["className"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "parseClassName")
    }
    guard let _ = objectDictionary["objectId"] as? String else {
        throw LiveQueryErrors.InvalidJSONError(json: objectDictionary, expectedKey: "objectId")
    }

    guard let object =  PFDecoder.object().decode(objectDictionary) as? T else {
        throw LiveQueryErrors.InvalidJSONObject(json: objectDictionary, details: "cannot decode json into \(T.self)")
    }

    return object
}

// ---------------
// MARK: Subscriptions
// ---------------

extension Client {
    class SubscriptionRecord {
        var subscriptionHandler: AnyObject?
        var eventHandlerClosure: (Event<PFObject>, Client) -> Void
        var errorHandlerClosure: (Error, Client) -> Void
        var subscribeHandlerClosure: (Client) -> Void
        var unsubscribeHandlerClosure: (Client) -> Void

        let query: PFQuery<PFObject>
        let requestId: RequestId

        init<T>(query: PFQuery<T.PFObjectSubclass>, requestId: RequestId, handler: T) where T:SubscriptionHandling {
            self.query = query as! PFQuery<PFObject>
            self.requestId = requestId

            subscriptionHandler = handler

            eventHandlerClosure = { _, _ in }
            errorHandlerClosure = { _, _ in }
            subscribeHandlerClosure = { _ in }
            unsubscribeHandlerClosure = { _ in }

            eventHandlerClosure = { [weak self] event, client in
                guard let handler = self?.subscriptionHandler as? T else { return }
                handler.didReceive(Event(event: event), forQuery: query, inClient: client)
            }

            errorHandlerClosure = { [weak self] error, client in
                guard let handler = self?.subscriptionHandler as? T else { return }
                handler.didEncounter(error, forQuery: query, inClient: client)
            }

            subscribeHandlerClosure = { [weak self] client in
                guard let handler = self?.subscriptionHandler as? T else { return }
                handler.didSubscribe(toQuery: query, inClient: client)
            }

            unsubscribeHandlerClosure = { [weak self] client in
                guard let handler = self?.subscriptionHandler as? T else { return }
                handler.didUnsubscribe(fromQuery: query, inClient: client)
            }
        }
    }
}

extension Client {
    struct RequestId: Equatable {
        let value: Int
        init(value: Int) { self.value = value }
    }
}

func == (first: Client.RequestId, second: Client.RequestId) -> Bool {
    return first.value == second.value
}

// ---------------
// MARK: Web Socket (URLSessionWebSocketTask)
// ---------------

extension Client: URLSessionWebSocketDelegate {

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // Ignore stale opens from old tasks/sessions.
        guard isCurrent(webSocketTask) else { return }

        stopPingTimer()
        isConnecting = false

        let sessionToken = PFUser.current()?.sessionToken ?? ""
        _ = self.sendOperationAsync(.connect(applicationId: applicationId, sessionToken: sessionToken, clientKey: clientKey))

        startPingTimer()
        startReceiveLoopIfNeeded()
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // Always notify trackers (even for stale tasks).
        notifyDisconnectingIfNeeded(for: webSocketTask)

        // Ignore stale closes from old tasks/sessions.
        guard isCurrent(webSocketTask) else { return }

        stopPingTimer()
        isConnecting = false
        isReceiving = false
        isConnected = false

        if shouldPrintWebSocketLog {
            NSLog("ParseLiveQuery: WebSocket did close. code:\(closeCode.rawValue)")
        }

        // The task is terminal; drop our reference so the reconnect below doesn't register a
        // disconnect-tracker for an already-dead task — its `cancel()` would be a no-op that never
        // fires a callback to remove the tracker (a slow leak across repeated failures).
        socket = nil

        // Reconnect with exponential backoff unless `disconnect()` was explicitly called.
        if !userDisconnected {
            scheduleReconnect()
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Always notify trackers (even for stale tasks).
        notifyDisconnectingIfNeeded(for: task)

        // Ignore stale completions from old tasks/sessions.
        guard isCurrent(task) else { return }

        stopPingTimer()
        isConnecting = false
        isReceiving = false
        isConnected = false

        if let error = error, shouldPrintWebSocketLog {
            NSLog("ParseLiveQuery: WebSocket task completed with error: \(error)")
        }

        // The task is terminal; drop our reference so the reconnect below doesn't register a
        // disconnect-tracker for an already-dead task — its `cancel()` would be a no-op that never
        // fires a callback to remove the tracker (a slow leak across repeated failures).
        socket = nil

        // Reconnect with exponential backoff unless `disconnect()` was explicitly called.
        if !userDisconnected {
            scheduleReconnect()
        }
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        // Recommended by URLSession's docs: the session releases its strong reference to this
        // delegate after this fires. No action needed — `reconnect()` builds a fresh session.
    }

    // Staleness is compared by object identity, not `taskIdentifier`: the latter is only unique
    // within a single `URLSession`, and every reconnect/disconnect builds a brand-new session whose
    // task ids restart low — so a fresh task could collide with a just-cancelled one and a stale
    // callback would tear down the live socket.
    private func isCurrent(_ task: URLSessionTask) -> Bool {
        task === socket
    }

    private func notifyDisconnectingIfNeeded(for task: URLSessionTask) {
        // match by task object identity
        if let match = disconnectingSockets.first(where: { $0.task === task }) {
            match.completion(match)
        }
    }

    private func startReceiveLoopIfNeeded() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isReceiving else { return }
            self.isReceiving = true
            self.receiveNext()
        }
    }

    private func receiveNext() {
        guard let task = socket else { return }

        task.receive { [weak self] result in
            guard let self = self else { return }

            // Stale task (a reconnect swapped sockets): stop this loop silently, without touching
            // the current loop's `isReceiving` flag. Identity check (not taskIdentifier) — see `isCurrent`.
            guard self.socket === task else { return }

            // Current task, but the user disconnected: end the loop and clear the flag.
            guard !self.userDisconnected else {
                self.isReceiving = false
                return
            }

            self.stopPingTimer()

            switch result {
            case .failure(let error):
                if self.shouldPrintWebSocketLog {
                    NSLog("ParseLiveQuery: WebSocket receive failed: \(error)")
                }
                self.isReceiving = false
                self.isConnecting = false
                self.isConnected = false
                // Drop the dead task (mirrors didClose/didComplete) so the pending reconnect doesn't
                // register a tracker for it, and the task's later didCompleteWithError no-ops via isCurrent.
                self.socket = nil

                if !self.userDisconnected {
                    self.scheduleReconnect()
                }

            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleOperationAsync(text, task: task).continueWith { [weak self] task in
                        if let error = task.error, self?.shouldPrintWebSocketLog == true {
                            NSLog("ParseLiveQuery: Error processing message: \(error)")
                        }
                    }

                case .data(_):
                    if self.shouldPrintWebSocketLog {
                        NSLog("ParseLiveQuery: Received binary data but we don't handle it...")
                    }

                @unknown default:
                    break
                }

                self.startPingTimer()
                self.receiveNext()
            }
        }
    }

    /// Stop the ping timer. Must be called on `queue`.
    func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    /// Start (or restart) the one-shot ping timer. Must be called on `queue`; the timer fires on
    /// `queue` as well, so `socket`/state reads stay consistent with the rest of the state machine.
    func startPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil

        guard !isConnecting, let delay = pingTimerDelayMs, delay > 0 else { return }

        let timer = DispatchSource.makeTimerSource(queue: queue)
        pingTimer = timer

        timer.schedule(wallDeadline: .now() + .milliseconds(delay))
        timer.setEventHandler { [weak self] in
            guard let self = self, !self.isConnecting else { return }
            if self.shouldPrintWebSocketLog { NSLog("ParseLiveQuery: Sending ping") }

            guard let task = self.socket else { return }
            task.sendPing { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    if self.shouldPrintWebSocketLog {
                        NSLog("ParseLiveQuery: Ping failed: \(error)")
                    }

                    // Ignore stale ping failures from a swapped task; only the active task may
                    // trigger a reconnect.
                    guard self.socket === task, !self.userDisconnected else { return }
                    self.stopPingTimer()
                    self.scheduleReconnect()
                } else if self.socket === task {
                    // Ping acknowledged (pong). The timer is one-shot, so reschedule the next
                    // keep-alive ping; otherwise monitoring stops during quiet periods.
                    self.startPingTimer()
                }
            }
        }

        timer.resume()
    }

}

// -------------------
// MARK: Operations
// -------------------

extension Event {
    init(serverResponse: ServerResponse, requestId: inout Client.RequestId) throws {
        switch serverResponse {
        case .enter(let reqId, let object):
            requestId = reqId
            self = .entered(try parseObject(object))
        case .leave(let reqId, let object):
            requestId = reqId
            self = .left(try parseObject(object))
        case .create(let reqId, let object):
            requestId = reqId
            self = .created(try parseObject(object))
        case .update(let reqId, let object):
            requestId = reqId
            self = .updated(try parseObject(object))
        case .delete(let reqId, let object):
            requestId = reqId
            self = .deleted(try parseObject(object))
        default:
            fatalError("Invalid state reached")
        }
    }
}

extension Client {
    fileprivate func subscriptionRecord(_ requestId: RequestId) -> SubscriptionRecord? {
        guard let recordIndex = self.subscriptions.firstIndex(where: { $0.requestId == requestId }) else {
            return nil
        }
        let record = self.subscriptions[recordIndex]
        return record.subscriptionHandler != nil ? record : nil
    }

    func sendOperationAsync(_ operation: ClientOperation) -> Task<Void> {
        return Task(.queue(queue)) {
            let jsonEncoded = operation.JSONObjectRepresentation
            let jsonData = try JSONSerialization.data(withJSONObject: jsonEncoded, options: JSONSerialization.WritingOptions(rawValue: 0))
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw LiveQueryErrors.InvalidResponseError(
                    response: "Internal error: JSONSerialization produced data that could not be decoded as UTF-8. This should never happen.")
            }

            if self.shouldPrintWebSocketTrace { NSLog("ParseLiveQuery: Sending message: \(jsonString)") }

            // Capture the task so a stale completion (after a reconnect swapped sockets) can't
            // trigger a reconnect against the current socket.
            guard let task = self.socket else { return }
            task.send(.string(jsonString)) { [weak self] error in
                guard let self = self, let error = error else { return }

                if self.shouldPrintWebSocketLog {
                    NSLog("ParseLiveQuery: Error sending message: \(error)")
                }

                // Treat send failure as a broken connection — but only if this is still the active
                // task and the user hasn't explicitly disconnected.
                guard self.socket === task, !self.userDisconnected else { return }
                self.scheduleReconnect()
            }

        }
    }

    func handleOperationAsync(_ string: String, task: URLSessionWebSocketTask) -> Task<Void> {
        return Task(.queue(queue)) {
            // Handling is deferred to this queued block, so re-check identity: a reconnect may have
            // swapped sockets since the frame was received. Applying a stale message here (e.g. a
            // `.connected` from the old socket) would corrupt the new connection's state.
            guard self.socket === task else { return }

            if self.shouldPrintWebSocketTrace { NSLog("ParseLiveQuery: Received message: \(string)") }
            guard
                let jsonData = string.data(using: .utf8),
                let jsonDecoded = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String:AnyObject],
                let response: ServerResponse = try? ServerResponse(json: jsonDecoded)
            else {
                throw LiveQueryErrors.InvalidResponseError(response: string)
            }

            switch response {
            case .connected:
                self.isConnected = true
                self.reconnectAttempts = 0
                let sessionToken = PFUser.current()?.sessionToken
                self.subscriptions.forEach {
                    _ = self.sendOperationAsync(.subscribe(requestId: $0.requestId, query: $0.query, sessionToken: sessionToken))
                }

            case .redirect:
                // TODO: Handle redirect.
                break

            case .subscribed(let requestId):
                self.subscriptionRecord(requestId)?.subscribeHandlerClosure(self)

            case .unsubscribed(let requestId):
                guard let recordIndex = self.subscriptions.firstIndex(where: { $0.requestId == requestId }) else {
                    break
                }
                let record: SubscriptionRecord = self.subscriptions[recordIndex]
                record.unsubscribeHandlerClosure(self)
                self.subscriptions.remove(at: recordIndex)

            case .create, .delete, .enter, .leave, .update:
                var requestId: RequestId = RequestId(value: 0)
                guard
                    let event: Event<PFObject> = try? Event(serverResponse: response, requestId: &requestId),
                    let record = self.subscriptionRecord(requestId)
                else {
                    break
                }
                record.eventHandlerClosure(event, self)

            case .error(let requestId, let code, let error, let reconnect):
                let error = LiveQueryErrors.ServerReportedError(code: code, error: error, reconnect: reconnect)
                if let requestId = requestId {
                    self.subscriptionRecord(requestId)?.errorHandlerClosure(error, self)
                } else {
                    throw error
                }
            }
        }
    }
}
