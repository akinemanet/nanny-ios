//
//  BookingModels.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

struct CreateBookingReq: Codable {
    let providerUserID: String
    let service: String
    let startAt: String
    let endAt: String
    let bookingType: String
    let familyDisplayName: String?
    let familyAbout: String?
    let familyLocationName: String?
    let familyLocationLatitude: Double?
    let familyLocationLongitude: Double?

    enum CodingKeys: String, CodingKey {
        case providerUserID = "provider_user_id"
        case service
        case startAt = "start_at"
        case endAt = "end_at"
        case bookingType = "booking_type"
        case familyDisplayName = "family_display_name"
        case familyAbout = "family_about"
        case familyLocationName = "family_location_name"
        case familyLocationLatitude = "family_location_latitude"
        case familyLocationLongitude = "family_location_longitude"
    }
}

struct CreateBookingRes: Decodable {
    let booking: BookingRecord
}

struct RescheduleBookingReq: Codable {
    let startAt: String
    let endAt: String

    enum CodingKeys: String, CodingKey {
        case startAt = "start_at"
        case endAt = "end_at"
    }
}

struct RescheduleBookingRes: Decodable {
    let ok: Bool?
    let booking: BookingRecord?
}

struct CancelBookingRes: Decodable {
    let ok: Bool?
    let booking: BookingRecord?
}

struct ProviderBookingDecisionReq: Encodable {
    let status: String
}

struct ProviderBookingDecisionRes: Decodable {
    let ok: Bool?
    let booking: BookingRecord?
}

struct BookingsResponse: Decodable {
    let count: Int
    let items: [BookingRecord]
}

