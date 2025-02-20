//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint

/// Implemented by `AWSPinpointAdapter` as a pass through to the methods on `pinpoint.analyticClient` and
/// `pinpoint.targetingClient`.
/// This protocol allows a way to create a Mock and ensure plugin implementation is testable.
protocol AWSPinpointBehavior: AWSPinpointAnalyticsClientBehavior, AWSPinpointTargetingClientBehavior {

    // Get the lower level `AWSPinpoint` client.
    func getEscapeHatch() -> AWSPinpoint
}

extension AWSPinpointBehavior {
    func removeGlobalProperty(withValue value: AnalyticsPropertyValue, forKey: String) {
        if value is String || value is Bool {
            removeGlobalAttribute(forKey: forKey)
        } else if value is Int || value is Double {
            removeGlobalMetric(forKey: forKey)
        }
    }

    func addGlobalProperty(withValue value: AnalyticsPropertyValue, forKey: String) {

        if let value = value as? String {
            addGlobalAttribute(value, forKey: forKey)
        } else if let value = value as? Int {
            addGlobalMetric(value as NSNumber, forKey: forKey)
        } else if let value = value as? Double {
            addGlobalMetric(value as NSNumber, forKey: forKey)
        } else if let value = value as? Bool {
            addGlobalAttribute(String(value), forKey: forKey)
        }
    }
}
