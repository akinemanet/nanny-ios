//
//  AppLogic.swift
//  APIEnvironment
//
//  Created by Codex on 21.03.2026.
//

import Foundation

extension Notification.Name {
    static let appDidOpenRemoteNotification = Notification.Name("appDidOpenRemoteNotification")
    static let didReceivePushRegistrationToken = Notification.Name("didReceivePushRegistrationToken")
    static let didReceiveAPNSToken = Notification.Name("didReceiveAPNSToken")
}

enum DashboardNotificationDestination: Equatable {
    case conversation(ConversationItem)
    case bookingDetail(String)
    case bookings
    case chatList
    case careRequests
    case notifications
}

struct MutationRequestCandidate: Equatable {
    let path: String
    let method: String
    let sendsReadBody: Bool
}

enum PreferenceSyncPlan {
    static func fetchCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/me/preferences", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me/settings", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/users/preferences", method: "GET", sendsReadBody: false)
        ]
    }

    static func saveCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/me/preferences", method: "PUT", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/me/preferences", method: "PATCH", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/me/settings", method: "PATCH", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/users/preferences", method: "POST", sendsReadBody: true)
        ]
    }
}

enum AccountSettingsSummaryPlan {
    static func fetchCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/me/settings-summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me/profile-summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me/preferences", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me/settings", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/users/preferences", method: "GET", sendsReadBody: false)
        ]
    }
}

enum AccountProfileSummaryPlan {
    static func fetchCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/me/profile-summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me/settings-summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/users/me", method: "GET", sendsReadBody: false)
        ]
    }
}

enum AccountProfileMutationPlan {
    static func saveCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/me/profile-summary", method: "PATCH", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/me/profile", method: "PATCH", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/me", method: "PUT", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/users/me", method: "POST", sendsReadBody: true)
        ]
    }
}

enum ProviderAvailabilitySyncPlan {
    static func fetchCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/availability", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/provider/availability", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/me/availability", method: "GET", sendsReadBody: false)
        ]
    }

    static func saveCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/availability", method: "PUT", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/providers/availability", method: "PATCH", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/provider/availability", method: "POST", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/me/availability", method: "PATCH", sendsReadBody: true)
        ]
    }
}

enum ProviderDashboardBookingPlan {
    static func todaysBookingsCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/bookings/today", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/providers/bookings?scope=today", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/bookings/provider?scope=today", method: "GET", sendsReadBody: false)
        ]
    }

    static func pendingRequestsCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/bookings/requests", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/providers/bookings?scope=pending_requests", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/bookings/provider?status=requested,pending", method: "GET", sendsReadBody: false)
        ]
    }
}

enum ProviderDashboardSummaryPlan {
    static func unreadMessageCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/messages/summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/chats/summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/chats/unread-count", method: "GET", sendsReadBody: false)
        ]
    }

    static func unreadNotificationCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/notifications/summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/notifications/summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/notifications/unread-count", method: "GET", sendsReadBody: false)
        ]
    }
}

enum ProviderEarningsSummaryPlan {
    static func candidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/earnings/summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/providers/payouts/summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/providers/dashboard/summary", method: "GET", sendsReadBody: false)
        ]
    }
}

enum ProviderOnboardingSummaryPlan {
    static func candidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/onboarding-summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/providers/profile-summary", method: "GET", sendsReadBody: false),
            MutationRequestCandidate(path: "v1/providers/payout-account", method: "GET", sendsReadBody: false)
        ]
    }
}

enum ProviderOnboardingMutationPlan {
    static func saveProfileCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(path: "v1/providers/onboarding-summary", method: "PUT", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/providers/profile-summary", method: "PATCH", sendsReadBody: true),
            MutationRequestCandidate(path: "v1/providers/profile", method: "POST", sendsReadBody: true)
        ]
    }
}

struct ProviderRequestContextPresentation: Equatable {
    let priority: Int
    let badgeTitle: String?
    let badgeSystemImage: String?
    let distanceBucketTitle: String?

