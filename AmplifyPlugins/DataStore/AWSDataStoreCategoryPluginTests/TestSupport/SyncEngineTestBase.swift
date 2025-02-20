//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class SyncEngineTestBase: XCTestCase {

    /// Mock used to listen for API calls; this is how we assert that syncEngine is delivering events to the API
    var apiPlugin: MockAPICategoryPlugin!

    var amplifyConfig: AmplifyConfiguration!

    var storageAdapter: StorageEngineAdapter!

    // MARK: - Setup

    override func setUp() {
        continueAfterFailure = false

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        apiPlugin = MockAPICategoryPlugin()
        tryOrFail {
            try Amplify.add(plugin: apiPlugin)
        }
    }

    /// Sets up a StorageAdapter backed by an in-memory SQLite database
    func setUpStorageAdapter() throws {
        let connection = try Connection(.inMemory)
        storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
        try storageAdapter.setUp(models: StorageEngine.systemModels + [Post.self, Comment.self])
    }

    func setUpDataStore() throws {
        let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
        let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
        let outgoingMutationQueue = NoOpMutationQueue()

        let syncEngine = RemoteSyncEngine(storageAdapter: storageAdapter,
                                         outgoingMutationQueue: outgoingMutationQueue,
                                         mutationEventIngester: mutationDatabaseAdapter,
                                         mutationEventPublisher: awsMutationEventPublisher)

        let storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          syncEngine: syncEngine,
                                          isSyncEnabled: true)

        let publisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                         storageEngine: storageEngine,
                                                         dataStorePublisher: publisher)

        try Amplify.add(plugin: dataStorePlugin)
    }

    func startAmplify() throws {
        try Amplify.configure(amplifyConfig)
    }

    func startAmplifyAndWaitForSync() throws {
        try setUpDataStore()

        let syncStarted = expectation(description: "Sync started")
        let token = Amplify.Hub.listen(to: .dataStore,
                                       eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                        syncStarted.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Never registered listener for sync started")
            return
        }

        try startAmplify()

        wait(for: [syncStarted], timeout: 5.0)
        Amplify.Hub.removeListener(token)
    }

    // MARK: - Data methods

    func saveMutationEvent(of mutationType: MutationEvent.MutationType,
                           for post: Post,
                           inProcess: Bool = false) throws {
        let mutationEvent = try MutationEvent(id: SyncEngineTestBase.mutationEventId(for: post),
                                              modelId: post.id,
                                              modelName: post.modelName,
                                              json: post.toJSON(),
                                              mutationType: mutationType,
                                              createdAt: Date(),
                                              inProcess: inProcess)

        let mutationEventSaved = expectation(description: "Preloaded mutation event saved")
        storageAdapter.save(mutationEvent) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
            case .success:
                mutationEventSaved.fulfill()
            }
        }
        wait(for: [mutationEventSaved], timeout: 1.0)
    }

    // Several tests require there to be a post in the database prior to starting. This utility supports that.
    func savePost(_ post: Post) throws {
        let postSaved = expectation(description: "Preloaded mutation event saved")
        storageAdapter.save(post) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
            case .success:
                postSaved.fulfill()
            }
        }
        wait(for: [postSaved], timeout: 1.0)
    }

    // MARK: - Helpers

    static func mutationEventId(for post: Post) -> String {
        "mutation-of-\(post.id)"
    }

}
