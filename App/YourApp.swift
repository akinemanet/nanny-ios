//
//  YourApp.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI

@main
struct YourApp: App {
    @StateObject private var session = SessionStore(deps: AppDependencies.live())
    @AppStorage("didSeeOnboarding") private var didSeeOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView(didSeeOnboarding: $didSeeOnboarding)
                .environmentObject(session)
        }
    }
}
