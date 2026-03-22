//
//  PhoneField.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct PhoneField: View {
    let placeholder: String
    @Binding var text: String

    init(_ placeholder: String = "+90555...", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        AppTextField(
            placeholder: placeholder,
            text: Binding(
                get: { text },
                set: { newValue in
                    let filtered = newValue.filter { $0.isNumber || $0 == "+" }
                    text = filtered
                }
            ),
            keyboardType: .phonePad
        )
    }
}
