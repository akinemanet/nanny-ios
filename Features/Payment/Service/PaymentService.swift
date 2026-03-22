import Foundation

struct CheckoutReq: Codable {

    let booking_id: String
}

struct CheckoutRes: Codable {

    let checkout_url: String
}

final class PaymentService {

    let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func checkout(bookingID: String) async throws -> String {

        let res: CheckoutRes = try await api.request(
            "v1/payments/checkout",
            method: "POST",
            body: CheckoutReq(booking_id: bookingID),
            needsAuth: true
        )

        return res.checkout_url
    }
}
