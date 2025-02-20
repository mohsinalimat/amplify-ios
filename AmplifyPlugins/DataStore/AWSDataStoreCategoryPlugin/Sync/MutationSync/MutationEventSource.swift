//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol MutationEventSource: class {
    /// Gets the next available mutation event, marking it as "inProcess" before delivery
    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>)
}
