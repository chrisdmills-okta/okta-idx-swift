# Okta Identity Engine Library

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->
<!-- /TOC -->

## Design Principles

Since the Identity Engine library is new, and built in Swift, there is an opportunity to create a best-in-class experience for developers that can streamline the process, simplify the developer experience, and provide maximum compatability with existing applications.

As a result, a multi-tiered approach will be made to reach the following goals:

* Full Swift and Objective-C support, with "Swifty" and Objective-C naming conventions.
* Traditional Delegation / block-based patterns used in Objective-C.
* Streamlined Combine extension that can leverage Promises and Futures.
* Overridden `description` and `debugDescription` implementations to aid in debugging.
* Unified Logging and Activity Tracing support for simpler crash log reporting.

This repository contains the Okta IDX SDK for Swift. This SDK can be used in your native client code (iOS, macOS) to assist in authenticating users against the Okta Identity Engine.

> :grey_exclamation: The use of this SDK requires you to be a part of our limited general availability (LGA) program with access to Okta Identity Engine. If you want to request to be a part of our LGA program for Okta Identity Engine, please reach out to your account manager. If you do not have an account manager, please reach out to oie@okta.com for more information.

> :warning: Beta alert! This library is in beta. See [release status](#release-status) for more information.

## Release status

This library uses semantic versioning and follows Okta's [Library Version Policy][okta-library-versioning].

| Version | Status                             |
| ------- | ---------------------------------- |
| 0.1.0   | :warning: Beta                     |

The latest release can always be found on the [releases page][github-releases].

## Need help?
 
If you run into problems using the SDK, you can
 
* Ask questions on the [Okta Developer Forums][devforum]
* Post [issues][github-issues] here on GitHub (for code errors)

## Getting Started

## Usage guide

The below code snippets will help you understand how to use this library.

Once you initialize an `IDXClient`, you can call methods to make requests to the Okta API.

### Create the Client

[//]: #(method: createClient)
```swift
let config = IDXClient.Configuration(issuer: "<#issuer#>",
                                     clientId: "<#clientId#>",
                                     clientSecret: nil,
                                     scopes: ["openid", "email", "<#otherScopes#>"],
                                     redirectUri: "<#redirectUri#>")
let client = IDXClient(configuration: config)
```
[//]: # (end: createClient)

### Start the authentication session

[//]: #(method: start)
```swift
client.start { (response, error) in
    guard let response = response else {
        // Handle error
        return
    }
    
    // Use response
}
```
[//]: # (end: start)

### Get new tokens using username & password

[//]: #(method: getNewTokens)
```swift
client.start { (response, error) in
    guard let response = response,
          let remediation = response.remediation?.remediationOptions.first else {
        // Handle error
        return
    }
    
    remediation.proceed(with: ["identifier": "<#username#>"]) { (response, error) in
        guard let response = response,
              let remediation = response.remediation?.remediationOptions.first else {
            // Handle error
            return
        }

        remediation.proceed(with: ["credentials": [ "passcode": "<#password#>" ]]) { (response, error) in
            guard let response = response else {
                // Handle error
                return
            }
            
            guard response.isLoginSuccessful else {
                // Handle error
                return
            }

            response.exchangeCode { (token, error) in
                guard let token = token else {
                    // Handle error
                    return
                }
                
                print("""
                Exchanged interaction code for token:
                    accessToken:  \(token.accessToken)
                    refreshToken: \(token.refreshToken ?? "Unavailable")
                    idToken:      \(token.idToken ?? "Unavailable")
                    tokenType:    \(token.tokenType)
                    scope:        \(token.scope)
                    expiresIn:    \(token.expiresIn) seconds
                """)
            }
        }
    }
}
```
[//]: # (end: getNewTokens)


## Supported Platforms

### iOS

### macOS

### tvOS _(Aspirational)_

## Install

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:

```swift
dependencies: [
    .Package(url: "https://github.com/okta/okta-idx-swift.git", majorVersion: <majorVersion>, minor: <minor>)
]
```

### Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaIdx'
```

Then install it into your project:

```bash
pod install
```

### Carthage

To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-idx-swift"
```

## Usage Guide

## Configuration Reference

## API Reference

## Development

## Known issues
