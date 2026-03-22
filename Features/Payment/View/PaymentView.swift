//
//  PaymentView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct PaymentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.l) {
                AppCard {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Payment Summary")
                            .font(DS.Typography.bodyStrong)
                        Text("3 hours care service")
                            .font(DS.Typography.body)
                        Text("Total: $45")
                            .font(DS.Typography.title)
                    }
                }

                PrimaryButton("Pay Now") {}
            }
            .padding(DS.Spacing.l)
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("Payment")
        }
    }
}