    static func make(
        familyDisplayName: String?,
        familyAbout: String?,
        familyLocationName: String?,
        providerLatitude: Double? = nil,
        providerLongitude: Double? = nil,
        familyLatitude: Double? = nil,
        familyLongitude: Double? = nil
    ) -> ProviderRequestContextPresentation {
        let trimmedAbout = familyAbout?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedLocation = familyLocationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedName = familyDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !trimmedAbout.isEmpty {
            return ProviderRequestContextPresentation(
                priority: 0,
                badgeTitle: "Aile Notu Var",
                badgeSystemImage: "text.bubble.fill",
                distanceBucketTitle: nil
            )
        }

        if let providerLatitude,
           let providerLongitude,
           let distance = DistanceMath.distanceInKilometers(
                from: providerLatitude,
                originLongitude: providerLongitude,
                to: familyLatitude,
                destinationLongitude: familyLongitude
           ) {
            return ProviderRequestContextPresentation(
                priority: 1,
                badgeTitle: String(format: "%.1f km", distance),
                badgeSystemImage: "location.fill",
                distanceBucketTitle: ProviderNearbyFamilyLogic.distanceBucketTitle(for: distance)
            )
        }

        if !trimmedLocation.isEmpty {
            return ProviderRequestContextPresentation(
                priority: 1,
                badgeTitle: trimmedName.isEmpty ? "Konum Hazir" : trimmedLocation,
                badgeSystemImage: "mappin.and.ellipse",
                distanceBucketTitle: nil
            )
        }

        if !trimmedName.isEmpty {
            return ProviderRequestContextPresentation(
                priority: 2,
                badgeTitle: "Aile Profili",
                badgeSystemImage: "person.text.rectangle",
                distanceBucketTitle: nil
            )
        }

        return ProviderRequestContextPresentation(
            priority: 3,
            badgeTitle: nil,
            badgeSystemImage: nil,
            distanceBucketTitle: nil
        )
    }
}

enum ProviderNearbyFamilyLogic {
    static func distanceBucketTitle(
        providerLatitude: Double,
        providerLongitude: Double,
        familyLatitude: Double?,
        familyLongitude: Double?
    ) -> String? {
        guard let distance = DistanceMath.distanceInKilometers(
            from: providerLatitude,
            originLongitude: providerLongitude,
            to: familyLatitude,
            destinationLongitude: familyLongitude
        ) else {
            return nil
        }

        return distanceBucketTitle(for: distance)
    }

    static func isNearby(
        providerLatitude: Double,
        providerLongitude: Double,
        familyLatitude: Double?,
        familyLongitude: Double?,
        fallbackLocationName: String?,
        maximumDistanceInKilometers: Double = 8
    ) -> Bool {
        if let distance = DistanceMath.distanceInKilometers(
            from: providerLatitude,
            originLongitude: providerLongitude,
            to: familyLatitude,
            destinationLongitude: familyLongitude
        ) {
            return distance <= maximumDistanceInKilometers
        }

        let fallback = fallbackLocationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !fallback.isEmpty
    }

    static func distanceBucketTitle(for distance: Double) -> String {
        switch distance {
        case ..<3:
            return "0-3 km"
        case ..<8:
            return "3-8 km"
        default:
            return "Uzak"
        }
    }
}

struct BookingStatusNotificationContent: Equatable {
    let title: String
    let body: String
    let type: String

    static func make(
        providerName: String,
        service: String,
        status: String,
        startAt: String? = nil,
        familyDisplayName: String? = nil,
        proximityText: String? = nil
    ) -> BookingStatusNotificationContent {
        let localizedService = service.replacingOccurrences(of: "_", with: " ").lowercased()
        let context = bookingContextText(
            service: localizedService,
            startAt: startAt,
            familyDisplayName: familyDisplayName,
            proximityText: proximityText
        )

        switch status.uppercased() {
        case "CONFIRMED":
            return BookingStatusNotificationContent(
                title: "Bakıcı Onay Verdi",
                body: "\(providerName), \(context) talebini onayladı.",
                type: "booking_confirmed"
            )
        case "CANCELED":
            return BookingStatusNotificationContent(
                title: "Bakıcı Reddetti",
                body: "\(providerName), \(context) talebini reddetti.",
                type: "booking_rejected"
            )
        default:
            return BookingStatusNotificationContent(
                title: "Hizmet Tamamlandı",
                body: "\(providerName), \(context) hizmetini tamamladığını bildirdi.",
                type: "booking_completed"
            )
        }
    }

    private static func bookingContextText(
        service: String,
        startAt: String?,
        familyDisplayName: String?,
        proximityText: String?
    ) -> String {
        let trimmedFamilyName = familyDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedProximity = proximityText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let scheduleText = compactScheduleText(from: startAt)

        var parts: [String] = []
        if !trimmedFamilyName.isEmpty {
            parts.append("\(trimmedFamilyName) icin")
        }
        if let scheduleText {
            parts.append(scheduleText)
        }
        parts.append(service)
        if !trimmedProximity.isEmpty {
            parts.append("(\(trimmedProximity))")
        }
        return parts.joined(separator: " ")
    }

