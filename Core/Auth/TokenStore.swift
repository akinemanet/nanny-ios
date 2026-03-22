//
//  TokenStore.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation
import Security

protocol TokenStore {
    func getToken() -> String?
    func setToken(_ token: String) throws
    func clearToken() throws
}

enum KeychainTokenStoreError: Error {
    case unexpectedStatus(OSStatus)
}

final class KeychainTokenStore: TokenStore {
    private let service = "net.clickajans.nanny"
    private let account = "accessToken"

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func setToken(_ token: String) throws {
        let data = Data(token.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status: OSStatus
        if getToken() == nil {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
        } else {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }

        guard status == errSecSuccess else { throw KeychainTokenStoreError.unexpectedStatus(status) }
    }

    func clearToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }
}
