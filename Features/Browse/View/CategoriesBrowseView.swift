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
            VStack(spacing: 18) {
                ForEach(categories, id: \.0) { category in
                    Button {
                        selectedCategory = category.0
                        dismiss()
                    } label: {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.1), Color.black.opacity(0.55)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 140)
                                .overlay {
                                    Text("343 x 122")
                                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.22))
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
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Kategoriler")
        .navigationBarTitleDisplayMode(.large)
    }
}
