import SwiftUI

struct CategoriesBrowseView: View {
    @Binding var selectedCategory: String
    @Environment(\.dismiss) private var dismiss

    private let categories = [
        ("Bebek", 746, 7),
        ("Yürümeye Başlayan", 836, 10),
        ("Okul Öncesi", 237, 14),
        ("Anaokulu", 935, 12),
        ("İlkokul", 4385, 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topBar
                categoryHeader

                Text("İhtiyacına uygun bakım kategorisini seç.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.horizontal, 16)

                ForEach(categories, id: \.0) { category in
                    Button {
                        selectedCategory = category.0
                        dismiss()
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DS.Colors.primary.opacity(0.65),
                                            DS.Colors.accent.opacity(0.82)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 140)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(.white.opacity(0.18), lineWidth: 1)
                                }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(category.0)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("\(category.1) bakıcı  •  ₺\(category.2)'den başlayan")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .padding(20)

                            HStack {
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(18)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private var categoryHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bakım Türleri")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.textPrimary)
            Text("Ailen için en uygun destek alanını seçerek sonuçları daralt.")
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var topBar: some View {
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

            Text("Kategoriler")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.textPrimary)

            Spacer()
            Color.clear.frame(width: 42, height: 42)
        }
        .padding(.horizontal, 16)
    }
}
