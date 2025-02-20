//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSRekognition
import Amplify

class IdentifyCelebritiesResultTransformers: IdentifyResultTransformers {
    static func processCelebs(_ rekognitionCelebs: [AWSRekognitionCelebrity]) -> [Celebrity] {
        var celebs = [Celebrity]()
        for rekognitionCeleb in rekognitionCelebs {

            guard let name = rekognitionCeleb.name,
                let identifier = rekognitionCeleb.identifier,
                let face = rekognitionCeleb.face,
                let stringUrls = rekognitionCeleb.urls else {
                continue
            }
            var urls = [URL]()
            for url in stringUrls {
                guard let newUrl = URL(string: url) else { continue }

                urls.append(newUrl)
            }

            guard let pitch = face.pose?.pitch, let roll = face.pose?.roll, let yaw = face.pose?.yaw else {
                continue
            }

            let pose = Pose(
                pitch: Double(truncating: pitch),
                roll: Double(truncating: roll),
                yaw: Double(truncating: yaw))

            let metadata = CelebrityMetadata(name: name, identifier: identifier, urls: urls, pose: pose)

            guard let boundingBox = processBoundingBox(face.boundingBox) else {
                continue
            }

            let landmarks = processLandmarks(face.landmarks)

            let celeb = Celebrity(metadata: metadata, boundingBox: boundingBox, landmarks: landmarks)

            celebs.append(celeb)
        }

        return celebs
    }
}
