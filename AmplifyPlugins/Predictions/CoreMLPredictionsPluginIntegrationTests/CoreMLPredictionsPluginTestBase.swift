//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import CoreMLPredictionsPlugin

class AWSPredictionsPluginTestBase: XCTestCase {

    let region: JSONValue = "us-east-1"
    let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts

    override func setUp() {

        setupAmplify()
    }

    override func tearDown() {
        print("Amplify reset")
        Amplify.reset()
        sleep(5)
    }

    private func setupAmplify() {
        // Set up Amplify predictions configuration
        let predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "awsPredictionsPlugin": [
                    "defaultRegion": region
                ]
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: predictionsConfig)

        // Set up Amplify
        do {
            try Amplify.add(plugin: CoreMLPredictionsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }


}
