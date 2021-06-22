//
//  ContentView.swift
//  Star Wars Cats
//
//  Created by Bre Meyer on 6/18/21.
//

import SwiftUI

// MARK: - Main View
struct ContentView: View {
    // MARK: Fields
    @ObservedObject private var viewModel = CatsViewModel()
    @State private var selection: String?
    @State private var searchText = ""

    // MARK: Body
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                List(viewModel.cats.filter { $0.name.contains(searchText) || searchText == "" },
                     id: \.self,
                     selection: $selection) { cat in
                    NavigationLink(
                        destination: CatDetail(cat: cat),
                        label: {
                            CatRow(name: cat.name, imageURL: cat.image)
                        })
                }
            }
            .navigationBarTitle(Text("STAR WARS CATS"))
        }
        .onAppear { viewModel.getData() }
    }
}

// MARK: - Row
struct CatRow: View {

    // MARK: Fields
    let name: String
    let imageURL: String

    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.colorScheme) var colorScheme

    // MARK: Body
    var body: some View {
        if sizeCategory >= .accessibilityMedium
        // I made a different layout for the list for accessibility so that the text does not get cut off
        {
            accessibilityLayout()
        } else {
            standardLayout()
        }
    }

    // MARK: Private Funcions
    private func accessibilityLayout() -> some View {
        VStack {
            RemoteImage(url: imageURL)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(Text(name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background((colorScheme == .dark ? Color.black : Color.white)
                                            .opacity(0.7)
                                            .blur(radius: 6)), alignment: .bottom)
                .frame(height: 300)
        }
    }

    private func standardLayout() -> some View {
        Group {
            RemoteImage(url: imageURL)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaledToFit()
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 60)
        .padding()
    }
}

// MARK: - Detail View
struct CatDetail: View {
    // MARK: Fields
    @Environment(\.colorScheme) var colorScheme
    @State private var isSharePresented = false
    let cat: StarWarsCatsFeed.Cat

    // MARK: Body
    var body: some View {
        VStack {
            RemoteImage(url: cat.image)
                .scaledToFit()
                .overlay(Text(cat.name)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((colorScheme == .dark ? Color.black: Color.white)
                                            .opacity(0.5)
                                            .blur(radius: 6)),
                         alignment: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
            listAttributes()
        }
    }

    // MARK: Private Functions
    private func listAttributes() -> some View {
        var labels: [String] = []
        for (property, value) in Mirror(reflecting: cat).children {
            // This grabs all of the keypaths and their values...
            guard let property = property,
                  let value = value as? String,
                  property != "image",
                  property != "name"
            // Skipping over `image` and `name`...
            else { continue }
            let text = "\(property.replacingOccurrences(of: "_", with: " ").capitalized): \(value)"
            // And formats the key/value pair into a string, then adds them to an array.
            labels.append(text)
        }
        return List(labels, id: \.self) { label in
            // now returning a list of the formatted keypaths and values
            Text(label)
                .padding()
        }
    }
}

// MARK: - Hosted Images
// in iOS 15 there is AsyncImage. This is my own implementation of something similar for iOS 14
struct RemoteImage: View {
    // MARK: Fields
    @ObservedObject private var loader: Loader

    // MARK: Body
    var body: some View {
        loader.image
            .resizable()
        // since `loader` is observed, this image will update as new data is available
    }

    // MARK: Private Classes
    private class Loader: ObservableObject {
        @Published var image: Image
        private let cacheKeyPrefix = "cat_image_"

        init(urlString: String, placeholder: Image) {
            image = placeholder
            guard let url = URL(string: urlString) else { return }
            // I don't like to force-cast. I'm not Anakin.

            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data,
                      let uiImage = UIImage(data: data)
                else {
                    // If the data cannot be retrieved or parsed, check for cached data
                    if let cachedImage = self.getCachedImage(forKey: urlString) {
                        DispatchQueue.main.async {
                            self.image = cachedImage
                        }
                    }
                    return
                }
                let image = Image(uiImage: uiImage)
                DispatchQueue.main.async {
                    self.image = image
                    self.cacheImageData(data, key: urlString)
                }

            }
            .resume()
        }

        private func cacheImageData(_ imageData: Data, key: String) {
            // For large apps one should use CoreData to cache. Using UserDefaults is a quick way to store small amounts of data.
            UserDefaults.standard.set(imageData, forKey: (cacheKeyPrefix + key))
        }

        private func getCachedImage(forKey key: String) -> Image? {
            guard let data =  UserDefaults.standard.object(forKey: (cacheKeyPrefix + key)) as? Data,
                  let uiImage = UIImage(data: data)
            else { return nil }
            return Image(uiImage: uiImage)
        }
    }

    // MARK: Init
    init(url: String, placeholder: Image = Image(systemName: "photo")) {
        _loader = ObservedObject(wrappedValue: Loader(urlString: url, placeholder: placeholder))
        // creates a new loader on initialization
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.colorScheme, .dark).environment(\.sizeCategory, .large)
    }
}
