//
//  OAuthApplicationDefault.swift
//  GoogleCloudProvider
//
//  Created by Brian Hatfield on 7/17/18.
//

import Foundation
import HTTP

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

        let body = HTTPBody(string: bodyString)
        let request = HTTPRequest(method: .POST, url: GoogleOAuthTokenUrl, headers: headers, body: body)

        return httpClient.send(request).map { response in
            guard response.status == .ok, let responseData = response.body.data else {
                throw OauthRefreshError.noResponse(response.status)
            }

            return try self.decoder.decode(OAuthAccessToken.self, from: responseData)
        }
    }
}
