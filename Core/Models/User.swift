//
//  User.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

struct User: Decodable {
    let id: String
    let role: String
    let phone: String
    let email: String?
    let isActive: Bool
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case phone
        case email
        case isActive
        case displayName
        case fullName
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(String.self, forKey: .role)
        phone = try container.decode(String.self, forKey: .phone)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        displayName =
            try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? container.decodeIfPresent(String.self, forKey: .fullName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
    }

    init(
        id: String,
        role: String,
        phone: String,
        email: String?,
        isActive: Bool,
        displayName: String?
    ) {
        self.id = id
        self.role = role
        self.phone = phone
        self.email = email
        self.isActive = isActive
        self.displayName = displayName
    }
}
