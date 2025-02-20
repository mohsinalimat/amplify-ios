//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

/// A mutation queue that takes no action on either pause or start, to let these unit tests operate on the
/// mutation queue without interference from the mutation queue polling for events and marking them in-process.
class NoOpMutationQueue: OutgoingMutationQueueBehavior {
    func pauseSyncingToCloud() {
        // do nothing
    }

    func startSyncingToCloud(api: APICategoryGraphQLBehavior, mutationEventPublisher: MutationEventPublisher) {
        // do nothing
    }
}