    private static func compactScheduleText(from startAt: String?) -> String? {
        guard let startAt, !startAt.isEmpty else { return nil }
        let sections = startAt.split(separator: "T", maxSplits: 1).map(String.init)
        guard sections.count == 2 else { return nil }

        let dateParts = sections[0].split(separator: "-")
        guard dateParts.count == 3 else { return nil }

        let timePrefix = sections[1].prefix(5)
        guard timePrefix.count == 5 else { return nil }

        return "\(dateParts[2]).\(dateParts[1]) \(timePrefix)"
    }
}

struct FamilyNotificationPresentation: Equatable {
    let tintKey: String
    let icon: String
    let badgeText: String
    let highlightText: String?

    static func make(type: String?) -> FamilyNotificationPresentation {
        switch (type ?? "").lowercased() {
        case "booking_confirmed":
            return FamilyNotificationPresentation(
                tintKey: "green",
                icon: "checkmark.seal.fill",
                badgeText: "Hızlı Dönüş",
                highlightText: "Bakıcın talebine hızlı yanıt verdi."
            )
        case "booking_rejected":
            return FamilyNotificationPresentation(
                tintKey: "red",
                icon: "xmark.seal.fill",
                badgeText: "Red",
                highlightText: nil
            )
        case "booking_completed":
            return FamilyNotificationPresentation(
                tintKey: "blue",
                icon: "party.popper.fill",
                badgeText: "Tamam",
                highlightText: "Hizmet basariyla tamamlandi."
            )
        default:
            return FamilyNotificationPresentation(
                tintKey: "accent",
                icon: "bell.badge.fill",
                badgeText: "Yeni",
                highlightText: nil
            )
        }
    }

    static func proximityBadgeText(from body: String) -> String? {
        guard let openIndex = body.firstIndex(of: "("),
              let closeIndex = body[openIndex...].firstIndex(of: ")"),
              openIndex < closeIndex else {
            return nil
        }

        let rawValue = body[body.index(after: openIndex)..<closeIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rawValue.isEmpty else { return nil }
        return rawValue
    }
}

struct ForegroundNotificationPresentation: Equatable {
    let options: [String]

    static func make(
        userInfo: [AnyHashable: Any],
        pushAlertsEnabled: Bool,
        bookingConfirmedEnabled: Bool,
        bookingRejectedEnabled: Bool,
        bookingCompletedEnabled: Bool,
        quietHoursEnabled: Bool,
        quietHoursStart: String,
        quietHoursEnd: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ForegroundNotificationPresentation {
        guard pushAlertsEnabled else {
            return ForegroundNotificationPresentation(options: [])
        }

        let baseOptions = QuietHoursLogic.notificationPresentationOptions(
            enabled: quietHoursEnabled,
            start: quietHoursStart,
            end: quietHoursEnd,
            now: now,
            calendar: calendar
        )

        let type =
            userInfo["type"] as? String
            ?? (userInfo["data"] as? [String: Any])?["type"] as? String
            ?? ((userInfo["aps"] as? [String: Any])?["type"] as? String)

        switch (type ?? "").lowercased() {
        case "booking_completed":
            guard bookingCompletedEnabled else {
                return ForegroundNotificationPresentation(options: [])
            }
            return ForegroundNotificationPresentation(options: ["badge"])
        case "booking_rejected":
            guard bookingRejectedEnabled else {
                return ForegroundNotificationPresentation(options: [])
            }
            return ForegroundNotificationPresentation(
                options: quietHoursEnabled && baseOptions == ["badge"]
                    ? ["badge"]
                    : ["banner", "sound", "badge"]
            )
        case "booking_confirmed":
            guard bookingConfirmedEnabled else {
                return ForegroundNotificationPresentation(options: [])
            }
            return ForegroundNotificationPresentation(
                options: baseOptions == ["badge"] ? ["badge"] : ["banner", "badge"]
            )
        default:
            return ForegroundNotificationPresentation(options: baseOptions)
        }
    }
}

enum ChatSocketParsedEvent: Equatable {
    case typing(chatID: String, isTyping: Bool)
    case message(chatID: String, text: String, createdAt: String)
}

enum CheckoutCompletion: Equatable {
    case success
    case cancelled
}

enum DashboardRouting {
    static func conversation(
        forProviderID providerID: String,
        participantName: String,
        conversations: [ConversationItem]
    ) -> ConversationItem? {
        if let byID = conversations.first(where: { $0.participantID == providerID }) {
            return byID
        }

        let normalizedTarget = normalizedText(participantName)

        return conversations.first {
            normalizedText($0.participantName) == normalizedTarget
        } ?? conversations.first {
            normalizedText($0.participantName).contains(normalizedTarget)
                || normalizedTarget.contains(normalizedText($0.participantName))
        }
    }

