import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import NIO
import NIOHTTP1

public enum HTTPClientError: Error {
    case badResponse
}

public final class HTTPClient {
    private let urlSession: URLSession

    public let eventLoop: EventLoop

    public init(urlSession: URLSession, eventLoop: EventLoop) {
        self.urlSession = urlSession
        self.eventLoop = eventLoop
    }

    public static func `default`(with eventLoop: EventLoop) -> HTTPClient {
        return .init(urlSession: .init(configuration: .default), eventLoop: eventLoop)
    }

    public func send(request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        let promise = eventLoop.newPromise(HTTPResponse.self)

        urlSession.dataTask(with: request.foundationRequest) { data, urlResponse, error in
            if let error = error {
                promise.fail(error: error)
                return
            }

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                promise.fail(error: HTTPClientError.badResponse)
                return
            }

            promise.succeed(result: httpResponse.convertToHTTPResponse(data: data))
        }.resume()

        return promise.futureResult
    }
}

extension HTTPRequest {
    public var foundationRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "\(method)"
        request.httpBody = body
        headers.forEach { key, val in
            request.addValue(val, forHTTPHeaderField: key.description)
        }
        return request
    }
}

extension HTTPURLResponse {
    func convertToHTTPResponse(data: Data?) -> HTTPResponse {
        let headers = HTTPHeaders(allHeaderFields.compactMap { key, value in
            guard let key = key as? String, let value = value as? String else {
                return nil
            }

            return (key, value)
        })

        return HTTPResponse(status: .init(statusCode: statusCode), headers: headers, body: data)
    }
}
