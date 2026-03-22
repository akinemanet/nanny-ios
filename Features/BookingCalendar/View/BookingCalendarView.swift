//
//  BookingCalendarView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BookingCalendarView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.l) {
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(DS.Colors.surface)
                    .frame(height: 320)
                    .overlay {
                        Text("Calendar Placeholder")
                            .font(DS.Typography.title)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }

                PrimaryButton("Confirm Booking") {}
            }
            .padding(DS.Spacing.l)
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("Booking Calendar")
        }
    }
}
