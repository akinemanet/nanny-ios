import Foundation

struct CreateBookingReq: Codable {

    let nanny_id: String
    let start_time: String
    let end_time: String
}

final class BookingService {

    let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func createBooking(req: CreateBookingReq) async throws {

        let _: EmptyResponse = try await api.request(
            "v1/bookings",
            method: "POST",
            body: req,
            needsAuth: true
        )
    }
}

struct EmptyResponse: Codable {}
