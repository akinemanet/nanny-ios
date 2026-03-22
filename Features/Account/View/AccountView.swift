//
//  AccountView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.m) {
                Text("Account")
                    .font(DS.Typography.title)
                Text(session.me?.user.phone ?? "No account data")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)

                DangerButton("Çıkış") {
                    session.logout()
                }
            }
            .padding(DS.Spacing.l)
        }
    }
}
