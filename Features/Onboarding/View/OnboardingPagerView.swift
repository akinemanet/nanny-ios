//
//  OnboardingPagerView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct OnboardingPagerView: View {
    let onDone: () -> Void
    @State private var index = 0

    private let pages: [(String, String, String)] = [
        ("Keşfet", "Bulunduğun bölgede sana en uygun bakıcıyı bul.", "magnifyingglass"),
        ("Planla", "Senin ve bakıcının uygun olduğu zamanı seç.", "calendar"),
        ("Bağlı Kal", "Mesajlar ve aramalarla anlık olarak iletişimde kal.", "video")
    ]

    var body: some View {
        VStack {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                    VStack(spacing: 20) {
                        Spacer()

                        RoundedRectangle(cornerRadius: DS.Radius.medium)
                            .fill(Color.black.opacity(0.08))
                            .frame(height: 280)
                            .overlay(Image(systemName: page.2).font(.largeTitle).foregroundStyle(.orange))

                        Text(page.0)
                            .font(.system(size: 30, weight: .bold))

                        Text(page.1)
                            .foregroundStyle(DS.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                if index == pages.count - 1 {
                    PrimaryButton("Başla") {
                        onDone()
                    }
                } else {
                    Button("Geç") {
                        onDone()
                    }
                    .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(DS.Colors.background.ignoresSafeArea())
    }
}
