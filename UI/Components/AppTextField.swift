//
//  AppTextField.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import UIKit

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.horizontal, 18)
            }

            TextField("", text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(DS.Colors.textPrimary)
                .tint(DS.Colors.textPrimary)
                .padding(.horizontal, 18)
        }
        .frame(height: DS.Size.fieldHeight)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }
}