    static func conversation(
        matching notification: AppNotification,
        conversations: [ConversationItem]
    ) -> ConversationItem? {
        let haystack = normalizedText(notification.title + " " + notification.body)

        return conversations.first {
            haystack.contains(normalizedText($0.participantName))
        }
    }

    static func destination(
        for notification: AppNotification,
        conversations: [ConversationItem]
    ) -> DashboardNotificationDestination {
        if let conversation = conversation(matching: notification, conversations: conversations) {
            return .conversation(conversation)
        }

        if let bookingID = notification.bookingID, !bookingID.isEmpty {
            return .bookingDetail(bookingID)
        }

        if prefersCareRequestsDestination(notification) {
            return .careRequests
        }

        if prefersBookingsDestination(notification) {
            return .bookings
        }

        if prefersChatDestination(notification) {
            return .chatList
        }

        return .notifications
    }

    static func normalizedText(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func prefersBookingsDestination(_ notification: AppNotification) -> Bool {
        let text = normalizedText(notification.title + " " + notification.body)
        return text.contains("rezervasyon")
            || text.contains("onay")
            || text.contains("booking")
            || text.contains("takvim")
    }

    static func prefersCareRequestsDestination(_ notification: AppNotification) -> Bool {
        let text = normalizedText(notification.title + " " + notification.body + " " + (notification.type ?? ""))
        return text.contains("aday")
            || text.contains("basvuru")
            || text.contains("başvuru")
            || text.contains("hizli bakici talebi")
            || text.contains("hızlı bakıcı talebi")
            || text.contains("aile talebi")
            || text.contains("care request")
    }

    static func prefersChatDestination(_ notification: AppNotification) -> Bool {
        let text = normalizedText(notification.title + " " + notification.body)
        return text.contains("mesaj")
            || text.contains("sohbet")
            || text.contains("chat")
            || text.contains("arama")
    }
}

enum DistanceMath {
    static func distanceInKilometers(
        from originLatitude: Double,
        originLongitude: Double,
        to destinationLatitude: Double?,
        destinationLongitude: Double?
    ) -> Double? {
        guard let destinationLatitude, let destinationLongitude else { return nil }

        let earthRadiusInKilometers = 6371.0
        let latitudeDelta = degreesToRadians(destinationLatitude - originLatitude)
        let longitudeDelta = degreesToRadians(destinationLongitude - originLongitude)

        let startLatitude = degreesToRadians(originLatitude)
        let endLatitude = degreesToRadians(destinationLatitude)

        let haversine =
            sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)

        let centralAngle = 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
        return earthRadiusInKilometers * centralAngle
    }

    static func distanceText(
        from originLatitude: Double,
        originLongitude: Double,
        to destinationLatitude: Double?,
        destinationLongitude: Double?,
        fallback: String
    ) -> String {
        guard let distance = distanceInKilometers(
            from: originLatitude,
            originLongitude: originLongitude,
            to: destinationLatitude,
            destinationLongitude: destinationLongitude
        ) else {
            return fallback
        }

        return String(format: "%.1f km uzaklikta", distance)
    }

    private static func degreesToRadians(_ value: Double) -> Double {
        value * .pi / 180
    }
}

enum CurrencyFormatting {
    static func symbol(for currencyCode: String) -> String {
        switch currencyCode.uppercased() {
        case "USD":
            return "$"
        case "EUR":
            return "€"
        default:
            return "₺"
        }
    }

    static func formattedAmount(_ amount: Int, currencyCode: String) -> String {
        "\(symbol(for: currencyCode))\(amount)"
    }

    static func formattedHourlyRate(_ amount: Int, currencyCode: String) -> String {
        "\(formattedAmount(amount, currencyCode: currencyCode))/saat"
    }
}

enum QuietHoursLogic {
    static func isActive(
        enabled: Bool,
        start: String,
        end: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard enabled else { return false }
        guard
            let startComponents = timeComponents(from: start),
            let endComponents = timeComponents(from: end)
        else {
            return false
        }

        let nowParts = calendar.dateComponents([.hour, .minute], from: now)
        guard let nowMinutes = totalMinutes(hour: nowParts.hour, minute: nowParts.minute) else {
            return false
        }

        guard
            let startMinutes = totalMinutes(hour: startComponents.hour, minute: startComponents.minute),
            let endMinutes = totalMinutes(hour: endComponents.hour, minute: endComponents.minute)
        else {
            return false
        }

        if startMinutes == endMinutes {
            return true
        }

        if startMinutes < endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }

        return nowMinutes >= startMinutes || nowMinutes < endMinutes
    }

