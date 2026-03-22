//
//  NannyCard.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct NannyCard: View {
    let provider: BrowseProvider

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(avatarGradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(initials)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }

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

                Text("\(provider.distanceText) • \(provider.age) yaş")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)

                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(DS.Colors.accent)
                    }
                    Text("12")
                        .font(.caption)
                        .foregroundStyle(DS.Colors.textSecondary)
                    Text("•")
                        .foregroundStyle(DS.Colors.textSecondary)
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
}
