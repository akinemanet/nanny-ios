//
//  RemoteImageView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 29.03.2026.
//

import SwiftUI
import UIKit

struct RemoteImageView<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @StateObject private var loader = RemoteImageLoader()

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published var image: UIImage?

    func load(from url: URL?) async {
        guard let url else {
            image = nil
            return
        }

        do {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                image = nil
                return
            }
            image = UIImage(data: data)
        } catch {
            image = nil
        }
    }
}