    static func notificationPresentationOptions(
        enabled: Bool,
        start: String,
        end: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [String] {
        if isActive(enabled: enabled, start: start, end: end, now: now, calendar: calendar) {
            return ["badge"]
        }

        return ["banner", "sound", "badge"]
    }

    private static func timeComponents(from value: String) -> (hour: Int, minute: Int)? {
        let parts = value.split(separator: ":")
        guard
            parts.count == 2,
            let hour = Int(parts[0]),
            let minute = Int(parts[1]),
            (0...23).contains(hour),
            (0...59).contains(minute)
        else {
            return nil
        }

        return (hour, minute)
    }

    private static func totalMinutes(hour: Int?, minute: Int?) -> Int? {
        guard let hour, let minute else { return nil }
        return hour * 60 + minute
    }
}

enum ProviderAvailabilityLogic {
    static func decodeWeeklyTemplates(_ rawValue: String) -> [Int: [String]] {
        guard let data = rawValue.data(using: .utf8) else { return [:] }

        if let decoded = try? JSONDecoder().decode([Int: [String]].self, from: data) {
            return decoded
        }

        guard let fallback = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }

        return fallback.reduce(into: [:]) { partial, item in
            guard let weekday = Int(item.key) else { return }
            partial[weekday] = item.value
        }
    }

    static func encodeWeeklyTemplates(_ templates: [Int: [String]]) -> String {
        guard
            let data = try? JSONEncoder().encode(templates),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return string
    }

    static func decodeSelections(_ rawValue: String) -> [String: [String]] {
        guard let data = rawValue.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }

    static func encodeSelections(_ selections: [String: [String]]) -> String {
        guard
            let data = try? JSONEncoder().encode(selections),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return string
    }

    static func sortedSlots(_ slots: [String]) -> [String] {
        slots.sorted()
    }

    static func totalSlotCount(in selections: [String: [String]]) -> Int {
        selections.values.reduce(0) { partial, slots in
            partial + Set(slots).count
        }
    }

    static func totalTemplateCount(in templates: [Int: [String]]) -> Int {
        templates.values.reduce(0) { partial, slots in
            partial + Set(slots).count
        }
    }

    static func nextAvailableDate(
        in selections: [String: [String]],
        from now: Date = Date()
    ) -> String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let today = formatter.string(from: now)

        return selections.keys
            .sorted()
            .first { key in
                key >= today && !(selections[key] ?? []).isEmpty
            }
    }

    static func weekday(for date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: date)
    }

    static func weekdayTitle(for weekday: Int, locale: Locale = Locale(identifier: "tr_TR")) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale

        let weekdaySymbols = calendar.weekdaySymbols
        guard weekday > 0, weekday <= weekdaySymbols.count else { return "Bu gün" }
        return weekdaySymbols[weekday - 1].capitalized(with: locale)
    }

    static func nextDate(
        for weekday: Int,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        guard (1...7).contains(weekday) else { return nil }

        let currentWeekday = calendar.component(.weekday, from: date)
        let delta = (weekday - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: delta, to: date)
    }

    static func selectionsApplyingWeeklyRule(
        currentSelections: [String: [String]],
        currentTemplates: [Int: [String]],
        selectedDate: Date,
        selectedSlots: [String],
        appliesWeeklyTemplate: Bool,
        horizonInWeeks: Int = 8,
        calendar: Calendar = .current
    ) -> (selections: [String: [String]], templates: [Int: [String]]) {
        var updatedSelections = currentSelections
        var updatedTemplates = currentTemplates

        let normalizedSlots = sortedSlots(selectedSlots)
        let selectedWeekday = weekday(for: selectedDate, calendar: calendar)

        if appliesWeeklyTemplate {
            updatedTemplates[selectedWeekday] = normalizedSlots

            guard horizonInWeeks > 0 else {
                return (updatedSelections, updatedTemplates)
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]

            for offset in 0..<horizonInWeeks {
                guard let candidateDate = calendar.date(byAdding: .weekOfYear, value: offset, to: selectedDate) else {
                    continue
                }
                let key = formatter.string(from: candidateDate)
                updatedSelections[key] = normalizedSlots
            }
        } else {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            updatedSelections[formatter.string(from: selectedDate)] = normalizedSlots
        }

        return (updatedSelections, updatedTemplates)
    }

    static func copyTemplate(
        from sourceWeekday: Int,
        to destinationWeekdays: [Int],
        using templates: [Int: [String]]
    ) -> [Int: [String]] {
        guard let sourceSlots = templates[sourceWeekday], !sourceSlots.isEmpty else {
            return templates
        }

        var updated = templates
        for weekday in destinationWeekdays where weekday != sourceWeekday {
            updated[weekday] = sortedSlots(sourceSlots)
        }
        return updated
    }
}

struct ProviderEarningsSummary: Equatable, Decodable {
    let completedTodayCount: Int
    let activeTodayCount: Int
    let todayEarnings: Int
    let pendingPayout: Int