struct BookingRecord: Decodable, Identifiable {
    let id: String
    let parentUserID: String?
    let providerUserID: String
    let service: String
    let startAt: String
    let endAt: String
    let bookingType: String
    let status: String
    let createdAt: String?
    let updatedAt: String?
    let totalPrice: Int?
    let address: String?
    let paymentStatus: String?
    let providerDisplayName: String?
    let providerHourlyRate: Int?
    let familyDisplayName: String?
    let familyAbout: String?
    let familyLocationName: String?
    let familyLocationLatitude: Double?
    let familyLocationLongitude: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case parentUserID = "parent_user_id"
        case providerUserID = "provider_user_id"
        case service
        case startAt = "start_at"
        case endAt = "end_at"
        case bookingType = "booking_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalPrice = "total_price"
        case totalPriceAlt = "price_total"
        case totalPriceLegacy = "amount"
        case address
        case paymentStatus = "payment_status"
        case paymentStatusAlt = "checkout_status"
        case paymentStatusLegacy = "payment_state"
        case providerDisplayName = "provider_display_name"
        case providerDisplayNameAlt = "provider_name"
        case providerHourlyRate = "provider_hourly_rate"
        case providerHourlyRateAlt = "hourly_rate"
        case familyDisplayName = "family_display_name"
        case familyDisplayNameAlt = "parent_display_name"
        case familyAbout = "family_about"
        case familyAboutAlt = "parent_about"
        case familyLocationName = "family_location_name"
        case familyLocationNameAlt = "parent_location_name"
        case familyLocationLatitude = "family_location_latitude"
        case familyLocationLatitudeAlt = "parent_location_latitude"
        case familyLocationLongitude = "family_location_longitude"
        case familyLocationLongitudeAlt = "parent_location_longitude"
        case provider
        case parent
    }

    enum ProviderCodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case displayName
        case fullName = "full_name"
        case name
        case hourlyRate = "hourly_rate"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        parentUserID = try container.decodeIfPresent(String.self, forKey: .parentUserID)
        service = try container.decode(String.self, forKey: .service)
        startAt = try container.decode(String.self, forKey: .startAt)
        endAt = try container.decode(String.self, forKey: .endAt)
        bookingType = try container.decode(String.self, forKey: .bookingType)
        status = try container.decode(String.self, forKey: .status)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        totalPrice =
            try container.decodeIfPresent(Int.self, forKey: .totalPrice)
            ?? container.decodeIfPresent(Int.self, forKey: .totalPriceAlt)
            ?? container.decodeIfPresent(Int.self, forKey: .totalPriceLegacy)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        paymentStatus =
            try container.decodeIfPresent(String.self, forKey: .paymentStatus)
            ?? container.decodeIfPresent(String.self, forKey: .paymentStatusAlt)
            ?? container.decodeIfPresent(String.self, forKey: .paymentStatusLegacy)

        let providerContainer = try container.decodeIfPresent(ProviderPayload.self, forKey: .provider)
        let parentContainer = try container.decodeIfPresent(ParentPayload.self, forKey: .parent)

        providerUserID =
            try container.decodeIfPresent(String.self, forKey: .providerUserID)
            ?? providerContainer?.id
            ?? providerContainer?.userID
            ?? ""
        providerDisplayName =
            try container.decodeIfPresent(String.self, forKey: .providerDisplayName)
            ?? container.decodeIfPresent(String.self, forKey: .providerDisplayNameAlt)
            ?? providerContainer?.displayName
            ?? providerContainer?.fullName
            ?? providerContainer?.name
        providerHourlyRate =
            try container.decodeIfPresent(Int.self, forKey: .providerHourlyRate)
            ?? container.decodeIfPresent(Int.self, forKey: .providerHourlyRateAlt)
            ?? providerContainer?.hourlyRate
        familyDisplayName =
            try container.decodeIfPresent(String.self, forKey: .familyDisplayName)
            ?? container.decodeIfPresent(String.self, forKey: .familyDisplayNameAlt)
            ?? parentContainer?.displayName
            ?? parentContainer?.fullName
            ?? parentContainer?.name
        familyAbout =
            try container.decodeIfPresent(String.self, forKey: .familyAbout)
            ?? container.decodeIfPresent(String.self, forKey: .familyAboutAlt)
            ?? parentContainer?.about
            ?? parentContainer?.bio
        familyLocationName =
            try container.decodeIfPresent(String.self, forKey: .familyLocationName)
            ?? container.decodeIfPresent(String.self, forKey: .familyLocationNameAlt)
            ?? parentContainer?.locationName
        familyLocationLatitude =
            try container.decodeIfPresent(Double.self, forKey: .familyLocationLatitude)
            ?? container.decodeIfPresent(Double.self, forKey: .familyLocationLatitudeAlt)
            ?? parentContainer?.locationLatitude
        familyLocationLongitude =
            try container.decodeIfPresent(Double.self, forKey: .familyLocationLongitude)
            ?? container.decodeIfPresent(Double.self, forKey: .familyLocationLongitudeAlt)
            ?? parentContainer?.locationLongitude
    }

    init(
        id: String,
        parentUserID: String?,
        providerUserID: String,
        service: String,
        startAt: String,
        endAt: String,
        bookingType: String,
        status: String,
        createdAt: String?,
        updatedAt: String?,
        totalPrice: Int?,
        address: String?,
        paymentStatus: String?,
        providerDisplayName: String?,
        providerHourlyRate: Int?,
        familyDisplayName: String?,
        familyAbout: String?,
        familyLocationName: String?,
        familyLocationLatitude: Double?,
        familyLocationLongitude: Double?
    ) {
        self.id = id
        self.parentUserID = parentUserID
        self.providerUserID = providerUserID
        self.service = service
        self.startAt = startAt
        self.endAt = endAt
        self.bookingType = bookingType
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalPrice = totalPrice
        self.address = address
        self.paymentStatus = paymentStatus
        self.providerDisplayName = providerDisplayName
        self.providerHourlyRate = providerHourlyRate
        self.familyDisplayName = familyDisplayName
        self.familyAbout = familyAbout
        self.familyLocationName = familyLocationName
        self.familyLocationLatitude = familyLocationLatitude
        self.familyLocationLongitude = familyLocationLongitude
    }

    private struct ProviderPayload: Codable {
        let id: String?
        let userID: String?
        let displayName: String?
        let fullName: String?
        let name: String?
        let hourlyRate: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case userID = "user_id"
            case displayName
            case fullName = "full_name"
            case name
            case hourlyRate = "hourly_rate"
        }
    }

    private struct ParentPayload: Codable {
        let displayName: String?
        let fullName: String?
        let name: String?
        let about: String?
        let bio: String?
        let locationName: String?
        let locationLatitude: Double?
        let locationLongitude: Double?

        enum CodingKeys: String, CodingKey {
            case displayName
            case fullName = "full_name"
            case name
            case about
            case bio
            case locationName = "location_name"
            case locationLatitude = "location_latitude"
            case locationLongitude = "location_longitude"
        }
    }
}

