//
//  NannyCard.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import UIKit
import Combine

struct NannyCard: View {
    let provider: BrowseProvider

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            avatarView

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(provider.displayName)
                        .font(.headline.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(2)

                    Spacer()

                    Image(systemName: "heart")
                        .foregroundStyle(Color.pink.opacity(0.75))
                }

                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(DS.Colors.accent)
                    }
                    if provider.reviewCount > 0 {
                        Text("\(provider.reviewCount)")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text("•")
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    Text("₺\(provider.hourlyRate)/saat")
                        .font(.subheadline.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
        }
        .padding(.vertical, 10)
        .background(DS.Colors.background)
        .overlay(alignment: .bottom) {
            Divider()
                .offset(y: 10)
        }
    }

    private var initials: String {
        let parts = provider.displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    private var subtitleText: String {
        if provider.age > 0 {
            return "\(provider.distanceText) • \(provider.age) yaş"
        }
        return provider.distanceText
    }

    private var avatarGradient: LinearGradient {
        let gradients: [[Color]] = [
            [Color(red: 0.20, green: 0.54, blue: 0.90), Color(red: 0.49, green: 0.74, blue: 0.98)],
            [Color(red: 0.98, green: 0.56, blue: 0.18), Color(red: 0.96, green: 0.74, blue: 0.34)],
            [Color(red: 0.33, green: 0.68, blue: 0.50), Color(red: 0.58, green: 0.83, blue: 0.66)],
            [Color(red: 0.56, green: 0.42, blue: 0.88), Color(red: 0.77, green: 0.63, blue: 0.95)]
        ]
        let index = abs(provider.displayName.hashValue) % gradients.count
        return LinearGradient(colors: gradients[index], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let photoURL = provider.photoURL, let url = URL(string: photoURL) {
            RemoteImageView(url: url) {
                avatarPlaceholder
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(avatarGradient)
            .frame(width: 80, height: 80)
            .overlay {
                Text(initials)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
    }
}

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
    private static let imageCache = NSCache<NSURL, UIImage>()

    @Published var image: UIImage?

    func load(from url: URL?) async {
        guard let url else {
            image = nil
            return
        }

        if let cachedImage = Self.imageCache.object(forKey: url as NSURL) {
            image = cachedImage
            return
        }

        do {
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                image = nil
                return
            }
            guard (200...299).contains(http.statusCode) else {
                image = nil
                return
            }
            guard let decoded = UIImage(data: data) else {
                image = nil
                return
            }
            image = decoded
            Self.imageCache.setObject(decoded, forKey: url as NSURL)
        } catch {
            image = nil
        }
    }
}
