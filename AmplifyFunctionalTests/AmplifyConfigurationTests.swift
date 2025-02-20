//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

@testable import AmplifyTestCommon

class AmplifyConfigurationTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    /// Given: An app with an `amplifyconfiguration.json` file in the main bundle
    /// When: `Amplify.configure()` is invoked
    /// Then: The Amplify framework is successfully configured from the config file stored in the bundle
    func testConfigureReadsFromFile() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure()
        XCTAssertNotNil(try Amplify.Storage.getPlugin(for: plugin.key))
        XCTAssertNoThrow(Amplify.Storage.downloadData(key: "", options: nil, listener: nil))
    }

    func testMultipleConfigureCallsFromFileThrowError() throws {
        let plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure()
        XCTAssertThrowsError(try Amplify.configure()) { error in
            guard case ConfigurationError.amplifyAlreadyConfigured = error else {
                XCTFail("Expected ConfigurationError.amplifyAlreadyConfigured error, got: \(error)")
                return
            }
        }
    }

}
