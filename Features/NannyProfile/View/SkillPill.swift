//
//  SkillPill.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct SkillPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.15))
            .clipShape(Capsule())
    }
}
