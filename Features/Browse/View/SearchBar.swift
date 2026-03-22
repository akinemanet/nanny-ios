//
//  SearchBar.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.Colors.textSecondary)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Bakıcı ara")
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                TextField("", text: $text)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tint(DS.Colors.textPrimary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
