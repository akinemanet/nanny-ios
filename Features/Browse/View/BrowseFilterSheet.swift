import SwiftUI

struct BrowseFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sortSelection = "En Yüksek Puan"
    @State private var genderSelection = "Kadın"
    @State private var experienceSelection = "Yürümeye Başlayan"
    @State private var price: Double = 45
    @State private var ratingSelection = 1
    @State private var showNearby = true

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
                    Toggle("Yakınımda Göster", isOn: $showNearby)
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
                                Image(systemName: sortSelection == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(sortSelection == option ? DS.Colors.accent : DS.Colors.textSecondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { sortSelection = option }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Cinsiyet")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        ForEach(["Erkek", "Kadın"], id: \.self) { option in
                            HStack {
                                Text(option)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Spacer()
                                Image(systemName: genderSelection == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(genderSelection == option ? DS.Colors.accent : DS.Colors.textSecondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { genderSelection = option }
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
                                    .foregroundStyle(experienceSelection == item ? DS.Colors.primary : DS.Colors.textSecondary)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(experienceSelection == item ? DS.Colors.primary.opacity(0.12) : .white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(experienceSelection == item ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                                    )
                                    .onTapGesture { experienceSelection = item }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Fiyat Aralığı")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        Text("₺10 - ₺87")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.Colors.textPrimary)

                        Text("Ortalama fiyat ₺45")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textSecondary)

                        Slider(value: $price, in: 10...87)
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
                                    .foregroundStyle(ratingSelection == item ? .white : DS.Colors.accent)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(ratingSelection == item ? DS.Colors.primary : DS.Colors.accent.opacity(0.08))
                                    )
                                    .onTapGesture { ratingSelection = item }
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
            .navigationTitle("Filtre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sıfırla") {
                        sortSelection = "En Yüksek Puan"
                        genderSelection = "Kadın"
                        experienceSelection = "Yürümeye Başlayan"
                        price = 45
                        ratingSelection = 1
                        showNearby = true
                    }
                    .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
    }
}
