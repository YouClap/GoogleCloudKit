import Foundation
import NIO
import NIOHTTP1

public struct HTTPRequest: CustomStringConvertible, CustomDebugStringConvertible {
    var head: HTTPRequestHead

    public var method: HTTPMethod {
        get { return head.method }
        set { head.method = newValue }
    }

    public var url: URL {
        get { return URL(string: urlString)! }
        set { urlString = newValue.absoluteString }
    }

    public var urlString: String {
        get { return head.uri }
        set { head.uri = newValue }
    }

    public var version: HTTPVersion {
        get { return head.version }
        set { head.version = newValue }
    }

    public var headers: HTTPHeaders {
        get { return head.headers }
        set { head.headers = newValue }
    }

    public var body: Data? {
        didSet { updateTransportHeaders() }
    }

    public var description: String {
        var desc: [String] = []
        desc.append("\(method) \(url) HTTP/\(version.major).\(version.minor)")
        desc.append(headers.description)
        body.flatMap { desc.append($0.description) }
        return desc.joined(separator: "\n")
    }

    public var debugDescription: String {
        return description
    }

    public init(method: HTTPMethod = .GET,
                url: URL,
                version: HTTPVersion = .init(major: 1, minor: 1),
                headers: HTTPHeaders = .init(),
                body: Data? = nil) {
        var head = HTTPRequestHead(version: version, method: method, uri: url.absoluteString)
        head.headers = headers

        self.init(head: head, body: body)

        updateTransportHeaders()
    }

    init(head: HTTPRequestHead, body: Data?) {
        self.head = head
        self.body = body
    }

    mutating func updateTransportHeaders() {
        body.flatMap { headers.replaceOrAdd(name: "Content-Length", value: $0.count.description) }
    }
}

