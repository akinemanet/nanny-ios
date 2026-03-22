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

            VStack(spacing: 10) {
                Text("EvimdeBak")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Capsule()
                    .fill(.yellow)
                    .frame(width: 44, height: 4)
            }
        }
    }
}