struct BookingItem: Identifiable, Hashable {
    let id: String
    let service: String
    let status: String
    let startTime: String
    let endTime: String
    let totalPrice: Int
    let address: String?
    let paymentStatus: String?
    let provider: BookingProvider
    let parentUserID: String?
    let familyDisplayName: String?
    let familyAbout: String?
    let familyLocationName: String?
    let familyLocationLatitude: Double?
    let familyLocationLongitude: Double?

    init(
        id: String,
        service: String,
        status: String,
        startTime: String,
        endTime: String,
        totalPrice: Int,
        address: String?,
        paymentStatus: String?,
        provider: BookingProvider,
        parentUserID: String? = nil,
        familyDisplayName: String? = nil,
        familyAbout: String? = nil,
        familyLocationName: String? = nil,
        familyLocationLatitude: Double? = nil,
        familyLocationLongitude: Double? = nil
    ) {
        self.id = id
        self.service = service
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.totalPrice = totalPrice
        self.address = address
        self.paymentStatus = paymentStatus
        self.provider = provider
        self.parentUserID = parentUserID
        self.familyDisplayName = familyDisplayName
        self.familyAbout = familyAbout
        self.familyLocationName = familyLocationName
        self.familyLocationLatitude = familyLocationLatitude
        self.familyLocationLongitude = familyLocationLongitude
    }
}

struct BookingProvider: Hashable {
    let id: String
    let displayName: String
    let hourlyRate: Int?
}

struct CareRequestCandidate: Codable, Identifiable, Hashable {
    var id: String { providerUserID }
    let providerUserID: String
    let providerDisplayName: String
    let providerPhone: String?
    let appliedAt: String
}

struct CareRequestItem: Codable, Identifiable, Hashable {
    let id: String
    let parentUserID: String
    let parentDisplayName: String
    let parentPhone: String?
    let service: String
    let note: String
    let startAt: String
    let endAt: String
    let locationName: String
    let createdAt: String
    var status: String
    var candidates: [CareRequestCandidate]
    var assignedProviderUserID: String?
    var assignedProviderDisplayName: String?

    var isOpen: Bool {
        status.uppercased() == "OPEN"
    }

    var isMatched: Bool {
        status.uppercased() == "MATCHED"
    }
}

struct CreateCareRequestInput: Hashable {
    let service: String
    let note: String
    let startAt: Date
    let endAt: Date
    let locationName: String
}

struct NotificationsResponse: Decodable {
    let notifications: [AppNotification]
}

