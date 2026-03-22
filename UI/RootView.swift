//
//  RootView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var session: SessionStore
    @Binding var didSeeOnboarding: Bool

    var body: some View {

        Group {

            if !didSeeOnboarding {

                OnboardingPagerView {
                    didSeeOnboarding = true
                }

            } else if session.isBootstrapping {

                ProgressView("Yükleniyor...")

            } else if !session.isLoggedIn {

                AuthFlowView()

            } else {

                if session.me?.user.role == "PROVIDER" {

                    NavigationStack {
                        ProviderOnboardingView(
                            service: ProviderService(api: session.deps.api)
                        )
                    }

                } else {

                    HomeView()
                }

            }
        }
        .task {
            await session.bootstrap()
        }
    }
}
