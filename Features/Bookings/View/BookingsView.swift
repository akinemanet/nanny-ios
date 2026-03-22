//
//  BookingsView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BookingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.m) {
                Text("Bookings")
                    .font(DS.Typography.title)
                Text("Bookings screen placeholder")
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(DS.Spacing.l)
        }
    }
}