struct AppNotification: Decodable, Identifiable {
    let id: String
    let title: String
    let body: String
    let createdAt: String
    let read: Bool
    let type: String?
    let bookingID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case createdAt = "created_at"
        case createdAtAlt = "createdAt"
        case read
        case type
        case bookingID = "booking_id"
    }

    init(
        id: String,
        title: String,
        body: String,
        createdAt: String,
        read: Bool,
        type: String? = nil,
        bookingID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.read = read
        self.type = type
        self.bookingID = bookingID
    }

    init?(userInfo: [AnyHashable: Any]) {
        func stringValue(_ value: Any?) -> String? {
            if let string = value as? String, !string.isEmpty {
                return string
            }
            if let number = value as? NSNumber {
                return number.stringValue
            }
            return nil
        }

        let aps = userInfo["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]
        let data = userInfo["data"] as? [String: Any]

        let resolvedTitle =
            stringValue(userInfo["title"])
            ?? stringValue(data?["title"])
            ?? stringValue(alert?["title"])
            ?? "Bildirim"

        let resolvedBody =
            stringValue(userInfo["body"])
            ?? stringValue(data?["body"])
            ?? stringValue(alert?["body"])
            ?? stringValue(alert?["subtitle"])
            ?? ""

        guard !resolvedBody.isEmpty || !resolvedTitle.isEmpty else { return nil }

        id =
            stringValue(userInfo["notification_id"])
            ?? stringValue(data?["notification_id"])
            ?? stringValue(userInfo["google.c.a.c_id"])
            ?? UUID().uuidString
        title = resolvedTitle
        body = resolvedBody
        createdAt =
            stringValue(userInfo["created_at"])
            ?? stringValue(data?["created_at"])
            ?? ISO8601DateFormatter().string(from: Date())
        read = false
        type =
            stringValue(userInfo["type"])
            ?? stringValue(data?["type"])
            ?? stringValue(aps?["type"])
        bookingID =
            stringValue(userInfo["booking_id"])
            ?? stringValue(data?["booking_id"])
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        createdAt =
            try container.decodeIfPresent(String.self, forKey: .createdAt)
            ?? container.decode(String.self, forKey: .createdAtAlt)
        read = try container.decode(Bool.self, forKey: .read)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        bookingID = try container.decodeIfPresent(String.self, forKey: .bookingID)
    }
}

struct ConversationsResponse: Decodable {
    let conversations: [ConversationItem]
}

struct ConversationItem: Decodable, Identifiable, Hashable {
    let id: String
    let participantID: String?
    let participantName: String
    let lastMessage: String
    let lastMessageAt: String
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case participantID = "participant_user_id"
        case participantIDAlt = "participant_id"
        case participantIDLegacy = "user_id"
        case participantName
        case lastMessage
        case lastMessageAt
        case unreadCount
    }

    init(
        id: String,
        participantID: String?,
        participantName: String,
        lastMessage: String,
        lastMessageAt: String,
        unreadCount: Int
    ) {
        self.id = id
        self.participantID = participantID
        self.participantName = participantName
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        participantID =
            try container.decodeIfPresent(String.self, forKey: .participantID)
            ?? container.decodeIfPresent(String.self, forKey: .participantIDAlt)
            ?? container.decodeIfPresent(String.self, forKey: .participantIDLegacy)
        participantName = try container.decode(String.self, forKey: .participantName)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        lastMessageAt = try container.decode(String.self, forKey: .lastMessageAt)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
    }
}

struct MessagesResponse: Codable {
    let messages: [ChatMessage]
}

struct SendMessageReq: Codable {
    let text: String
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let text: String
    let isMine: Bool
    let createdAt: String
}

struct CallsResponse: Codable {
    let calls: [CallItem]
}

struct CallItem: Codable, Identifiable {
    let id: String
    let participantName: String
    let direction: String
    let status: String
    let createdAt: String
}

struct FavoritesResponse: Codable {
    let favorites: [FavoriteItem]
}

struct FavoriteMutationResponse: Codable {
    let ok: Bool
}

struct FavoriteItem: Codable, Identifiable {
    var id: String { providerId }
    let providerId: String
    let displayName: String
    let rating: Double
}

struct PaymentMethodsResponse: Codable {
    let paymentMethods: [PaymentMethodItem]
}

struct CreatePaymentMethodReq: Codable {
    let brand: String
    let cardNumber: String
    let holderName: String
    let expMonth: Int
    let expYear: Int
    let cvc: String
}

struct PaymentMethodItem: Codable, Identifiable {
    let id: String
    let brand: String
    let last4: String
    let holderName: String
    let expMonth: Int
    let expYear: Int
    let isDefault: Bool
}
