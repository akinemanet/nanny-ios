//
//  BrowseView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BrowseView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar()
                    CategoryRow()

                    ForEach(0..<6, id: \.self) { _ in
                        NannyCard()
                    }
                }
                .padding()
            }
            .navigationTitle("Discover")
        }
    }
}

private struct SearchBar: View {
    var body: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.Colors.textSecondary)
            Text("Search nanny, area, service")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: DS.Size.fieldHeight)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }
}

private struct CategoryRow: View {
    private let items = ["Infant", "Night", "Weekend", "Tutor"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DS.Colors.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(DS.Colors.border, lineWidth: 1)
                        )
                }
            }
        }
    }
}

private struct NannyCard: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack {
                    Circle()
                        .fill(DS.Colors.primary.opacity(0.2))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(DS.Colors.primary)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ayse Y.")
                            .font(DS.Typography.bodyStrong)
                        Text("4.9 • Kadikoy")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }

                    Spacer()

                    Text("₺250/saat")
                        .font(DS.Typography.bodyStrong)
                }

                Text("Experienced nanny for daily care, evening support, and weekend help.")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)

                PrimaryButton("View Profile") {}
            }
        }
    }
}
