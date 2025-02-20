//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSPinpoint

extension AWSPinpointAnalyticsPlugin {

    /// Configures AWSPinpointAnalyticsPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any) throws {

        guard let config = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(
                AnalyticsPluginErrorConstant.decodeConfigurationError.errorDescription,
                AnalyticsPluginErrorConstant.decodeConfigurationError.recoverySuggestion)
        }

        let pluginConfiguration = try AWSPinpointAnalyticsPluginConfiguration(config)
        try configure(using: pluginConfiguration)
    }

    /// Configure AWSPinpointAnalyticsPlugin programatically using AWSPinpointAnalyticsPluginConfiguration
    public func configure(using configuration: AWSPinpointAnalyticsPluginConfiguration) throws {
        let authService = AWSAuthService()
        let cognitoCredentialsProvider = authService.getCognitoCredentialsProvider()

        let pinpoint = try AWSPinpointAdapter(
            pinpointAnalyticsAppId: configuration.appId,
            pinpointAnalyticsRegion: configuration.region,
            pinpointTargetingRegion: configuration.targetingRegion,
            cognitoCredentialsProvider: cognitoCredentialsProvider)

        let appSessionTracker =
            AppSessionTracker(trackAppSessions: configuration.trackAppSessions,
                              autoSessionTrackingInterval: configuration.autoSessionTrackingInterval)

        var autoFlushEventsTimer: DispatchSourceTimer?
        if configuration.autoFlushEventsInterval != 0 {
            let timeInterval = TimeInterval(configuration.autoFlushEventsInterval)
            autoFlushEventsTimer = RepeatingTimer.createRepeatingTimer(timeInterval: timeInterval,
                                                                       eventHandler: { [weak self] in
                self?.log.debug("AutoFlushTimer triggered, flushing events")
                self?.flushEvents()
            })
        }

        configure(pinpoint: pinpoint,
                  authService: authService,
                  autoFlushEventsTimer: autoFlushEventsTimer,
                  appSessionTracker: appSessionTracker)
    }

    // MARK: Internal

    /// Internal configure method to set the properties of the plugin
    func configure(pinpoint: AWSPinpointBehavior,
                   authService: AWSAuthServiceBehavior,
                   autoFlushEventsTimer: DispatchSourceTimer?,
                   appSessionTracker: Tracker) {
        self.pinpoint = pinpoint
        self.authService = authService
        self.appSessionTracker = appSessionTracker
        globalProperties = [:]
        isEnabled = true
        self.autoFlushEventsTimer = autoFlushEventsTimer
        self.autoFlushEventsTimer?.resume()
    }
}
