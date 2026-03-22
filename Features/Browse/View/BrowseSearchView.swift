import SwiftUI

struct BrowseSearchView: View {
    let providers: [BrowseProvider]
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredProviders: [BrowseProvider] {
        if query.isEmpty { return providers }
        return providers.filter {
            $0.displayName.localizedCaseInsensitiveContains(query) ||
            $0.locationName.localizedCaseInsensitiveContains(query) ||
            $0.categories.joined(separator: " ").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
                }

                Spacer()

                Text("Ara")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.textPrimary)

                Spacer()
                Color.clear.frame(width: 42, height: 42)
            }

            SearchBar(text: $query)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredProviders) { provider in
                        SearchProviderRow(provider: provider)
                    }

                    if query.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        Text("Son Aramalar")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textSecondary)

                        ForEach(["Barbara Michelle", "Amber Julia", "Kristina Clark"], id: \.self) { item in
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(DS.Colors.textSecondary)
                                Text(item)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

private struct SearchProviderRow: View {
    let provider: BrowseProvider

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DS.Colors.surface)
                .frame(width: 72, height: 72)
                .overlay {
                    Text("80 x 80")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.textSecondary)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(provider.displayName)
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(DS.Colors.primary)
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
                    Text("• ₺\(Int(provider.hourlyRate))/saat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}
