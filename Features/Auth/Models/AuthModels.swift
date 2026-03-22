//
//  AuthModels.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case parent = "PARENT"
    case provider = "PROVIDER"

    var titleTR: String {
        switch self {
        case .parent:
            return "Aile (Parent)"
        case .provider:
            return "Bakıcı (Provider)"
        }
    }
}

struct RequestOTPReq: Codable {
    let phone: String
}

struct RequestOTPRes: Codable {
    let sent: Bool
    let ttlSeconds: Int
    let devCode: String?
}

struct VerifyOTPReq: Codable {
    let phone: String
    let code: String
    let role: UserRole
}

struct VerifyOTPRes: Codable {
    let accessToken: String
}

struct MeResponse: Codable {
    struct Jwt: Codable {
        let sub: String
        let role: String
        let phone: String
        let iat: Int
        let exp: Int
    }

    let user: User
    let jwt: Jwt
}
