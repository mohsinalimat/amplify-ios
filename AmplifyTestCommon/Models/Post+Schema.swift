//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// swiftlint:disable all
extension Post {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case title
        case content
        case createdAt
        case updatedAt
        case rating
        case draft
        case comments
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let post = Post.keys

        model.pluralName = "Posts"
        model.attributes(.isSyncable)

        model.fields(
            .id(),
            .field(post.title, is: .required, ofType: .string),
            .field(post.content, is: .required, ofType: .string),
            .field(post.createdAt, is: .required, ofType: .dateTime),
            .field(post.updatedAt, is: .optional, ofType: .dateTime),
            .field(post.rating, is: .optional, ofType: .double),
            .field(post.draft, is: .optional, ofType: .bool),

            .hasMany(post.comments,
                     ofType: Comment.self,
                     associatedWith: Comment.keys.post)
        )
    }

}
