import Foundation

final class BookingService {
    private struct Empty: Encodable {}

    let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func createBooking(req: CreateBookingReq) async throws -> CreateBookingRes {
        try await api.request(
            "v1/bookings",
            method: "POST",
            body: req,
            needsAuth: true
        )
    }

    func listBookings() async throws -> [BookingItem] {
        let response: BookingsResponse = try await api.request(
            "v1/bookings/my",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
        return response.items.map(Self.toBookingItem)
    }

    func providerTodayBookings(
        fallback bookings: [BookingItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> [BookingItem] {
        var lastError: Error?

        for candidate in ProviderDashboardBookingPlan.todaysBookingsCandidates() {
            do {
                let response: BookingsResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.items.map(Self.toBookingItem)
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        _ = lastError
        return bookings.filter { booking in
            guard let date = ISO8601DateFormatter().date(from: booking.startTime) else { return false }
            return calendar.isDate(date, inSameDayAs: now)
        }
        .sorted { $0.startTime < $1.startTime }
    }

    func providerPendingRequests(fallback bookings: [BookingItem]) async throws -> [BookingItem] {
        var lastError: Error?

        for candidate in ProviderDashboardBookingPlan.pendingRequestsCandidates() {
            do {
                let response: BookingsResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.items.map(Self.toBookingItem)
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        _ = lastError
        return bookings.filter {
            let status = $0.status.uppercased()
            return status == "REQUESTED" || status == "PENDING"
        }
        .sorted { $0.startTime < $1.startTime }
    }

    func providerEarningsSummary(fallback bookings: [BookingItem]) async throws -> ProviderEarningsSummary {
        var lastError: Error?

        for candidate in ProviderEarningsSummaryPlan.candidates() {
            do {
                let response: ProviderEarningsSummaryResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.summary
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        _ = lastError
        return ProviderEarningsSummary.make(bookings: bookings)
    }

    func booking(id bookingID: String) async throws -> BookingItem? {
        try await listBookings().first(where: { $0.id == bookingID })
    }

    func cancelBooking(bookingID: String) async throws -> BookingItem? {
        var lastError: Error?

        for candidate in BookingMutationPlan.cancelCandidates(bookingID: bookingID) {
            do {
                if candidate.sendsReadBody {
                    let response: CancelBookingRes = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: CancelBookingStatusReq(status: "CANCELED"),
                        needsAuth: true
                    )
                    return response.booking.map(Self.toBookingItem)
                }

                let response: CancelBookingRes = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.booking.map(Self.toBookingItem)
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        throw lastError ?? APIError.invalidURL
    }

    func rescheduleBooking(
        bookingID: String,
        startAt: String,
        endAt: String
    ) async throws -> BookingItem? {
        var lastError: Error?
        let body = RescheduleBookingReq(startAt: startAt, endAt: endAt)

        for candidate in BookingMutationPlan.rescheduleCandidates(bookingID: bookingID) {
            do {
                let response: RescheduleBookingRes = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: body,
                    needsAuth: true
                )
                return response.booking.map(Self.toBookingItem)
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        throw lastError ?? APIError.invalidURL
    }

    func providerUpdateBookingStatus(
        bookingID: String,
        status: String
    ) async throws -> BookingItem? {
        var lastError: Error?
        let body = ProviderBookingDecisionReq(status: status)

        for candidate in BookingMutationPlan.providerDecisionCandidates(bookingID: bookingID) {
            do {
                let response: ProviderBookingDecisionRes = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: body,
                    needsAuth: true
                )
                return response.booking.map(Self.toBookingItem)
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        throw lastError ?? APIError.invalidURL
    }

    private static func toBookingItem(_ record: BookingRecord) -> BookingItem {
        BookingItem(
            id: record.id,
            service: record.service,
            status: record.status,
            startTime: record.startAt,
            endTime: record.endAt,
            totalPrice: record.totalPrice ?? 0,
            address: record.address,
            paymentStatus: record.paymentStatus,
            provider: BookingProvider(
                id: record.providerUserID,
                displayName: record.providerDisplayName ?? "Provider",
                hourlyRate: record.providerHourlyRate
            ),
            parentUserID: record.parentUserID,
            familyDisplayName: record.familyDisplayName,
            familyAbout: record.familyAbout,
            familyLocationName: record.familyLocationName,
            familyLocationLatitude: record.familyLocationLatitude,
            familyLocationLongitude: record.familyLocationLongitude
        )
    }
}

private struct CancelBookingStatusReq: Encodable {
    let status: String
}

private struct ProviderEarningsSummaryResponse: Decodable {
    let summary: ProviderEarningsSummary

    enum CodingKeys: String, CodingKey {
        case completedTodayCount
        case activeTodayCount
        case todayEarnings
        case pendingPayout
        case summary
        case earnings
    }

    init(from decoder: Decoder) throws {
        if let nested = try? NestedSummary(from: decoder), let value = nested.summary {
            summary = value
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = ProviderEarningsSummary(
            completedTodayCount: try container.decodeIfPresent(Int.self, forKey: .completedTodayCount) ?? 0,
            activeTodayCount: try container.decodeIfPresent(Int.self, forKey: .activeTodayCount) ?? 0,
            todayEarnings: try container.decodeIfPresent(Int.self, forKey: .todayEarnings) ?? 0,
            pendingPayout: try container.decodeIfPresent(Int.self, forKey: .pendingPayout) ?? 0
        )
    }

    private struct NestedSummary: Decodable {
        let summary: ProviderEarningsSummary?

        enum CodingKeys: String, CodingKey {
            case summary
            case earnings
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            summary =
                try container.decodeIfPresent(ProviderEarningsSummary.self, forKey: .summary)
                ?? container.decodeIfPresent(ProviderEarningsSummary.self, forKey: .earnings)
        }
    }
}