    static func make(
        bookings: [BookingItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> ProviderEarningsSummary {
        let formatter = ISO8601DateFormatter()

        let todaysBookings = bookings.filter {
            guard let date = formatter.date(from: $0.startTime) else { return false }
            return calendar.isDate(date, inSameDayAs: now)
        }

        let completedToday = todaysBookings.filter { $0.status.uppercased() == "COMPLETED" }
        let activeToday = todaysBookings.filter { $0.status.uppercased() == "IN_PROGRESS" }
        let pendingPayoutBookings = bookings.filter {
            let normalizedStatus = $0.status.uppercased()
            let normalizedPaymentStatus = ($0.paymentStatus ?? "").uppercased()

            guard normalizedStatus == "COMPLETED" else { return false }
            return normalizedPaymentStatus != "PAID" && normalizedPaymentStatus != "SETTLED"
        }

        return ProviderEarningsSummary(
            completedTodayCount: completedToday.count,
            activeTodayCount: activeToday.count,
            todayEarnings: completedToday.reduce(0) { $0 + $1.totalPrice },
            pendingPayout: pendingPayoutBookings.reduce(0) { $0 + $1.totalPrice }
        )
    }
}

enum ChatSocketPayloadParser {
    static func event(
        from text: String,
        now: @autoclosure () -> Date = Date()
    ) -> ChatSocketParsedEvent? {
        guard
            let data = text.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let type = (object["type"] as? String ?? object["event"] as? String ?? "").lowercased()
        let chatID =
            object["chat_id"] as? String
            ?? object["chatId"] as? String
            ?? object["conversation_id"] as? String
            ?? object["conversationId"] as? String

        if type == "typing" {
            let isTyping =
                object["is_typing"] as? Bool
                ?? object["isTyping"] as? Bool
                ?? object["typing"] as? Bool

            guard let chatID, let isTyping else { return nil }
            return .typing(chatID: chatID, isTyping: isTyping)
        }

        if type == "message" || type == "new_message" {
            let messageText =
                object["text"] as? String
                ?? object["message"] as? String
                ?? object["body"] as? String
            let createdAt =
                object["created_at"] as? String
                ?? object["createdAt"] as? String
                ?? ISO8601DateFormatter().string(from: now())

            guard let chatID, let messageText else { return nil }
            return .message(chatID: chatID, text: messageText, createdAt: createdAt)
        }

        return nil
    }
}

enum NotificationMutationPlan {
    static func markReadCandidates(notificationID: String) -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(
                path: "v1/notifications/\(notificationID)/read",
                method: "POST",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/notifications/\(notificationID)/read",
                method: "PATCH",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/notifications/\(notificationID)",
                method: "PATCH",
                sendsReadBody: true
            )
        ]
    }

    static func markAllReadCandidates() -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(
                path: "v1/notifications/read-all",
                method: "POST",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/notifications/mark-all-read",
                method: "POST",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/notifications/read",
                method: "PATCH",
                sendsReadBody: true
            )
        ]
    }

    static func bookingCompletedCandidates(parentUserID: String) -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(
                path: "v1/notifications",
                method: "POST",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/users/\(parentUserID)/notifications",
                method: "POST",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/parents/\(parentUserID)/notifications",
                method: "POST",
                sendsReadBody: false
            )
        ]
    }

    static func shouldFallbackForUnavailableMutation(statusCode: Int) -> Bool {
        statusCode == 404 || statusCode == 405
    }
}

enum BookingMutationPlan {
    static func cancelCandidates(bookingID: String) -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/cancel",
                method: "POST",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/cancel",
                method: "PATCH",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)",
                method: "DELETE",
                sendsReadBody: false
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/status",
                method: "PATCH",
                sendsReadBody: true
            )
        ]
    }

    static func rescheduleCandidates(bookingID: String) -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/reschedule",
                method: "POST",
                sendsReadBody: true
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/reschedule",
                method: "PATCH",
                sendsReadBody: true
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/schedule",
                method: "PATCH",
                sendsReadBody: true
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)",
                method: "PATCH",
                sendsReadBody: true
            )
        ]
    }

    static func providerDecisionCandidates(bookingID: String) -> [MutationRequestCandidate] {
        [
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/status",
                method: "PATCH",
                sendsReadBody: true
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)/decision",
                method: "POST",
                sendsReadBody: true
            ),
            MutationRequestCandidate(
                path: "v1/bookings/\(bookingID)",
                method: "PATCH",
                sendsReadBody: true
            )
        ]
    }

    static func shouldFallbackForUnavailableMutation(statusCode: Int) -> Bool {
        statusCode == 404 || statusCode == 405
    }
}

