//
//  AuthFlowView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct AuthFlowView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel: AuthViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AuthViewModel.placeholder())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.step == .enterPhone {
                    OTPLoginView(viewModel: viewModel)
                } else {
                    OTPVerifyView(viewModel: viewModel) {
                        Task { await session.bootstrap() }
                    }
                }
            }
        }
        .onAppear {
            viewModel.attachIfNeeded(session: session)
        }
    }
}
