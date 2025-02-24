/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

/// The IDXClient class is used to define and initiate an authentication workflow utilizing the Okta Identity Engine. Your app can use this to begin a customizable workflow to authenticate and verify the identity of a user using your application.
///
/// The `IDXClient.Configuration` class is used to communicate which application, defined within Okta, the user is being authenticated with. From this point a workflow is initiated, consisting of a series of authentication "Remediation" steps. At each step, your application can introspect the `Response` object to determine which UI should be presented to your user to guide them through to login.
@objc
public final class IDXClient: NSObject {
    /// Options to use when initiating an IDXClient.
    public enum Option: String {
        /// Option used when a client needs to supply its own custom state value when initiating an IDXClient.
        case state
        
        /// Option used when a user is authenticating using a recovery token.
        case recoveryToken = "recovery_token"
    }
    
    /// The type used for the completion  handler result from any method that returns an `Response`.
    /// - Parameters:
    ///   - response: The `Response` object that describes the next workflow steps.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias ResponseResultCallback = (_ response: Response?, _ error: Error?) -> Void
    public typealias ResponseResult = (Result<Response, IDXClientError>) -> Void

    /// The type used for the completion  handler result from any method that returns an `Token`.
    /// - Parameters:
    ///   - token: The `Token` object created when the token is successfully exchanged.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias TokenResultCallback = (_ token: Token?, _ error: Error?) -> Void
    public typealias TokenResult = (Result<Token, IDXClientError>) -> Void

    /// The current context for the authentication session.
    ///
    /// This value is used when resuming authentication at a later date or after app launch, and to ensure the final token exchange can be completed.
    @objc public let context: Context
    
    /// Optional delegate property, used to be informed when important events occur throughout the authentication workflow.
    @objc public weak var delegate: IDXClientDelegate? = nil
    
    /// Starts a new authentication session using the given configuration values. If the client is able to successfully interact with Okta Identity Engine, a new client instance is returned to the caller.
    /// - Parameters:
    ///   - configuration: Configuration describing the app settings to contact.
    ///   - options: Options to include within the OAuth2 transaction.
    ///   - completion: Completion block to be invoked when a client is created, or when an error is received.
    public static func start(with configuration: Configuration,
                             options: [Option:String]? = nil,
                             completion: @escaping (Result<IDXClient, IDXClientError>) -> Void)
    {
        let api = Version.latest.clientImplementation(with: configuration)
        start(with: api, options: options, completion: completion)
    }

