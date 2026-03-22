//
//  User.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

struct User: Codable {
    let id: String
    let role: String
    let phone: String
    let email: String?
    let isActive: Bool
}
