//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

@available(iOS 13.0, *)
class SubscriptionEndToEndTests: SyncEngineIntegrationTestBase {

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I start Amplify
    /// - Then:
    ///    - I receive subscriptions from other systems for syncable models
    func testSubscribeReceivesCreateMutateDelete() throws {
        try startAmplifyAndWaitForSync()

        let originalContent = "Original content from SubscriptionTests at \(Date())"
        let updatedContent = "UPDATED CONTENT from SubscriptionTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Create notification received")
        let deleteReceived = expectation(description: "Create notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                switch mutationEvent.mutationType {
                case GraphQLMutationType.create.rawValue:
                    createReceived.fulfill()
                case GraphQLMutationType.update.rawValue:
                    updateReceived.fulfill()
                case GraphQLMutationType.delete.rawValue:
                    deleteReceived.fulfill()
                default:
                    break
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let id = UUID().uuidString

        sendCreateRequest(withId: id, content: originalContent)
        wait(for: [createReceived], timeout: networkTimeout)

        let createSyncData = getMutationSync(forPostWithId: id)
        XCTAssertNotNil(createSyncData)
        let createdPost = createSyncData?.model.instance as? Post
        XCTAssertNotNil(createdPost)
        XCTAssertEqual(createdPost?.content, originalContent)
        XCTAssertEqual(createSyncData?.syncMetadata.version, 1)
        XCTAssertEqual(createSyncData?.syncMetadata.deleted, false)

        sendUpdateRequest(forId: id, content: updatedContent, version: 1)
        wait(for: [updateReceived], timeout: networkTimeout)
        let updateSyncData = getMutationSync(forPostWithId: id)
        XCTAssertNotNil(updateSyncData)
        let updatedPost = updateSyncData?.model.instance as? Post
        XCTAssertNotNil(updatedPost)
        XCTAssertEqual(updatedPost?.content, updatedContent)
        XCTAssertEqual(updateSyncData?.syncMetadata.version, 2)
        XCTAssertEqual(updateSyncData?.syncMetadata.deleted, false)

        sendDeleteRequest(forId: id, version: 2)
        wait(for: [deleteReceived], timeout: networkTimeout)
        let deleteSyncData = getMutationSync(forPostWithId: id)
        XCTAssertNil(deleteSyncData)
    }

    func sendCreateRequest(withId id: Model.Identifier, content: String) {
        // Note: The hand-written documents must include the sync/conflict resolution fields in order for the
        // subscription to get them
        let document = """
        mutation CreatePost($input: CreatePostInput!) { createPost(input: $input) {id content createdAt draft rating
        title updatedAt __typename _version _deleted _lastChangedAt } }
        """

        let input: [String: Any] = ["input":
            [
                "id": id,
                "title": Optional("This is a new post I created"),
                "content": content,
                "createdAt": Date().iso8601String,
                "draft": nil,
                "rating": nil,
                "updatedAt": nil
            ]
        ]

        let request = GraphQLRequest(document: document,
                                     variables: input,
                                     responseType: Post.self,
                                     decodePath: "createPost")

        _ = Amplify.API.mutate(request: request) { asyncEvent in
            switch asyncEvent {
            case .completed(let result):
                switch result {
                case .failure(let errors):
                    XCTFail(String(describing: errors))
                case .success(let post):
                    XCTAssertNotNil(post)
                }
            case .failed(let apiError):
                XCTFail(String(describing: apiError))
            default:
                break
            }
        }
    }

    func sendUpdateRequest(forId id: Model.Identifier, content: String, version: Int) {
        // Note: The hand-written documents must include the sync/conflict resolution fields in order for the
        // subscription to get them
        let document = """
        mutation UpdatePost($input: UpdatePostInput!) { updatePost(input: $input) {id content createdAt draft rating
        title updatedAt __typename _version _deleted _lastChangedAt } }
        """

        let input: [String: Any] = ["input":
            [
                "id": id,
                "content": content,
                "_version": version
            ]
        ]

        let request = GraphQLRequest(document: document,
                                     variables: input,
                                     responseType: Post.self,
                                     decodePath: "updatePost")

        _ = Amplify.API.mutate(request: request) { asyncEvent in
            switch asyncEvent {
            case .completed(let result):
                switch result {
                case .failure(let errors):
                    XCTFail(String(describing: errors))
                case .success(let post):
                    XCTAssertNotNil(post)
                }
            case .failed(let apiError):
                XCTFail(String(describing: apiError))
            default:
                break
            }
        }
    }

    func sendDeleteRequest(forId id: Model.Identifier, version: Int) {
        // Note: The hand-written documents must include the sync/conflict resolution fields in order for the
        // subscription to get them
        let document = """
        mutation DeletePost($input: DeletePostInput!) { deletePost(input: $input) {id content createdAt draft rating
        title updatedAt __typename _version _deleted _lastChangedAt } }
        """

        let input: [String: Any] = ["input":
            [
                "id": id,
                "_version": version
            ]
        ]

        let request = GraphQLRequest(document: document,
                                     variables: input,
                                     responseType: Post.self,
                                     decodePath: "deletePost")

        _ = Amplify.API.mutate(request: request) { asyncEvent in
            switch asyncEvent {
            case .completed(let result):
                switch result {
                case .failure(let errors):
                    XCTFail(String(describing: errors))
                case .success(let post):
                    XCTAssertNotNil(post)
                }
            case .failed(let apiError):
                XCTFail(String(describing: apiError))
            default:
                break
            }
        }
    }

    func getMutationSync(forPostWithId id: Model.Identifier) -> MutationSync<AnyModel>? {
        let semaphore = DispatchSemaphore(value: 1)
        var postFromQuery: Post?
        storageAdapter.query(Post.self, predicate: Post.keys.id == id) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let posts):
                // swiftlint:disable:next force_try
                postFromQuery = try! posts.unique()
            }
            semaphore.signal()
        }

        guard let post = postFromQuery else {
            return nil
        }

        let mutationSync = try? storageAdapter.queryMutationSync(for: [post]).first

        return mutationSync
    }

}
