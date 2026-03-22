//
//  APIError.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case http(Int, Data?)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .http(let code, let data):
            if let data, let string = String(data: data, encoding: .utf8), !string.isEmpty {
                return "HTTP \(code): \(string)"
            }
            return "HTTP Hatası: \(code)"
        case .decoding(let error):
            return "Decode Hatası: \(error.localizedDescription)"
        case .transport(let error):
            return "Network Hatası: \(error.localizedDescription)"
        }
    }
}
