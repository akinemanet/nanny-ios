//
//  OnboardingPageView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .fill(Color.gray.opacity(0.18))
                .frame(height: 280)
                .overlay(
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                        .foregroundStyle(.orange)
                )

            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.black)

            Text(subtitle)
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(DS.Colors.background)
    }
}
