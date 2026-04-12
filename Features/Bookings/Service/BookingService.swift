import Foundation

final class BookingService {
    private struct Empty: Encodable {}
    private struct CareRequestStore: Codable {
        var items: [CareRequestItem]
    }

    private enum CareRequestStorageKeys {
        static let store = "careRequestStoreV1"
    }

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
        let providerIndex = (try? await fetchProviderIndex()) ?? [:]
        let response: BookingsResponse = try await api.request(
            "v1/bookings/my",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
        return response.items.map { Self.toBookingItem($0, providerIndex: providerIndex) }
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

    func listParentCareRequests(parentUserID: String) async throws -> [CareRequestItem] {
        do {
            let response: CareRequestsResponse = try await api.request(
                "v1/care-requests/my",
                method: "GET",
                body: Optional<Empty>.none,
                needsAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            return response.items.sorted { $0.startAt < $1.startAt }
        } catch let error as APIError {
            switch error {
            case .http(let code, _) where code == 404 || code == 405:
                return loadCareRequests()
                    .filter { $0.parentUserID == parentUserID }
                    .sorted { $0.startAt < $1.startAt }
            case .decoding:
                return loadCareRequests()
                    .filter { $0.parentUserID == parentUserID }
                    .sorted { $0.startAt < $1.startAt }
            default:
                throw error
            }
        }
    }

    func listProviderCareRequests(providerUserID: String) async throws -> [CareRequestItem] {
        do {
            let response: CareRequestsResponse = try await api.request(
                "v1/care-requests/my",
                method: "GET",
                body: Optional<Empty>.none,
                needsAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            return response.items.sorted { $0.startAt < $1.startAt }
        } catch let error as APIError {
            switch error {
            case .http(let code, _) where code == 404 || code == 405:
                return loadCareRequests()
                    .filter { request in
                        request.isOpen
                            || request.assignedProviderUserID == providerUserID
                            || request.candidates.contains(where: { $0.providerUserID == providerUserID })
                    }
                    .sorted { $0.startAt < $1.startAt }
            case .decoding:
                return loadCareRequests()
                    .filter { request in
                        request.isOpen
                            || request.assignedProviderUserID == providerUserID
                            || request.candidates.contains(where: { $0.providerUserID == providerUserID })
                    }
                    .sorted { $0.startAt < $1.startAt }
            default:
                throw error
            }
        }
    }

    func createCareRequest(
        input: CreateCareRequestInput,
        parent: User,
        parentDisplayName: String,
        parentPhone: String?,
        locationName: String
    ) async throws -> CareRequestItem {
        guard input.endAt > input.startAt else {
            throw Self.localError(statusCode: 400, message: "Bitiş saati başlangıçtan sonra olmalı.")
        }

        let iso = ISO8601DateFormatter()

        struct CareRequestCreatePayload: Encodable {
            let service: String
            let note: String
            let startAt: String
            let endAt: String
            let locationName: String

            enum CodingKeys: String, CodingKey {
                case service
                case note
                case startAt = "start_at"
                case endAt = "end_at"
                case locationName = "location_name"
            }
        }

        do {
            let response: CareRequestMutationResponse = try await api.request(
                "v1/care-requests",
                method: "POST",
                body: CareRequestCreatePayload(
                    service: input.service,
                    note: input.note.trimmingCharacters(in: .whitespacesAndNewlines),
                    startAt: iso.string(from: input.startAt),
                    endAt: iso.string(from: input.endAt),
                    locationName: locationName
                ),
                needsAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            return response.request
        } catch let error as APIError {
            switch error {
            case .http(let code, _) where code == 404 || code == 405:
                var requests = loadCareRequests()
                let item = CareRequestItem(
                    id: UUID().uuidString,
                    parentUserID: parent.id,
                    parentDisplayName: parentDisplayName,
                    parentPhone: parentPhone,
                    service: input.service,
                    note: input.note.trimmingCharacters(in: .whitespacesAndNewlines),
                    startAt: iso.string(from: input.startAt),
                    endAt: iso.string(from: input.endAt),
                    locationName: locationName,
                    createdAt: iso.string(from: Date()),
                    status: "OPEN",
                    candidates: [],
                    assignedProviderUserID: nil,
                    assignedProviderDisplayName: nil
                )
                requests.append(item)
                saveCareRequests(requests)
                return item
            default:
                throw error
            }
        }
    }

    func applyToCareRequest(
        requestID: String,
        provider: User,
        providerDisplayName: String
    ) async throws -> CareRequestItem {
        do {
            let response: CareRequestMutationResponse = try await api.request(
                "v1/care-requests/\(requestID)/apply",
                method: "POST",
                body: Optional<Empty>.none,
                needsAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            return response.request
        } catch let error as APIError {
            switch error {
            case .http(let code, _) where code == 404 || code == 405:
                var requests = loadCareRequests()
                guard let index = requests.firstIndex(where: { $0.id == requestID }) else {
                    throw Self.localError(statusCode: 404, message: "Talep bulunamadı.")
                }

                var request = requests[index]
                guard request.isOpen else {
                    throw Self.localError(statusCode: 400, message: "Bu talep artık aday kabul etmiyor.")
                }

                if request.candidates.contains(where: { $0.providerUserID == provider.id }) {
                    throw Self.localError(statusCode: 400, message: "Bu talebe zaten aday oldun.")
                }

                let candidate = CareRequestCandidate(
                    providerUserID: provider.id,
                    providerDisplayName: providerDisplayName,
                    providerPhone: provider.phone,
                    appliedAt: ISO8601DateFormatter().string(from: Date())
                )
                request.candidates.append(candidate)
                requests[index] = request
                saveCareRequests(requests)
                return request
            default:
                throw error
            }
        }
    }

    func approveCareRequestCandidate(
        requestID: String,
        candidateProviderUserID: String,
        parentUserID: String
    ) async throws -> CareRequestItem {
        do {
            let response: CareRequestMutationResponse = try await api.request(
                "v1/care-requests/\(requestID)/candidates/\(candidateProviderUserID)/approve",
                method: "POST",
                body: Optional<Empty>.none,
                needsAuth: true,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            return response.request
        } catch let error as APIError {
            switch error {
            case .http(let code, _) where code == 404 || code == 405:
                var requests = loadCareRequests()
                guard let index = requests.firstIndex(where: { $0.id == requestID }) else {
                    throw Self.localError(statusCode: 404, message: "Talep bulunamadı.")
                }

                var request = requests[index]
                guard request.parentUserID == parentUserID else {
                    throw Self.localError(statusCode: 403, message: "Bu talebi onaylama yetkin yok.")
                }

                guard let candidate = request.candidates.first(where: { $0.providerUserID == candidateProviderUserID }) else {
                    throw Self.localError(statusCode: 404, message: "Seçilen aday bulunamadı.")
                }

                request.status = "MATCHED"
                request.assignedProviderUserID = candidate.providerUserID
                request.assignedProviderDisplayName = candidate.providerDisplayName
                requests[index] = request
                saveCareRequests(requests)
                return request
            default:
                throw error
            }
        }
    }

    private func loadCareRequests() -> [CareRequestItem] {
        guard let data = UserDefaults.standard.data(forKey: CareRequestStorageKeys.store) else {
            return []
        }

        do {
            return try JSONDecoder().decode(CareRequestStore.self, from: data).items
        } catch {
            return []
        }
    }

    private func saveCareRequests(_ items: [CareRequestItem]) {
        let store = CareRequestStore(items: items)
        if let data = try? JSONEncoder().encode(store) {
            UserDefaults.standard.set(data, forKey: CareRequestStorageKeys.store)
        }
    }

    private static func localError(statusCode: Int, message: String) -> APIError {
        let payload = #"{"message":"\#(message)"}"#.data(using: .utf8)
        return .http(statusCode, payload)
    }

    private func fetchProviderIndex() async throws -> [String: BrowseProvider] {
        let response: ProvidersResponse = try await api.request(
            "v1/providers",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: false,
            cachePolicy: .reloadIgnoringLocalCacheData
        )

        return Dictionary(uniqueKeysWithValues: response.providers.map { ($0.id, $0) })
    }

    private static func toBookingItem(_ record: BookingRecord) -> BookingItem {
        toBookingItem(record, providerIndex: [:])
    }

    private static func toBookingItem(_ record: BookingRecord, providerIndex: [String: BrowseProvider]) -> BookingItem {
        let enrichedProvider = providerIndex[record.providerUserID]
        let durationHours = bookingDurationHours(startAt: record.startAt, endAt: record.endAt)
        let resolvedHourlyRate = record.providerHourlyRate ?? enrichedProvider?.hourlyRate
        let resolvedTotalPrice = record.totalPrice
            ?? resolvedHourlyRate.map { max($0 * durationHours, $0) }
            ?? 0

        return BookingItem(
            id: record.id,
            service: record.service,
            status: record.status,
            startTime: record.startAt,
            endTime: record.endAt,
            totalPrice: resolvedTotalPrice,
            address: record.address ?? enrichedProvider?.locationName,
            paymentStatus: record.paymentStatus,
            provider: BookingProvider(
                id: record.providerUserID,
                displayName: record.providerDisplayName ?? enrichedProvider?.displayName ?? "Bakıcı",
                hourlyRate: resolvedHourlyRate
            ),
            parentUserID: record.parentUserID,
            familyDisplayName: record.familyDisplayName,
            familyAbout: record.familyAbout,
            familyLocationName: record.familyLocationName,
            familyLocationLatitude: record.familyLocationLatitude,
            familyLocationLongitude: record.familyLocationLongitude
        )
    }

    private static func bookingDurationHours(startAt: String, endAt: String) -> Int {
        guard
            let start = parseISODate(startAt),
            let end = parseISODate(endAt),
            end > start
        else {
            return 1
        }

        let rawHours = end.timeIntervalSince(start) / 3600
        return max(Int(rawHours.rounded(.up)), 1)
    }

    private static func parseISODate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
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
