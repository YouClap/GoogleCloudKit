//
//  OAuthServiceAccount.swift
//  GoogleCloudProvider
//
//  Created by Andrew Edwards on 4/15/18.
//

import Crypto
import JWT
import NIO
import NIOHTTP1

public enum OAuthServiceAccountError: GoogleCloudError {
    case escapeToken(String)
}

public class OAuthServiceAccount: OAuthRefreshable {
    let httpClient: HTTPClient
    public let credentials: GoogleServiceAccountCredentials
    public let scope: String

    private let decoder = JSONDecoder()
    private let eventLoop: EventLoop
    
    init(credentials: GoogleServiceAccountCredentials, scopes: [GoogleCloudAPIScope], httpClient: HTTPClient, eventLoop: EventLoop) {
        self.credentials = credentials
        self.scope = scopes.map { $0.value }.joined(separator: " ")
        self.httpClient = httpClient
        self.eventLoop = eventLoop

        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // Google Documentation for this approach: https://developers.google.com/identity/protocols/OAuth2ServiceAccount
    public func refresh() -> EventLoopFuture<OAuthAccessToken> {
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]

        do {
            let token = try generateJWT()

            guard
                let bodyString = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(token)"
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            else {
                throw OAuthServiceAccountError.escapeToken(token)
            }

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
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
    }

    private func generateJWT() throws -> String {
        let payload = OAuthPayload(iss: IssuerClaim(value: credentials.clientEmail),
                                   scope: scope,
                                   aud: AudienceClaim(value: GoogleOAuthTokenAudience),
                                   exp: ExpirationClaim(value: Date().addingTimeInterval(3600)),
                                   iat: IssuedAtClaim(value: Date()))

        let privateKey = try RSAKey.private(pem: credentials.privateKey.data(using: .utf8, allowLossyConversion: true) ?? Data())
        let jwtData = try JWT(payload: payload).sign(using: .rs256(key: privateKey))
        
        return String(data: Data(jwtData), encoding: .utf8) ?? ""
    }
}
