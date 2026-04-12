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
    case admin = "ADMIN"

    static var allCases: [UserRole] {
        [.parent, .provider]
    }

    var titleTR: String {
        switch self {
        case .parent: return "Aile"
        case .provider: return "Bakıcı"
        case .admin: return "Admin"
        }
    }
}

struct RequestOTPReq: Codable { let phone: String }
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
