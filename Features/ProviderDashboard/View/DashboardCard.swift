//
//  DashboardCard.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct DashboardCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .foregroundStyle(DS.Colors.textSecondary)

            Text(value)
                .font(.title.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 3)
    }
}
