//
//  OAuthComputeEngine+AppEngineFlex.swift
//  GoogleCloud
//
//  Created by Andrew Edwards on 11/15/18.
//

import Foundation
import NIO
import NIOHTTP1

/// [Reference](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#applications)
public class OAuthComputeEngineAppEngineFlex: OAuthRefreshable {
    let serviceAccount: String
    let httpClient: HTTPClient
    var serviceAccountTokenURL: String {
      return "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/\(serviceAccount)/token"
    }
    private let decoder = JSONDecoder()
    
    init(serviceAccount: String = "default", httpClient: HTTPClient) {
        self.serviceAccount = serviceAccount
        self.httpClient = httpClient

        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    public func refresh() -> EventLoopFuture<OAuthAccessToken> {
        let headers: HTTPHeaders = ["Metadata-Flavor": "Google"]

        guard let url = URL(string: GoogleOAuthTokenUrl) else {
            return httpClient.eventLoop.newFailedFuture(
                error: OAuthApplicationDefaultError.failedToCreateURL(GoogleOAuthTokenUrl))
        }

        let request = HTTPRequest(method: .POST, url: url, headers: headers)

        return httpClient.send(request: request).map { response in
            guard response.status == .ok, let responseData = response.body else {
                throw OauthRefreshError.noResponse(response.status)
            }

            return try self.decoder.decode(OAuthAccessToken.self, from: responseData)
        }
    }
}
