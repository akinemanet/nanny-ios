//
//  BookingModels.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

struct BookingRequest: Codable {
    let providerId: String
    let date: String
    let time: String
}

struct BookingResponse: Codable {
    let id: String
    let status: String
}
