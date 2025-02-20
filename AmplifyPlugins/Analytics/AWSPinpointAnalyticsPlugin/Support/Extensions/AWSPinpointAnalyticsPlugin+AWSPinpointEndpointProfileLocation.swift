//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPinpoint

extension AWSPinpointEndpointProfileLocation {
    func addLocation(_ location: AnalyticsUserProfile.Location) {
        if let latitudeValue = location.latitude as NSNumber? {
            latitude = latitudeValue
        }

        if let longitudeValue = location.longitude as NSNumber? {
            longitude = longitudeValue
        }

        if let postalCodeValue = location.postalCode {
            postalCode = postalCodeValue
        }

        if let cityValue = location.city {
            city = cityValue
        }

        if let regionValue = location.region {
            region = regionValue
        }

        if let countryValue = location.country {
            country = countryValue
        }
    }
}
