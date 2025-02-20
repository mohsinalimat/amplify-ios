//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

class StorageAdapterMutationSyncTests: BaseDataStoreTests {

    /// - Given: a list of `Post` and `MutationSyncMetadata`
    /// - When:
    ///   - the `storageAdapter.queryMutationSync(for:)` is called
    /// - Then:
    ///   - the result should contain a list of `MutationSync`
    ///   - each `MutationSync` represents the correct pair of `Post` and `MutationSyncMetadata`
    func testQueryMutationSync() {
        let expect = expectation(description: "it should create posts and sync metadata")
        // insert some posts
        let posts = stride(from: 0, to: 3, by: 1).map {
            Post(title: "title \($0)", content: "content \($0)")
        }
        populateData(posts)

        // then create sync metadata for them
        let syncMetadataList = posts.map {
            MutationSyncMetadata(id: $0.id,
                                 deleted: false,
                                 lastChangedAt: Int(Date().timeIntervalSince1970),
                                 version: 1)
        }
        populateData(syncMetadataList)

        do {
            let mutationSync = try storageAdapter.queryMutationSync(for: posts)
            mutationSync.forEach {
                XCTAssertEqual($0.model.id, $0.syncMetadata.id)
                let post = $0.model.instance as? Post
                XCTAssertNotNil(post)
            }
            expect.fulfill()
        } catch {
            XCTFail(error.localizedDescription)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 5)
    }

}