    /// Starts a new authentication session using the given configuration values. If the client is able to successfully interact with Okta Identity Engine, a new client instance is returned to the caller.
    /// - Parameters:
    ///   - configuration: Configuration describing the app settings to contact.
    ///   - options: Options to include within the OAuth2 transaction.
    ///   - completion: Completion block to be invoked when a client is created, or when an error is received.
    @objc public static func start(with configuration: Configuration,
                                   options: [String:String]? = nil,
                                   completion: @escaping (_ client: IDXClient?, _ error: Error?) -> Void)
    {
        let mappedOptions = options?.reduce(into: [Option:String](), { partialResult, item in
            guard let option = Option(rawValue: item.key) else { return }
            partialResult[option] = item.value
        })
        
        start(with: configuration, options: mappedOptions) { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
            case .success(let client):
                completion(client, nil)
            }
        }
    }
    
    static func start(with api: IDXClientAPIImpl,
                      options: [Option:String]? = nil,
                      completion: @escaping (Result<IDXClient, IDXClientError>) -> Void)
    {
        api.start(options: options) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let context):
                completion(.success(IDXClient(context: context, api: api)))
            }
        }
    }
    
    /// Initializes an IDX client instance with the given configuration object. This can be used when a Context is available from a previous session, and the user needs to resume the authentication.
    /// - Parameters:
    ///   - context: Context object to use when resuming a session.
    @objc public convenience init(context: Context) {
        let api = context.version.clientImplementation(with: context.configuration)
        self.init(context: context, api: api)
    }
        
    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method is usually performed after an IDXClient is created in `IDXClient.start(with:state:completion:)`, but can also be called at any time to identify what next remediation steps are available to the user.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a response is received.
    ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    @objc public func resume(completion: ResponseResultCallback?) {
        resume() { result in
            switch result {
            case .success(let response):
                completion?(response, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }

    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method is usually performed after an IDXClient is created in `IDXClient.start(with:state:completion:)`, but can also be called at any time to identify what next remediation steps are available to the user.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a response is received.
    public func resume(completion: ResponseResult? = nil) {
        api.resume { result in
            self.handleResponse(result, completion: completion)
        }
    }
    
    /// Evaluates the given redirect URL to determine what next steps can be performed. This is usually used when receiving a redirection from an IDP authentication flow.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    /// - Returns: Result of parsing the given redirect URL.
    @objc public func redirectResult(for url: URL) -> RedirectResult {
        api.redirectResult(for: url)
    }
    
    /// Exchanges the redirect URL with a token.
    ///
    /// Once the `redirectResult` method returns `authenticated`, the developer can exchange that redirect URL for a valid token by using this method.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` method to receive the token or to handle any errors.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    ///   - completion: Optional completion handler invoked when a token, or error, is received.
    @objc(exchangeCodeWithRedirectUrl:completion:)
    public func exchangeCode(redirect url: URL,
                             completion: TokenResultCallback?) {
        exchangeCode(redirect: url) { result in
            switch result {
            case .success(let token):
                completion?(token, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }

    /// Exchanges the redirect URL with a token.
    ///
    /// Once the `redirectResult` method returns `authenticated`, the developer can exchange that redirect URL for a valid token by using this method.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    ///   - completion: Optional completion handler invoked when a token, or error, is received.
    public func exchangeCode(redirect url: URL,
                             completion: TokenResult? = nil) {
        api.exchangeCode(redirect: url) { result in
            self.handleResponse(result, completion: completion)
        }
    }

    internal let api: IDXClientAPIImpl
    internal required init(context: Context, api: IDXClientAPIImpl) {
        self.context = context
        self.api = api

        super.init()

        self.api.client = self
    }
    
    public override var description: String {
        let logger = DebugDescription(self)
        let components = [logger.address()]
        
        return logger.brace(components.joined(separator: "; "))
    }
    
    public override var debugDescription: String {
        let components = [
            context.debugDescription,
            api.configuration.debugDescription
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
extension IDXClient {
    /// Starts a new authentication session using the given configuration values. If the client is able to successfully interact with Okta Identity Engine, a new client instance is returned to the caller.
    /// - Parameters:
    ///   - configuration: Configuration describing the app settings to contact.
    ///   - options: Options to include within the OAuth2 transaction.
    /// - Returns: An IDXClient instance for this session.
    public static func start(with configuration: Configuration,
                             options: [Option:String]? = nil) async throws -> IDXClient
    {
        let api = Version.latest.clientImplementation(with: configuration)
        return try await start(with: api, options: options)
    }

    static func start(with api: IDXClientAPIImpl,
                      options: [Option:String]? = nil) async throws -> IDXClient
    {
        try await withCheckedThrowingContinuation { continuation in
            start(with: api, options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method is usually performed after an IDXClient is created in ``IDXClient.start(with:state:)``, but can also be called at any time to identify what next remediation steps are available to the user.
    /// - Returns: A response showing the user's next steps.
    public func resume() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            resume() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Exchanges the redirect URL with a token.
    ///
    /// Once the `redirectResult` method returns `authenticated`, the developer can exchange that redirect URL for a valid token by using this method.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    public func exchangeCode(redirect url: URL) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            exchangeCode(redirect: url) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

/// Delegate protocol that can be used to receive updates from the IDXClient through the process of a user's authentication.
@objc
public protocol IDXClientDelegate {
    /// Message sent when an error is received at any point during the authentication process.
    /// - Parameters:
    ///   - client: IDXClient sending the error.
    ///   - error: The error that was received.
    @objc(idxClient:didReceiveError:)
    func idx(client: IDXClient, didReceive error: Error)
    
    /// Informs the delegate when an IDX response is received, either through an `introspect` or `proceed` call.
    /// - Parameters:
    ///   - client: IDXClient receiving the response.
    ///   - response: The response that was received.
    @objc(idxClient:didReceiveResponse:)
    func idx(client: IDXClient, didReceive response: Response)
    
    /// Informs the delegate when authentication is successful, and the token is returned.
    /// - Parameters:
    ///   - client: IDXClient receiving the token.
    ///   - token: The IDX token object describing the user's credentials.
    @objc(idxClient:didReceiveToken:)
    func idx(client: IDXClient, didReceive token: Token)
}

/// Errors reported from IDXClient
public enum IDXClientError: Error {
    case invalidClient
    case cannotCreateRequest
    case invalidHTTPResponse
    case invalidResponseData
    case invalidRequestData
    case serverError(message: String, localizationKey: String, type: String)
    case internalError(_: Error)
    case internalMessage(_: String)
    case oauthError(summary: String, code: String?, errorId: String?)
    case invalidParameter(name: String)
    case invalidParameterValue(name: String, type: String)
    case parameterImmutable(name: String)
    case missingRequiredParameter(name: String)
    case missingRemediationOption(name: String)
    case unknownRemediationOption(name: String)
    case successResponseMissing
    case missingRefreshToken
    case missingRelatedObject
}
