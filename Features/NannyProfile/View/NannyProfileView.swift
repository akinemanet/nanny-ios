//
//  NannyProfileView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct NannyProfileView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 260)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Sophia")
                        .font(DS.Typography.hero)
                    Text("5 years experience • 4.8 rating")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                AppCard {
                    Text("Experienced nanny focused on daily care, structured play, and bedtime support.")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.textPrimary)
                }

                PrimaryButton("Book Now") {}
            }
            .padding(DS.Spacing.l)
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Nanny Profile")
    }
}
