//
//  OAuthComputeEngine+AppEngineFlex.swift
//  GoogleCloud
//
//  Created by Andrew Edwards on 11/15/18.
//

import Foundation
import NIO
import HTTP

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

        let request = HTTPRequest(method: .POST, url: GoogleOAuthTokenUrl, headers: headers)

        return httpClient.send(request).map { response in
            guard response.status == .ok, let responseData = response.body.data else {
                throw OauthRefreshError.noResponse(response.status)
            }

            return try self.decoder.decode(OAuthAccessToken.self, from: responseData)
        }
    }
}
