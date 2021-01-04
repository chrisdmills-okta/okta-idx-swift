//
//  AcceptType.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-28.
//

import Foundation

extension IDXClient.APIVersion1.AcceptType {
    private static let urlEncodedString = "application/x-www-form-urlencoded"
    private static let ionJsonString = "application/ion+json"
    
    init?(rawValue: String) {
        if rawValue == IDXClient.APIVersion1.AcceptType.urlEncodedString {
            self = .formEncoded
        } else if rawValue.hasPrefix(IDXClient.APIVersion1.AcceptType.ionJsonString) {
            var version: String? = nil
            if let range = rawValue.range(of: "okta-version=") {
                version = String(rawValue.suffix(from: range.upperBound))
            }
            self = .ionJson(version: version)
        } else {
            return nil
        }
    }
    
    func encodedData(with parameters: [String:Any]) throws -> Data?{
        switch self {
        case .formEncoded:
            guard let parameters = parameters as? [String:String] else {
                throw IDXClientError.invalidRequestData
            }
            return URLRequest.idxURLFormEncodedString(for: parameters)?.data(using: .utf8)
            
        case .ionJson:
            return try JSONSerialization.data(withJSONObject: parameters, options: .sortedKeys)
        }
    }
    
    public func stringValue() -> String {
        switch self {
        case .formEncoded:
            return IDXClient.APIVersion1.AcceptType.urlEncodedString
        case .ionJson(version: let version):
            if version == nil {
                return IDXClient.APIVersion1.AcceptType.ionJsonString
            } else {
                return "\(IDXClient.APIVersion1.AcceptType.ionJsonString); okta-version=\(version!)"
            }
        }
    }
}
