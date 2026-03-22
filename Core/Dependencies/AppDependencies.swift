//
//  AppDependencies.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation

struct AppDependencies {
    let tokenStore: TokenStore
    let api: APIClient
    let auth: AuthService

    static func live() -> AppDependencies {
        let tokenStore = KeychainTokenStore()
        let api = APIClient(tokenStore: tokenStore)
        let auth = AuthService(api: api, tokenStore: tokenStore)
        return .init(tokenStore: tokenStore, api: api, auth: auth)
    }
}
