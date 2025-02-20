//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

@available(iOS 13.0, *)
final class MutationEventSubscription: Subscription {

    private var demand = Subscribers.Demand.none
    let subscriber: MutationEventSubscriber
    private weak var publisher: AWSMutationEventPublisher?

    init<S>(subscriber: S,
            publisher: AWSMutationEventPublisher) where S: Subscriber,
        S.Failure == DataStoreError,
        S.Input == MutationEvent {
            self.subscriber = MutationEventSubscriber(subscriber: subscriber)
            self.publisher = publisher
    }

    func cancel() {
        publisher?.cancel()
    }

    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
        publisher?.request(demand)
    }
}

@available(iOS 13.0, *)
extension MutationEventSubscription: DefaultLogger { }
