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

class DataStoreCategoryConfigurationTests: XCTestCase {
    override func setUp() {
        Amplify.reset()
    }

    func testCanAddDataStorePlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        XCTAssertNoThrow(try Amplify.add(plugin: plugin))
    }

    func testCanConfigureFirstWithEmptyConfiguration() throws {
        let plugin = MockDataStoreCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }

        try Amplify.add(plugin: plugin)

        let amplifyConfig = AmplifyConfiguration()
        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.DataStore)
        XCTAssertNotNil(Amplify.DataStore.plugin)
        wait(for: [methodInvokedOnDefaultPlugin], timeout: 1.0)
    }

    func testCanConfigureDataStorePlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(Amplify.DataStore)
        XCTAssertNotNil(try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin"))
    }

    func testCanResetDataStorePlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        let resetWasInvoked = expectation(description: "reset() was invoked")
        plugin.listeners.append { message in
            if message == "reset" {
                resetWasInvoked.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        waitForExpectations(timeout: 1.0)
    }

    func testResetRemovesAddedPlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        Amplify.reset()
        XCTAssertThrowsError(try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin"),
                             "Getting a plugin after reset() should throw") { error in
                                guard case DataStoreError.configuration = error else {
                                    XCTFail("Expected PluginError.noSuchPlugin")
                                    return
                                }
        }
    }

    func testCanRegisterMultipleDataStorePlugins() throws {
        let plugin1 = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: [
                "MockDataStoreCategoryPlugin": true,
                "MockSecondDataStoreCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        XCTAssertNotNil(try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin"))
        XCTAssertNotNil(try Amplify.DataStore.getPlugin(for: "MockSecondDataStoreCategoryPlugin"))
    }

    func testCanUseDefaultPluginIfOnlyOnePlugin() throws {
        let plugin = MockDataStoreCategoryPlugin()
        let methodInvokedOnDefaultPlugin = expectation(description: "test method invoked on default plugin")
        plugin.listeners.append { message in
            if message == "save" {
                methodInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: ["MockDataStoreCategoryPlugin": true])
        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        Amplify.DataStore.save(TestModel.make()) { _ in }

        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingWithMultiplePlugins() throws {
        let plugin1 = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin2)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: [
                "MockDataStoreCategoryPlugin": true,
                "MockSecondDataStoreCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)

        let exception: BadInstructionException? = catchBadInstruction {
            Amplify.DataStore.save(TestModel.make()) { _ in }
        }
        XCTAssertNotNil(exception)
    }

    func testCanUseSpecifiedPlugin() throws {
        let plugin1 = MockDataStoreCategoryPlugin()
        let methodShouldNotBeInvokedOnDefaultPlugin =
            expectation(description: "test method should not be invoked on default plugin")
        methodShouldNotBeInvokedOnDefaultPlugin.isInverted = true
        plugin1.listeners.append { message in
            if message == "save" {
                methodShouldNotBeInvokedOnDefaultPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin1)

        let plugin2 = MockSecondDataStoreCategoryPlugin()
        let methodShouldBeInvokedOnSecondPlugin =
            expectation(description: "test method should be invoked on second plugin")
        plugin2.listeners.append { message in
            if message == "save" {
                methodShouldBeInvokedOnSecondPlugin.fulfill()
            }
        }
        try Amplify.add(plugin: plugin2)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: [
                "MockDataStoreCategoryPlugin": true,
                "MockSecondDataStoreCategoryPlugin": true
            ]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.DataStore.getPlugin(for: "MockSecondDataStoreCategoryPlugin")
            .save(TestModel.make()) { _ in }
        waitForExpectations(timeout: 1.0)
    }

    func testCanConfigurePluginDirectly() throws {
        let plugin = MockDataStoreCategoryPlugin()
        let configureShouldBeInvokedFromCategory =
            expectation(description: "Configure should be invoked by Amplify.configure()")
        let configureShouldBeInvokedDirectly =
            expectation(description: "Configure should be invoked by getPlugin().configure()")

        var invocationCount = 0
        plugin.listeners.append { message in
            if message == "configure(using:)" {
                invocationCount += 1
                switch invocationCount {
                case 1: configureShouldBeInvokedFromCategory.fulfill()
                case 2: configureShouldBeInvokedDirectly.fulfill()
                default: XCTFail("Expected configure() to be called only two times, but got \(invocationCount)")
                }
            }
        }
        try Amplify.add(plugin: plugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        try Amplify.configure(amplifyConfig)
        try Amplify.DataStore.getPlugin(for: "MockDataStoreCategoryPlugin").configure(using: true)
        waitForExpectations(timeout: 1.0)
    }

    func testPreconditionFailureInvokingBeforeConfig() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)

        // Remember, this test must be invoked with a category that doesn't include an Amplify-supplied default plugin
        let exception: BadInstructionException? = catchBadInstruction {
            Amplify.DataStore.save(TestModel.make()) { _ in }
        }
        XCTAssertNotNil(exception)
    }

    // MARK: - Test internal config behavior guarantees

    func testThrowsConfiguringTwice() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        try Amplify.DataStore.configure(using: categoryConfig)
        XCTAssertThrowsError(try Amplify.DataStore.configure(using: categoryConfig),
                             "configure() an already configured plugin should throw") { error in
                                guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                                    XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured")
                                    return
                                }
        }
    }

    func testCanConfigureAfterReset() throws {
        let plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        let categoryConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        try Amplify.DataStore.configure(using: categoryConfig)

        let semaphore = DispatchSemaphore(value: 1)
        Amplify.DataStore.reset { semaphore.signal() }
        semaphore.wait()

        XCTAssertNoThrow(try Amplify.DataStore.configure(using: categoryConfig))
    }

}
