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

/// Instances of `Remediation` describe choices the user can make to proceed through the authentication workflow.
///
/// Either simple or complex authentication scenarios consist of a set of steps that may be followed, but at some times the user may have a choice in what they use to verify their identity. For example, a user may have multiple choices in verifying their account, such as:
///
/// 1. Password
/// 2. Security Questions
/// 3. Email verification
/// 4. Other, customizable, verification steps.
///
/// Each of the remediation options includes details about what form values should be collected from the user, and a description of the resulting request that should be sent to Okta to proceed to the next step.
///
/// Nested form values can be accessed through keyed subscripting, for example:
///
///    response.remediations[.identifier]
///
/// Some remediations are represented by subclasses of `Remediation` when specific behaviors or common patterns are available. These represent optional conveniences that simplify access to these types of objects.
@objc(IDXRemediation)
public class Remediation: NSObject {
    /// The type of this remediation, which is used for keyed subscripting from a `RemediationCollection`.
    @objc public let type: RemediationType
    
    /// The string name for this type.
    @objc public let name: String
    
    /// A description of the form values that this remediation option supports and expects.
    @objc public let form: Form
    
    /// The set of authenticators associated with this remediation.
    @objc public internal(set) var authenticators: Authenticator.Collection = .init(authenticators: nil)
    
    public let capabilities: [RemediationCapability]
    
    /// Returns the field within this remedation with the given name or key-path.
    ///
    /// To retrieve nested fields, keyPath "." notation can be used to select fields within child forms, for example:
    ///
    ///    response.remediations[.identifier]["credentials.passcode"]
    @objc public subscript(name: String) -> Form.Field? {
        get { form[name] }
    }
    
    /// Collection of messages for all fields within this remedation.
    @objc public lazy var messages: IDXClient.Message.Collection = {
        IDXClient.Message.Collection(messages: nil, nestedMessages: nestedMessages())
    }()
    
    private weak var client: IDXClientAPI?
    
    let method: String
    let href: URL
    let accepts: String?
    let refresh: TimeInterval?
    let relatesTo: [String]?
    
    required internal init?(client: IDXClientAPI,
                            name: String,
                            method: String,
                            href: URL,
                            accepts: String?,
                            form: Form,
                            refresh: TimeInterval? = nil,
                            relatesTo: [String]? = nil,
                            capabilities: [RemediationCapability])
    {
        self.client = client
        self.name = name
        self.type = .init(string: name)
        self.method = method
        self.href = href
        self.accepts = accepts
        self.form = form
        self.refresh = refresh
        self.relatesTo = relatesTo
        self.capabilities = capabilities
        
        super.init()
    }
    
    public override var description: String {
        let logger = DebugDescription(self)
        let components = [
            logger.address(),
            "\(#keyPath(type)): \(type.rawValue)"
        ]
        
        return logger.brace(components.joined(separator: "; "))
    }
    
    public override var debugDescription: String {
        let components = [
            "\(#keyPath(form)): \(form.debugDescription)",
            "\(#keyPath(authenticators)): \(authenticators.debugDescription)",
        ]
        
        return """
            \(description) {
            \(DebugDescription(self).format(components, indent: 4))
            }
            """
    }
    
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a response is received.
    public func proceed(completion: IDXClient.ResponseResult? = nil) {
        guard let client = client else {
            completion?(.failure(.invalidClient))
            return
        }
        
        client.proceed(remediation: self, completion: completion)
    }
    
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the `IDXClientDelegate.idx(client:didReceive:)` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a response is received.
    ///   - response: `Response` object describing the next step in the remediation workflow, or `nil` if an error occurred.
    ///   - error: A description of the error that occurred, or `nil` if the request was successful.
    @objc public func proceed(completion: IDXClient.ResponseResultCallback?) {
        proceed { result in
            switch result {
            case .success(let response):
                completion?(response, nil)
            case .failure(let error):
                completion?(nil, error)
            }
        }
    }
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension Remediation {
    /// Executes the remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    public func proceed() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            proceed() { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
