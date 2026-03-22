//
//  AuthService.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

final class AuthService {
    private let api: APIClient
    private let tokenStore: TokenStore

    init(api: APIClient, tokenStore: TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func requestOTP(phone: String) async throws -> RequestOTPRes {
        try await api.request("v1/auth/request-otp", method: "POST", body: RequestOTPReq(phone: phone), needsAuth: false)
    }

    @discardableResult
    func verifyOTP(phone: String, code: String, role: UserRole) async throws -> VerifyOTPRes {
        let res: VerifyOTPRes = try await api.request(
            "v1/auth/verify-otp",
            method: "POST",
            body: VerifyOTPReq(phone: phone, code: code, role: role),
            needsAuth: false
        )
        try tokenStore.setToken(res.accessToken)
        return res
    }

    func me() async throws -> MeResponse {
        struct Empty: Encodable {}
        return try await api.request("v1/me", method: "GET", body: Optional<Empty>.none, needsAuth: true)
    }
}
