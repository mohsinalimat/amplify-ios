//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import CwlPreconditionTesting

@testable import Amplify
@testable import AmplifyTestCommon

class ConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testPreconditionFailureInvokingWithNoPlugin() throws {
        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            _ = Amplify.API.get(request: RESTRequest()) { _ in }
        }
        XCTAssertNotNil(exception)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            _ = Amplify.API.get(request: RESTRequest()) { _ in }
        }
        XCTAssertNotNil(exception)
    }

    func testConfigureDelegatesToPlugins() throws {
        let configureWasInvoked = expectation(description: "Plugin configure() was invoked")
        let plugin = MockLoggingCategoryPlugin()
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                configureWasInvoked.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        wait(for: [configureWasInvoked], timeout: 1.0)
    }

    func testThrowsOnNonExistentPlugin() throws {
        try Amplify.add(plugin: MockLoggingCategoryPlugin())

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["NonExistentPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        XCTAssertThrowsError(try Amplify.configure(amplifyConfig),
                             "Throws for nonexistent plugin") { error in
                                guard case LoggingError.configuration = error else {
                                    XCTFail("Should have thrown for nonexistent plugin")
                                    return
                                }
        }
    }

    func testMultipleConfigureCallsThrowError() throws {
        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)
        XCTAssertThrowsError(try Amplify.configure(amplifyConfig),
                             "Subsequent calls to configure should throw") { error in
            guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured error")
                return
            }
        }
    }

    func testResetClearsPreviouslyAddedPlugins() throws {
        let plugin = MockLoggingCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        XCTAssertNotNil(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"))
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.Logging.getPlugin(for: "MockLoggingCategoryPlugin"),
                             "Plugins should be reset") { error in
                                guard case LoggingError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin error")
                                    return
                                }
        }
    }

    func testResetDelegatesToPlugins() throws {
        let plugin = MockLoggingCategoryPlugin()

        let resetWasInvoked = expectation(description: "Reset was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)

        let loggingConfig = LoggingCategoryConfiguration(
            plugins: ["MockLoggingCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(logging: loggingConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        wait(for: [resetWasInvoked], timeout: 1.0)
    }

    func testResetAllowsReconfiguration() throws {
        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertNoThrow(try Amplify.configure(amplifyConfig))
    }

    func testDecodeConfiguration() throws {
        let jsonString = """
        {"UserAgent":"aws-amplify-cli/2.0","Version":"1.0","storage":{"plugins":{"MockStorageCategoryPlugin":{}}}}
        """

        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let config = try decoder.decode(AmplifyConfiguration.self, from: jsonData)
        XCTAssertNotNil(config.storage)
    }
}
