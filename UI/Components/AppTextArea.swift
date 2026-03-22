//
//  AppTextArea.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct AppTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(DS.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )

            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .foregroundStyle(DS.Colors.textPrimary)
                .tint(DS.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.clear)
        }
        .frame(minHeight: minHeight)
    }
}
