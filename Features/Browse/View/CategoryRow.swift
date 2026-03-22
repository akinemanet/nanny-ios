//
//  CategoryRow.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct CategoryRow: View {
    let categories = [
        "Bebek",
        "Yürümeye Başlayan",
        "Okul Öncesi",
        "Anaokulu"
    ]
    @Binding var selectedCategory: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { cat in
                    Text(cat)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedCategory == cat ? DS.Colors.primary : .white)
                        .foregroundStyle(selectedCategory == cat ? .white : DS.Colors.textSecondary)
                        .overlay {
                            Capsule()
                                .stroke(selectedCategory == cat ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                        }
                        .clipShape(Capsule())
                        .onTapGesture { selectedCategory = cat }
                }
            }
        }
    }
}
