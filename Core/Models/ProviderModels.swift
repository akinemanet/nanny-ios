//
//  ProviderModels.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

struct ProviderAccount: Codable {
    let id: String?
    let providerUserId: String?
    let subMerchantExternalId: String?
    let subMerchantKey: String?
    let subMerchantType: String?
    let currency: String
    let status: String
    let lastError: String?
    let address: String
    let contactName: String
    let contactSurname: String
    let email: String
    let gsmNumber: String
    let name: String
    let iban: String
    let identityNumber: String
}

struct UpsertPayoutAccountRequest: Codable {
    let address: String
    let contactName: String
    let contactSurname: String
    let email: String
    let gsmNumber: String
    let name: String
    let iban: String
    let identityNumber: String
}

struct PayoutAccountResponse: Codable {
    let account: ProviderAccount?
}
