//
//  OAuthApplicationDefault.swift
//  GoogleCloudProvider
//
//  Created by Brian Hatfield on 7/17/18.
//

import Foundation
import NIO
import NIOHTTP1

public enum OAuthApplicationDefaultError: GoogleCloudError {
    case failedToCreateURL(String)
}

public class OAuthApplicationDefault: OAuthRefreshable {
    let httpClient: HTTPClient
    let credentials: GoogleApplicationDefaultCredentials
    private let decoder = JSONDecoder()
    
    init(credentials: GoogleApplicationDefaultCredentials, httpClient: HTTPClient) {
        self.credentials = credentials
        self.httpClient = httpClient

        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // Google Documentation for this approach: https://developers.google.com/identity/protocols/OAuth2WebServer#offline
    public func refresh() -> EventLoopFuture<OAuthAccessToken> {
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]

        let bodyString = """
            client_id=\(credentials.clientId)\
            &client_secret=\(credentials.clientSecret)\
            &refresh_token=\(credentials.refreshToken)\
            &grant_type=refresh_token
        """

        guard let url = URL(string: GoogleOAuthTokenUrl) else {
            return httpClient.eventLoop.newFailedFuture(
                error: OAuthApplicationDefaultError.failedToCreateURL(GoogleOAuthTokenUrl))
        }

        let body = Data(bodyString.utf8)
        let request = HTTPRequest(method: .POST, url: url, headers: headers, body: body)

        return httpClient.send(request: request).map { response in
            guard response.status == .ok, let responseData = response.body else {
                throw OauthRefreshError.noResponse(response.status)
            }

            return try self.decoder.decode(OAuthAccessToken.self, from: responseData)
        }
    }
}
