//
//  ProviderDashboardView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct ProviderDashboardView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    AppCard {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Provider Dashboard")
                                .font(DS.Typography.title)
                            Text(session.me?.user.phone ?? "No provider data")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Upcoming Jobs")
                                .font(DS.Typography.bodyStrong)
                            Text("No active jobs yet")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                }
                .padding(DS.Spacing.l)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
        }
    }
}