enum CheckoutCompletionDetector {
    static func completion(for url: URL) -> CheckoutCompletion? {
        let absolute = url.absoluteString.lowercased()
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).map {
                ($0.name.lowercased(), ($0.value ?? "").lowercased())
            }
        )

        if let status = query["status"] ?? query["result"] ?? query["payment_status"] {
            if ["success", "successful", "paid", "succeeded", "ok"].contains(status) {
                return .success
            }
            if ["cancel", "cancelled", "canceled", "failure", "failed"].contains(status) {
                return .cancelled
            }
        }

        if absolute.contains("payment/success")
            || absolute.contains("checkout/success")
            || absolute.contains("checkout-success")
            || absolute.contains("payment-success")
            || absolute.contains("callback/success")
            || ((host.contains("success") || path.contains("success"))
                && (path.contains("payment") || path.contains("checkout") || path.contains("callback")))
        {
            return .success
        }

        if absolute.contains("payment/cancel")
            || absolute.contains("checkout/cancel")
            || absolute.contains("checkout-cancel")
            || absolute.contains("payment-cancel")
            || absolute.contains("callback/cancel")
        {
            return .cancelled
        }

        return nil
    }
}

enum ChatSocketReconnectPlan {
    static func shouldReuseOpenConnection(
        currentToken: String?,
        incomingToken: String,
        isConnected: Bool,
        hasSocket: Bool
    ) -> Bool {
        currentToken == incomingToken && isConnected && hasSocket
    }

    static func shouldScheduleReconnect(currentToken: String?) -> Bool {
        currentToken?.isEmpty == false
    }

    static func reconnectDelay(forAttempt attempt: Int) -> TimeInterval {
        let sanitizedAttempt = max(0, attempt)
        let baseDelay = pow(2.0, Double(sanitizedAttempt))
        return min(max(2.0, baseDelay), 30.0)
    }
}

enum BookingPresentationTone: Equatable {
    case primary
    case accent
    case danger
    case neutral
}

struct BookingStatusPresentation {
    let localizedStatus: String
    let statusTone: BookingPresentationTone
    let paymentSummaryText: String
    let paymentSummaryTone: BookingPresentationTone
    let paymentLabel: String
    let paymentDescription: String
    let paymentTone: BookingPresentationTone
    let paymentIcon: String
    let canPay: Bool
    let canRebook: Bool
    let canCancel: Bool

    static func make(for status: String, paymentStatus: String? = nil) -> BookingStatusPresentation {
        let base: BookingStatusPresentation

        switch status.uppercased() {
        case "ACCEPTED", "CONFIRMED":
            base = BookingStatusPresentation(
                localizedStatus: "Onaylandı",
                statusTone: .primary,
                paymentSummaryText: "Sıradaki adım ödeme",
                paymentSummaryTone: .primary,
                paymentLabel: "Hazır",
                paymentDescription: "Rezervasyon onaylandı. Hazırsan şimdi ödeme adımına geçip rezervasyonu tamamlayabilirsin.",
                paymentTone: .primary,
                paymentIcon: "creditcard",
                canPay: true,
                canRebook: false,
                canCancel: true
            )
        case "IN_PROGRESS":
            base = BookingStatusPresentation(
                localizedStatus: "Devam Ediyor",
                statusTone: .primary,
                paymentSummaryText: "Hizmet aktif",
                paymentSummaryTone: .primary,
                paymentLabel: "Aktif",
                paymentDescription: "Hizmet başladı. İş bittiğinde bu kaydı tamamlandı olarak işaretleyebilirsin.",
                paymentTone: .primary,
                paymentIcon: "figure.walk",
                canPay: false,
                canRebook: false,
                canCancel: false
            )
        case "REQUESTED":
            base = BookingStatusPresentation(
                localizedStatus: "Beklemede",
                statusTone: .accent,
                paymentSummaryText: "Onay bekleniyor",
                paymentSummaryTone: .accent,
                paymentLabel: "Beklemede",
                paymentDescription: "Rezervasyon talebin alındı. Karşı taraf onay verdiğinde ödeme adımı açılacak.",
                paymentTone: .accent,
                paymentIcon: "clock.badge",
                canPay: true,
                canRebook: false,
                canCancel: true
            )
        case "COMPLETED":
            base = BookingStatusPresentation(
                localizedStatus: "Tamamlandı",
                statusTone: .primary,
                paymentSummaryText: "Ödeme tamamlandı",
                paymentSummaryTone: .primary,
                paymentLabel: "Tamamlandı",
                paymentDescription: "Bu rezervasyon tamamlanmış görünüyor. Gerekirse aynı bakıcı ile yeni bir rezervasyon oluşturabilirsin.",
                paymentTone: .primary,
                paymentIcon: "checkmark.circle",
                canPay: false,
                canRebook: true,
                canCancel: false
            )
        case "CANCELED", "CANCELLED":
            base = BookingStatusPresentation(
                localizedStatus: "İptal Edildi",
                statusTone: .danger,
                paymentSummaryText: "Ödeme kapatıldı",
                paymentSummaryTone: .danger,
                paymentLabel: "Kapatıldı",
                paymentDescription: "Bu rezervasyon kapatıldı. Tekrar ihtiyacın olursa aynı bakıcı için yeni bir takvim seç.",
                paymentTone: .danger,
                paymentIcon: "xmark.circle",
                canPay: false,
                canRebook: true,
                canCancel: false
            )
        default:
            base = BookingStatusPresentation(
                localizedStatus: status,
                statusTone: .neutral,
                paymentSummaryText: "Ödeme durumu bilinmiyor",
                paymentSummaryTone: .neutral,
                paymentLabel: "Bilinmiyor",
                paymentDescription: "Ödeme durumunu şu anda net okuyamadık. Birkaç saniye sonra tekrar kontrol edebilirsin.",
                paymentTone: .neutral,
                paymentIcon: "questionmark.circle",
                canPay: false,
                canRebook: false,
                canCancel: false
            )
        }

        guard let paymentStatus else { return base }
        return base.overridingPaymentStatus(paymentStatus)
    }

