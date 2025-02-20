//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
import AWSS3StoragePlugin
import AWSS3

class AWSS3StoragePluginDownloadDataResumabilityTests: AWSS3StoragePluginTestBase {

    /// Given: A large data object in storage
    /// When: Call the get API then pause
    /// Then: The operation is stalled (no progress, completed, or failed event)
    func testDownloadLargeDataAndPause() {
        let key = "testGetLargeDataAndPause"
        uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completeInvoked = expectation(description: "Completion invoked")
        completeInvoked.isInverted = true
        let failedInvoked = expectation(description: "Failed invoked")
        failedInvoked.isInverted = true
        let noProgressAfterPause = expectation(description: "Progress after pause is invoked")
        noProgressAfterPause.isInverted = true
        let operation = Amplify.Storage.downloadData(key: key, options: nil) { event in
            switch event {
            case .inProcess(let progress):
                // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
                if progress.fractionCompleted > 0.3 {
                    progressInvoked.fulfill()
                }

                // After pausing, progress events still trickle in, but should not exceed
                if progress.fractionCompleted > 0.7 {
                    noProgressAfterPause.fulfill()
                }
            case .completed:
                completeInvoked.fulfill()
            case .failed:
                failedInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: networkTimeout)
        operation.pause()
        wait(for: [completeInvoked, failedInvoked, noProgressAfterPause], timeout: 30)
    }

    /// Given: A large data object in storage
    /// When: Call the downloadData API, pause, and then resume the operation
    /// Then: The operation should complete successfully
    func testDownloadLargeDataAndPauseThenResume() {
        let key = "testGetLargeDataAndPauseThenResume"
        uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completeInvoked = expectation(description: "Complete invoked")
        let operation = Amplify.Storage.downloadData(key: key, options: nil) { event in
            switch event {
            case .inProcess(let progress):
                // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
                if progress.fractionCompleted > 0.3 {
                    progressInvoked.fulfill()
                }
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: networkTimeout)
        operation.pause()
        operation.resume()
        wait(for: [completeInvoked], timeout: networkTimeout)
    }

    /// Given: A large data object in storage
    /// When: Call the get API then cancel the operation,
    /// Then: The operation should not complete or fail.
    func testDownloadLargeDataAndCancel() {
        let key = "testGetLargeDataAndCancel"
        uploadData(key: key, data: AWSS3StoragePluginTestBase.largeDataObject)

        let progressInvoked = expectation(description: "Progress invoked")
        progressInvoked.assertForOverFulfill = false
        let completedInvoked = expectation(description: "Completion invoked")
        completedInvoked.isInverted = true
        let failedInvoked = expectation(description: "Failed invoked")
        failedInvoked.isInverted = true
        let operation = Amplify.Storage.downloadData(key: key, options: nil) { event in
            switch event {
            case .inProcess(let progress):
                // To simulate a normal scenario, fulfill the progressInvoked expectation after some progress (30%)
                if progress.fractionCompleted > 0.3 {
                    progressInvoked.fulfill()
                }
            case .completed:
                completedInvoked.fulfill()
            case .failed:
                failedInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        wait(for: [progressInvoked], timeout: networkTimeout)
        operation.cancel()
        wait(for: [completedInvoked, failedInvoked], timeout: 30)
    }
}
