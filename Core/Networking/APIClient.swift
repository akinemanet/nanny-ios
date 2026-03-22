//
//  APIClient.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

final class APIClient {
    private enum APIConfig {
        static let baseURL = URL(string: "https://api.clickajans.net")!
    }

    private let tokenStore: TokenStore
    private let session: URLSession

    init(tokenStore: TokenStore, session: URLSession = .shared) {
        self.tokenStore = tokenStore
        self.session = session
    }

    func request<T: Decodable, B: Encodable>(
        _ path: String,
        method: String = "GET",
        body: B? = nil,
        needsAuth: Bool = false
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if needsAuth, let token = tokenStore.getToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidURL }
            guard (200...299).contains(http.statusCode) else { throw APIError.http(http.statusCode, data) }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.transport(error)
        }
    }
}
