//
//  ViewModel.swift
//  Star Wars Cats
//
//  Created by Bre Meyer on 6/18/21.
//

import Foundation
import SwiftUI

final class CatsViewModel: ObservableObject {
    // MARK: Fields
    @Published var cats: [StarWarsCatsFeed.Cat]
    private let cacheKeyPrefix = "star_wars_cat_feed_"

    // MARK: Init
    init() {
        cats = []
    }

    // MARK: Functions
    func getData() {
        let urlString = "https://duet-public-content.s3.us-east-2.amazonaws.com/project.json"
        guard let url = URL(string:  urlString)
        else { return } // I don't like force-casting. This guard just to prevent force-casting.
        // may the force-casting be with you...
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let parsedData = StarWarsCatsFeed.decodeFromJSON(data)?.results
            else {
                // If the data cannot be retrieved from online or parsed, see if there is any cached data available
                if let cachedFeed = self.getCachedFeed(forKey: urlString) {
                    DispatchQueue.main.async {
                        self.cats = cachedFeed
                    }
                }
                return
            }
            DispatchQueue.main.async {
                self.cats = parsedData
                self.cacheData(data, forKey: urlString)
            }
        }.resume()
    }

    private func cacheData(_ data: Data, forKey key: String) {
        // For large apps one should use CoreData to cache. Using UserDefaults is a quick way to store small amounts of data.
        UserDefaults.standard.set(data, forKey: (cacheKeyPrefix + key))
    }

    private func getCachedFeed(forKey key: String) -> [StarWarsCatsFeed.Cat]? {
        guard let cachedData = UserDefaults.standard.object(forKey: (cacheKeyPrefix + key)) as? Data,
              let json = try? JSONSerialization.data(withJSONObject: cachedData, options: [])
        else { return nil }
        return StarWarsCatsFeed.decodeFromJSON(json)?.results
    }
}
