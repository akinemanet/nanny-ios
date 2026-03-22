//
//  ProviderService.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation

final class ProviderService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func getPayoutAccount() async throws -> GetPayoutAccountResponse {
        try await api.request("v1/providers/payout-account", needsAuth: true)
    }

    func upsertPayoutAccount(_ req: UpsertPayoutAccountRequest) async throws -> UpsertPayoutAccountResponse {
        try await api.request("v1/providers/payout-account", method: "POST", body: req, needsAuth: true)
    }
}
