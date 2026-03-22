//
//  ContentView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        YourAppRootPreview()
    }
}

#Preview {
    ContentView()
}

private struct YourAppRootPreview: View {
    @StateObject private var session = SessionStore(deps: AppDependencies.live())

    var body: some View {
        Group {
            if session.isBootstrapping {
                ProgressView("Yükleniyor…")
            } else if session.isLoggedIn {
                HomeView()
            } else {
                AuthFlowView()
            }
        }
        .environmentObject(session)
    }
}
