//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation

/// Access tokens created as a result of exchanging a successful workflow response.
@objc(IDXToken)
public final class Token: NSObject, Codable {
    /// The access token to use.
    @objc public let accessToken: String
    
    /// The refresh token, if available.
    @objc public let refreshToken: String?
    
    /// The time interval after which this token will expire.
    @objc public let expiresIn: TimeInterval
    
    /// The ID token JWT string.
    @objc public let idToken: String?
    
    /// The access scopes for this token.
    @objc public let scope: String
    
    /// The type of this token.
    @objc public let tokenType: String
    
    /// The configuration used when this token was created
    @objc public let configuration: IDXClient.Configuration
    
    /// The possible token types that can be revoked.
    @objc public enum RevokeType: Int {
        case refreshToken
        case accessAndRefreshToken
    }
    
    /// Revokes the token.
    /// - Parameters:
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    ///   - completion: Completion handler for when the token is revoked.
    public func revoke(type: Token.RevokeType = .accessAndRefreshToken, completion: @escaping(Result<Void,IDXClientError>) -> Void) {
        let selectedToken: String?
        switch type {
        case .refreshToken:
            selectedToken = refreshToken
        case .accessAndRefreshToken:
            selectedToken = accessToken
        }
        
        guard let tokenString = selectedToken else {
            completion(.failure(IDXClientError.invalidParameter(name: "token")))
            return
        }
        
        Token.revoke(token: tokenString, type: type, configuration: configuration, completion: completion)
    }
    
    /// Revokes the token.
    /// - Parameters:
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    ///   - completion: Completion handler for when the token is revoked.
    @objc(revokeToken:completion:)
    public func revoke(type: Token.RevokeType = .accessAndRefreshToken, completion: @escaping(_ successful: Bool, _ error: Error?) -> Void) {
        revoke(type: type) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    /// Revokes the given token using the string value of the token.
    /// - Parameters:
    ///   - token: Token string to revoke.
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    ///   - configuration: The client configuration used when the token was created.
    ///   - completion: Completion handler for when the token is revoked.
    public static func revoke(token: String,
                              type: Token.RevokeType,
                              configuration: IDXClient.Configuration,
                              completion: @escaping(Result<Void,IDXClientError>) -> Void)
    {
        let api = IDXClient.Version.latest.clientImplementation(with: configuration)
        revoke(token: token, type: type, api: api, completion: completion)
    }
    
    /// Revokes the given token using the string value of the token.
    /// - Parameters:
    ///   - token: Token string to revoke.
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    ///   - configuration: The client configuration used when the token was created.
    ///   - completion: Completion handler for when the token is revoked.
    @objc(revokeToken:type:configuration:completion:)
    public static func revoke(token: String,
                              type: Token.RevokeType,
                              configuration: IDXClient.Configuration,
                              completion: @escaping(_ successful: Bool, _ error: Error?) -> Void)
    {
        revoke(token: token, type: type, configuration: configuration) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    /// Refreshes the token.
    ///
    /// If no refresh token is available, or the tokens have been revoked, an error will be returned.
    ///
    /// > *Note:* Depending on organization or policy settings, the values contained within the token may or may not differ once the token is refreshed. Therefore, it may be necessary to save the newly-refeshed object for use in future requests.
    /// - Parameters:
    ///   - completion: Completion handler for when the token is revoked.
    public func refresh(completion: @escaping (Result<Token,IDXClientError>) -> Void)
    {
        let api = IDXClient.Version.latest.clientImplementation(with: configuration)
        api.refresh(token: self) { result in
            completion(result)
        }
    }
    
    /// Refreshes the token.
    ///
    /// If no refresh token is available, or the tokens have been revoked, an error will be returned.
    ///
    /// > *Note:* Depending on organization or policy settings, the values contained within the token may or may not differ once the token is refreshed. Therefore, it may be necessary to save the newly-refeshed object for use in future requests.
    /// - Parameters:
    ///   - token: The new token object if the refresh was successful.
    ///   - error: An error object if the refresh was unsuccessful.
    ///   - completion: Completion handler for when the token is revoked.
    @objc public func refresh(completion: @escaping(_ token: Token?, _ error: Error?) -> Void)
    {
        refresh { result in
            switch result {
            case .success(let token):
                completion(token, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    static func revoke(token: String,
                       type: Token.RevokeType,
                       api: IDXClientAPIImpl,
                       completion: @escaping(Result<Void,IDXClientError>) -> Void)
    {
        api.revoke(token: token, type: type.tokenTypeHint) { result in
            completion(result)
        }
    }
    
    internal init(accessToken: String,
                  refreshToken: String?,
                  expiresIn: TimeInterval,
                  idToken: String?,
                  scope: String,
                  tokenType: String,
                  configuration: IDXClient.Configuration)
    {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.idToken = idToken
        self.scope = scope
        self.tokenType = tokenType
        self.configuration = configuration
        
        super.init()
    }
    
    public override var description: String {
        let logger = DebugDescription(self)
        let components = [
            logger.address(),
            "\(#keyPath(accessToken)): \(accessToken)",
            "\(#keyPath(idToken)): \(idToken ?? "-")",
            "\(#keyPath(refreshToken)): \(refreshToken ?? "-")"
        ]
        
        return logger.brace(components.joined(separator: "; "))
    }
    
    public override var debugDescription: String {
        let components = [
            "\(#keyPath(expiresIn)): \(expiresIn)",
            "\(#keyPath(scope)): \(scope)",
            "\(#keyPath(tokenType)): \(tokenType)",
            "\(#keyPath(configuration)): \(configuration.debugDescription)",
        ]
        
        return """
            \(description) {
            \(DebugDescription(self).format(components, indent: 4))
            }
            """
    }
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension Token {
    /// Refreshes the token.
    ///
    /// If no refresh token is available, or the tokens have been revoked, an error will be returned.
    ///
    /// > *Note:* Depending on organization or policy settings, the values contained within the token may or may not differ once the token is refreshed. Therefore, it may be necessary to save the newly-refeshed object for use in future requests.
    public func refresh() async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            refresh() { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Revokes the token.
    /// - Parameters:
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    public func revoke(type: Token.RevokeType = .accessAndRefreshToken) async throws {
        try await withCheckedThrowingContinuation { continuation in
            revoke(type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Revokes the given token using the string value of the token.
    /// - Parameters:
    ///   - token: Token string to revoke.
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    ///   - configuration: The client configuration used when the token was created.
    public static func revoke(token: String,
                              type: Token.RevokeType,
                              configuration: IDXClient.Configuration) async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            revoke(token: token, type: type, configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
