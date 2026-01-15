//
//  LiveQueryProtocolTests.swift
//  TMGParseLiveQueryTests
//
//  Wire-protocol tests for the LiveQuery client. These pin down the messages the
//  client parses (incoming `ServerResponse`) and sends (outgoing `ClientOperation`) —
//  the contract the websocket transport must carry intact after the Starscream ->
//  URLSessionWebSocketTask migration. They are pure: no Parse backend, no live socket.
//

import XCTest
@testable import TMGParseLiveQuery

final class LiveQueryProtocolTests: XCTestCase {

    /// Decode a JSON string into the `[String: AnyObject]` shape `ServerResponse` expects.
    private func json(_ string: String) throws -> [String: AnyObject] {
        let data = Data(string.utf8)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: AnyObject])
    }

    // MARK: - Incoming: ServerResponse parsing

    func test_parse_connected() throws {
        let response = try ServerResponse(json: try json(#"{"op":"connected"}"#))
        guard case .connected = response else { return XCTFail("expected .connected, got \(response)") }
    }

    func test_parse_subscribed_carriesRequestId() throws {
        let response = try ServerResponse(json: try json(#"{"op":"subscribed","requestId":7}"#))
        guard case let .subscribed(requestId) = response else { return XCTFail("expected .subscribed") }
        XCTAssertEqual(requestId.value, 7)
    }

    func test_parse_unsubscribed_carriesRequestId() throws {
        let response = try ServerResponse(json: try json(#"{"op":"unsubscribed","requestId":3}"#))
        guard case let .unsubscribed(requestId) = response else { return XCTFail("expected .unsubscribed") }
        XCTAssertEqual(requestId.value, 3)
    }

    func test_parse_createEvent_carriesRequestIdAndObject() throws {
        let response = try ServerResponse(json: try json(
            #"{"op":"create","requestId":2,"object":{"className":"Msg","objectId":"abc"}}"#
        ))
        guard case let .create(requestId, object) = response else { return XCTFail("expected .create") }
        XCTAssertEqual(requestId.value, 2)
        XCTAssertEqual(object["objectId"] as? String, "abc")
    }

    func test_parse_updateEvent_carriesRequestIdAndObject() throws {
        let response = try ServerResponse(json: try json(
            #"{"op":"update","requestId":5,"object":{"className":"Msg","objectId":"x"}}"#
        ))
        guard case let .update(requestId, object) = response else { return XCTFail("expected .update") }
        XCTAssertEqual(requestId.value, 5)
        XCTAssertEqual(object["className"] as? String, "Msg")
    }

    func test_parse_error_withRequestId() throws {
        let response = try ServerResponse(json: try json(
            #"{"op":"error","requestId":1,"code":99,"error":"boom","reconnect":true}"#
        ))
        guard case let .error(requestId, code, message, reconnect) = response else { return XCTFail("expected .error") }
        XCTAssertEqual(requestId?.value, 1)
        XCTAssertEqual(code, 99)
        XCTAssertEqual(message, "boom")
        XCTAssertTrue(reconnect)
    }

    func test_parse_error_withoutRequestId() throws {
        let response = try ServerResponse(json: try json(
            #"{"op":"error","code":4,"error":"global","reconnect":false}"#
        ))
        guard case let .error(requestId, _, _, reconnect) = response else { return XCTFail("expected .error") }
        XCTAssertNil(requestId)
        XCTAssertFalse(reconnect)
    }

    func test_parse_unknownOp_throws() {
        XCTAssertThrowsError(try ServerResponse(json: try json(#"{"op":"banana"}"#)))
    }

    func test_parse_missingOp_throws() {
        XCTAssertThrowsError(try ServerResponse(json: try json(#"{"requestId":1}"#)))
    }

    // MARK: - Outgoing: ClientOperation encoding (Parse-free cases)

    func test_encode_connect_includesClientKeyWhenPresent() {
        let op = ClientOperation.connect(applicationId: "app", sessionToken: "sess", clientKey: "key")
        let payload = op.JSONObjectRepresentation
        XCTAssertEqual(payload["op"] as? String, "connect")
        XCTAssertEqual(payload["applicationId"] as? String, "app")
        XCTAssertEqual(payload["sessionToken"] as? String, "sess")
        XCTAssertEqual(payload["clientKey"] as? String, "key")
    }

    func test_encode_connect_omitsClientKeyWhenNil() {
        let op = ClientOperation.connect(applicationId: "app", sessionToken: "sess", clientKey: nil)
        XCTAssertNil(op.JSONObjectRepresentation["clientKey"])
    }

    func test_encode_unsubscribe() {
        let op = ClientOperation.unsubscribe(requestId: Client.RequestId(value: 42))
        let payload = op.JSONObjectRepresentation
        XCTAssertEqual(payload["op"] as? String, "unsubscribe")
        XCTAssertEqual(payload["requestId"] as? Int, 42)
    }

    // MARK: - RequestId

    func test_requestId_equality() {
        XCTAssertEqual(Client.RequestId(value: 1), Client.RequestId(value: 1))
        XCTAssertNotEqual(Client.RequestId(value: 1), Client.RequestId(value: 2))
    }
}
