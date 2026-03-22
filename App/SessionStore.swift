//
//  SessionStore.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var isBootstrapping = true
    @Published var isLoggedIn = false
    @Published var me: MeResponse?

    let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
        self.isLoggedIn = deps.tokenStore.getToken() != nil
    }

    func bootstrap() async {
        guard deps.tokenStore.getToken() != nil else {
            isLoggedIn = false
            me = nil
            isBootstrapping = false
            return
        }

        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            me = try await deps.auth.me()
            isLoggedIn = true
        } catch {
            try? deps.tokenStore.clearToken()
            me = nil
            isLoggedIn = false
        }
    }

    func logout() {
        try? deps.tokenStore.clearToken()
        me = nil
        isLoggedIn = false
    }
}
