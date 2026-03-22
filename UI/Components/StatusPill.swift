//
//  StatusPill.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct StatusPill: View {
    let status: String

    private var color: Color {
        switch status.uppercased() {
        case "APPROVED": return .green
        case "FAILED": return .red
        default: return .orange
        }
    }

    var body: some View {
        Text(status)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
