//
//  OTPVerifyView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct OTPVerifyView: View {
    @ObservedObject var viewModel: AuthViewModel
    let onVerified: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer().frame(height: 24)
            Text("Doğrulama")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DS.Colors.textPrimary)
            Text("Telefonuna gönderilen kodu gir").foregroundStyle(DS.Colors.textSecondary)
            AppTextField(placeholder: "OTP Kodu", text: $viewModel.code, keyboardType: .numberPad)

            if let devCode = viewModel.devCode, !devCode.isEmpty {
                Text("HATA AYIKLAMA KODU: \(devCode)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(DS.Colors.textPrimary)
            }

            if let err = viewModel.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote)
            }

            PrimaryButton("Doğrula", isLoading: viewModel.isLoading) {
                Task {
                    let ok = await viewModel.verifyOTP()
                    if ok { onVerified() }
                }
            }

            Button("Geri") { viewModel.backToPhone() }
            .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(DS.Colors.background.ignoresSafeArea())
    }
}
