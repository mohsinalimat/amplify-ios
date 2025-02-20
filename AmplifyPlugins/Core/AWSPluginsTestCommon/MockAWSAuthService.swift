//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSMobileClient
import Amplify
import AWSPluginsCore

public class MockAWSAuthService: AWSAuthServiceBehavior {
    var getIdentityIdError: AuthError?
    var getTokenError: AuthError?
    var identityId: String?
    var token: String?

    public func configure() {
    }

    public func reset() {
    }

    public func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        let cognitoCredentialsProvider = AWSCognitoCredentialsProvider()
        return cognitoCredentialsProvider
    }

    public func getIdentityId() -> Result<String, AuthError> {
        if let error = getIdentityIdError {
            return .failure(error)
        }

        return .success(identityId ?? "IdentityId")
    }

    public func getToken() -> Result<String, AuthError> {
        if let error = getTokenError {
            return .failure(error)
        }

        return .success(token ?? "token")
    }
}
