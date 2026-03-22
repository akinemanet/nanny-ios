//
//  SplashView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            DS.Colors.primary.ignoresSafeArea()
            HStack(spacing: 0) {
                Text("evimde")
                    .foregroundStyle(.white)
                Text("bak")
                    .foregroundStyle(.orange)
            }
            .font(.system(size: 34, weight: .bold))
        }
    }
}
