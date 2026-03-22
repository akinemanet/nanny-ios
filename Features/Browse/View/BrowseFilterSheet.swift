import SwiftUI

struct BrowseFilters {
    var sortSelection = "Popülerlik"
    var genderSelection = "Tümü"
    var experienceSelection: String?
    var maxPrice: Double = 800
    var ratingSelection = 1
    var showNearby = false

    static let `default` = BrowseFilters()
}

struct BrowseFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: BrowseFilters

    private let sortOptions = [
        "Popülerlik",
        "En Yüksek Puan",
        "En Düşük Puan",
        "En Çok Değerlendirilen",
        "En Çok Yorumlanan",
        "En Düşük Fiyat",
        "En Yüksek Fiyat"
    ]

    private let experiences = ["Bebek", "Yürümeye Başlayan", "Okul Öncesi", "Anaokulu", "İlkokul"]
    private let ratings = [1, 2, 3, 4, 5]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    filterTopBar

                    Toggle(isOn: $filters.showNearby) {
                        Text("Yakınımda Göster")
                            .foregroundStyle(DS.Colors.textPrimary)
                    }
                    .tint(DS.Colors.primary)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sıralama")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        ForEach(sortOptions, id: \.self) { option in
                            HStack {
                                Text(option)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Spacer()
                                Image(systemName: filters.sortSelection == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(filters.sortSelection == option ? DS.Colors.accent : DS.Colors.textSecondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { filters.sortSelection = option }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Cinsiyet")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        ForEach(["Tümü", "Erkek", "Kadın"], id: \.self) { option in
                            HStack {
                                Text(option)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Spacer()
                                Image(systemName: filters.genderSelection == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(filters.genderSelection == option ? DS.Colors.accent : DS.Colors.textSecondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { filters.genderSelection = option }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Deneyim")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                            ForEach(experiences, id: \.self) { item in
                                Text(item)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(filters.experienceSelection == item ? DS.Colors.primary : DS.Colors.textSecondary)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(filters.experienceSelection == item ? DS.Colors.primary.opacity(0.12) : .white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(filters.experienceSelection == item ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        filters.experienceSelection = filters.experienceSelection == item ? nil : item
                                    }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Fiyat Aralığı")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        Text("₺300 - ₺800")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.Colors.textPrimary)

                        Text("Seçili üst sınır ₺\(Int(filters.maxPrice))")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textSecondary)

                        Slider(value: $filters.maxPrice, in: 300...800, step: 25)
                            .tint(DS.Colors.primary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Yıldız Puanı")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        HStack(spacing: 10) {
                            ForEach(ratings, id: \.self) { item in
                                Text("\(item) ★")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(filters.ratingSelection == item ? .white : DS.Colors.accent)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(filters.ratingSelection == item ? DS.Colors.primary : DS.Colors.accent.opacity(0.08))
                                    )
                                    .onTapGesture { filters.ratingSelection = item }
                            }
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Filtreleri Uygula")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DS.Colors.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
        }
    }

    private var filterTopBar: some View {
        HStack {
            Color.clear.frame(width: 42, height: 42)

            Spacer()

            Text("Filtre")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.textPrimary)

            Spacer()

            Button("Sıfırla") {
                filters = .default
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DS.Colors.textSecondary)
            .frame(width: 64, height: 42)
            .background(.white, in: Capsule())
        }
    }
}
