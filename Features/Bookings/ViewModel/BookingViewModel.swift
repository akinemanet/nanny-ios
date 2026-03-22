//
//  BookingViewModel.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation
import Combine

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var success = false
    @Published var error: String?

    private let service = BookingService(
        api: APIClient(tokenStore: KeychainTokenStore())
    )

    func book(providerId: String, date: Date, time: String) async {
        isLoading = true

        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            let dateString = formatter.string(from: date)

            _ = try await service.createBooking(
                providerId: providerId,
                date: dateString,
                time: time
            )

            success = true
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
