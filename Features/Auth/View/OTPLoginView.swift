//
//  OTPLoginView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct OTPLoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer().frame(height: 24)
            Text("Giriş")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DS.Colors.textPrimary)
            Text("Rol").foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 10) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Button {
                        viewModel.role = role
                    } label: {
                        Text(role.titleTR)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.role == role ? .white : DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(viewModel.role == role ? DS.Colors.primary : .white)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(viewModel.role == role ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Telefon").foregroundStyle(DS.Colors.textSecondary)
            AppTextField(placeholder: "+90555...", text: $viewModel.phone, keyboardType: .phonePad)

            if let err = viewModel.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote)
            }

            PrimaryButton("Kod Gönder", isLoading: viewModel.isLoading) {
                Task { await viewModel.requestOTP() }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(DS.Colors.background.ignoresSafeArea())
    }
}
