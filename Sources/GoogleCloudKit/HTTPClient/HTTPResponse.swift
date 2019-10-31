import Foundation
import NIO
import NIOHTTP1

public struct HTTPResponse: CustomStringConvertible, CustomDebugStringConvertible {
    internal var head: HTTPResponseHead

    public var version: HTTPVersion {
        get { return head.version }
        set { head.version = newValue }
    }

    public var status: HTTPResponseStatus {
        get { return head.status }
        set { head.status = newValue }
    }

    public var headers: HTTPHeaders {
        get { return head.headers }
        set { head.headers = newValue }
    }

    public var body: Data?

    public var description: String {
        var desc: [String] = []
        desc.append("HTTP/\(version.major).\(version.minor) \(status.code) \(status.reasonPhrase)")
        desc.append(headers.description)
        body.flatMap { desc.append($0.description) }
        return desc.joined(separator: "\n")
    }

    public var debugDescription: String {
        return description
    }

    public init(status: HTTPResponseStatus = .ok,
                version: HTTPVersion = .init(major: 1, minor: 1),
                headers: HTTPHeaders = .init(),
                body: Data?) {
        let head = HTTPResponseHead(version: version, status: status, headers: headers)

        self.init(head: head, body: body)
    }

    init(head: HTTPResponseHead, body: Data?) {
        self.head = head
        self.body = body
    }
}