    private func overridingPaymentStatus(_ paymentStatus: String) -> BookingStatusPresentation {
        switch paymentStatus.uppercased() {
        case "PAID", "SUCCEEDED", "SUCCESS":
            return withPayment(
                summary: "Ödeme tamamlandı",
                tone: .primary,
                label: "Tamamlandı",
                description: "Ödeme tamamlandı. Rezervasyonun planlandığı şekilde devam edecek.",
                icon: "checkmark.circle.fill"
            )
        case "PENDING", "PROCESSING":
            return withPayment(
                summary: "Ödeme işleniyor",
                tone: .accent,
                label: "İşleniyor",
                description: "Ödeme alındı ve işleniyor. Sonuç kesinleştiğinde burada güncellenecek.",
                icon: "hourglass"
            )
        case "REQUIRES_ACTION", "REQUIRES_PAYMENT_METHOD", "UNPAID":
            return withPayment(
                summary: "Ödeme aksiyonu gerekiyor",
                tone: .accent,
                label: "Aksiyon Gerekli",
                description: "Ödemenin tamamlanması için checkout adımına geri dönülmesi gerekiyor.",
                icon: "exclamationmark.circle"
            )
        case "FAILED", "CANCELED", "CANCELLED":
            return withPayment(
                summary: "Ödeme başarısız",
                tone: .danger,
                label: "Başarısız",
                description: "Ödeme tamamlanmadı. İstersen tekrar deneyebilir ya da başka bir ödeme yöntemi seçebilirsin.",
                icon: "xmark.octagon"
            )
        default:
            return self
        }
    }

    private func withPayment(
        summary: String,
        tone: BookingPresentationTone,
        label: String,
        description: String,
        icon: String
    ) -> BookingStatusPresentation {
        BookingStatusPresentation(
            localizedStatus: localizedStatus,
            statusTone: statusTone,
            paymentSummaryText: summary,
            paymentSummaryTone: tone,
            paymentLabel: label,
            paymentDescription: description,
            paymentTone: tone,
            paymentIcon: icon,
            canPay: canPay,
            canRebook: canRebook,
            canCancel: canCancel
        )
    }
}

struct HomeDashboardSnapshot {
    let bookings: [BookingItem]
    let favorites: [FavoriteItem]
    let notifications: [AppNotification]
    let conversations: [ConversationItem]

    var activeBookings: [BookingItem] {
        bookings.filter { !$0.status.uppercased().contains("COMPLETED") }
    }

    var completedBookings: [BookingItem] {
        bookings.filter { $0.status.uppercased() == "COMPLETED" }
    }

    var unreadNotifications: Int {
        notifications.filter { !$0.read }.count
    }

    static func make(
        bookings: [BookingItem],
        favoritesResponse: FavoritesResponse,
        notificationsResponse: NotificationsResponse,
        conversationsResponse: ConversationsResponse
    ) -> HomeDashboardSnapshot {
        HomeDashboardSnapshot(
            bookings: bookings.sorted { $0.startTime < $1.startTime },
            favorites: favoritesResponse.favorites.sorted { $0.rating > $1.rating },
            notifications: notificationsResponse.notifications,
            conversations: conversationsResponse.conversations
        )
    }
}
