//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Amplify

public struct IdentifyConfiguration {

    public let region: AWSRegionType
    public let identifyLabels: IdentifyLabelsConfiguration?
    public let identifyEntities: IdentifyEntitiesConfiguration?
    public let identifyText: IdentifyTextConfiguration?

    init(_ region: AWSRegionType) {
        self.region = region
        self.identifyLabels = nil
        self.identifyEntities = nil
        self.identifyText = nil
    }
}

public struct IdentifyLabelsConfiguration {
    public let type: LabelType
}

public struct IdentifyTextConfiguration {
    public let format: TextFormatType
}

public struct IdentifyEntitiesConfiguration {
    public let collectionId: String?
    public let maxEntities: String?
}

extension IdentifyConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case region
        case identifyLabels
        case identifyEntities
        case identifyText
    }

    enum SubRegion: String, CodingKey {
        case region
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var awsRegion: AWSRegionType?

        if let configuration = try values.decodeIfPresent(IdentifyLabelsConfiguration.self,
                                                          forKey: .identifyLabels) {
            self.identifyLabels = configuration
            let nestedContainer = try values.nestedContainer(keyedBy: SubRegion.self,
                                                            forKey: .identifyLabels)
            awsRegion = awsRegion ?? IdentifyConfiguration.getRegionIfPresent(nestedContainer)
        } else {
            self.identifyLabels = nil
        }

        if let configuration = try values.decodeIfPresent(IdentifyEntitiesConfiguration.self,
                                                          forKey: .identifyEntities) {
            self.identifyEntities = configuration
            let nestedContainer = try values.nestedContainer(keyedBy: SubRegion.self,
                                                              forKey: .identifyEntities)
            awsRegion = awsRegion ?? IdentifyConfiguration.getRegionIfPresent(nestedContainer)

        } else {
            self.identifyEntities = nil
        }

        if let configuration  = try values.decodeIfPresent(IdentifyTextConfiguration.self,
                                                           forKey: .identifyText) {
            self.identifyText = configuration
            let nestedContainer = try values.nestedContainer(keyedBy: SubRegion.self,
                                                             forKey: .identifyText)
            awsRegion = awsRegion ?? IdentifyConfiguration.getRegionIfPresent(nestedContainer)
        } else {
            self.identifyText = nil
        }

        guard  let region = awsRegion else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.missingRegion.errorDescription,
                                                       PluginErrorMessage.missingRegion.recoverySuggestion)
        }
        self.region = region
    }

    static func getRegionIfPresent(_ container: KeyedDecodingContainer<SubRegion>) -> AWSRegionType? {
        guard let textRegionString = try? container.decodeIfPresent(String.self, forKey: .region) as NSString? else {
            return nil
        }
        return textRegionString.aws_regionTypeValue()
    }
}

extension IdentifyLabelsConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(LabelType.self, forKey: .type)
    }
}

extension LabelType: Decodable {

    enum CodingError: Error {
           case unknownValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "ALL":
            self = .all
        case "MODERATION":
            self = .moderation
        case "LABELS":
            self = .labels
        default:
            throw CodingError.unknownValue
        }
    }
}

extension IdentifyTextConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case format
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        format = try values.decode(TextFormatType.self, forKey: .format)
    }
}

extension TextFormatType: Decodable {

    enum CodingError: Error {
           case unknownValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "ALL":
            self = .all
        case "TABLE":
            self = .table
        case "PLAIN":
            self = .plain
        case "FORM":
            self = .form
        default:
            throw CodingError.unknownValue
        }
    }
}

extension IdentifyEntitiesConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case collectionId
        case maxEntities
    }
}
