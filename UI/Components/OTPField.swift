//
//  OTPField.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct OTPField: View {
    let placeholder: String
    @Binding var text: String
    let maxLength: Int

    init(_ placeholder: String = "OTP Kodu", text: Binding<String>, maxLength: Int = 6) {
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
    }

    var body: some View {
        AppTextField(
            placeholder: placeholder,
            text: Binding(
                get: { text },
                set: { newValue in
                    let digits = newValue.filter(\.isNumber)
                    text = String(digits.prefix(maxLength))
                }
            ),
            keyboardType: .numberPad
        )
    }
}
