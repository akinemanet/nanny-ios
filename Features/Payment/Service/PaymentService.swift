import Foundation

struct CheckoutReq: Codable {
    let bookingId: String
}

struct CheckoutRes: Codable {
    let checkoutUrl: String?
    let checkoutURL: String?

    var resolvedURL: String? {
        checkoutUrl ?? checkoutURL
    }
}

final class PaymentService {
    let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func checkout(bookingID: String) async throws -> String {
        let res: CheckoutRes = try await api.request(
            "v1/payments/checkout-init",
            method: "POST",
            body: CheckoutReq(bookingId: bookingID),
            needsAuth: true
        )

        if let url = res.resolvedURL, !url.isEmpty {
            return url
        }

        throw APIError.invalidURL
    }

    func listPaymentMethods() async throws -> PaymentMethodsResponse {
        struct Empty: Encodable {}
        return try await api.request(
            "v1/payment-methods",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
    }

    func createPaymentMethod(_ req: CreatePaymentMethodReq) async throws -> PaymentMethodItem {
        try await api.request(
            "v1/payment-methods",
            method: "POST",
            body: req,
            needsAuth: true
        )
    }
}
