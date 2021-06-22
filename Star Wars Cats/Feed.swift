//
//  Feed.swift
//  Star Wars Cats
//
//  Created by Bre Meyer on 6/18/21.
//

import Foundation

struct StarWarsCatsFeed: Hashable, Codable {

    static func decodeFromJSON(_ data: Data?) -> StarWarsCatsFeed? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(StarWarsCatsFeed.self, from: data)
        // do or do not, until you need to try? decoding
    }

    let results: [Cat]

    struct Cat: Hashable, Codable {
        let name: String
        let height: String
        let mass: String
        let hair_color: String
        let skin_color: String
        let eye_color: String
        let birth_year: String
        let gender: String
        let image: String
    }
}
