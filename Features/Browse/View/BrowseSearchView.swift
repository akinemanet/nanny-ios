import SwiftUI

struct BrowseSearchView: View {
    let providers: [BrowseProvider]
    @State private var query = ""

    private var filteredProviders: [BrowseProvider] {
        if query.isEmpty { return providers }
        return providers.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredProviders) { provider in
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(DS.Colors.surfaceAlt)
                            .frame(width: 72, height: 72)
                            .overlay {
                                Text("80 x 80")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DS.Colors.textSecondary)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text(provider.name)
                                    .font(.headline)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundStyle(DS.Colors.primary)
                            }

                            Text("0.31 mi uzaklık • 24 yaş")
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
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }

            Section("Son Aramalar") {
                ForEach(["Kristina Clark", "St. Louis Maria", "St. Gading Kasri"], id: \.self) { item in
                    Text(item)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Colors.background)
        .navigationTitle("Ara")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Bakıcı ara")
    }
}
