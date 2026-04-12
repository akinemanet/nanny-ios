//
//  ProviderModels.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation

struct ProviderAccount: Codable {
    let id: String?
    let providerUserId: String?
    let subMerchantExternalId: String?
    let subMerchantKey: String?
    let subMerchantType: String?
    let currency: String
    let status: String
    let lastError: String?
    let address: String
    let contactName: String
    let contactSurname: String
    let email: String
    let gsmNumber: String
    let name: String
    let iban: String
    let identityNumber: String
}

struct UpsertPayoutAccountRequest: Codable {
    let address: String
    let contactName: String
    let contactSurname: String
    let email: String
    let gsmNumber: String
    let name: String
    let iban: String
    let identityNumber: String
}

struct PayoutAccountResponse: Codable {
    let account: ProviderAccount?
}

struct ProviderOnboardingProfile: Codable {
    let educationLevel: String
    let about: String
    let experience: String
    let categories: [String]
    let age: Int?
    let hourlyRate: Int?
    let dailyRate: Int?
    let profilePhotoName: String
    let profilePhotoUrl: String
    let criminalRecordFileName: String
    let criminalRecordUrl: String
    let profilePhotoStatus: String
    let criminalRecordStatus: String
    let approvalStatus: String

    init(
        educationLevel: String = "",
        about: String = "",
        experience: String = "",
        categories: [String] = [],
        age: Int? = nil,
        hourlyRate: Int? = nil,
        dailyRate: Int? = nil,
        profilePhotoName: String = "",
        profilePhotoUrl: String = "",
        criminalRecordFileName: String = "",
        criminalRecordUrl: String = "",
        profilePhotoStatus: String = "MISSING",
        criminalRecordStatus: String = "MISSING",
        approvalStatus: String = "PENDING"
    ) {
        self.educationLevel = educationLevel
        self.about = about
        self.experience = experience
        self.categories = categories
        self.age = age
        self.hourlyRate = hourlyRate
        self.dailyRate = dailyRate
        self.profilePhotoName = profilePhotoName
        self.profilePhotoUrl = profilePhotoUrl
        self.criminalRecordFileName = criminalRecordFileName
        self.criminalRecordUrl = criminalRecordUrl
        self.profilePhotoStatus = profilePhotoStatus
        self.criminalRecordStatus = criminalRecordStatus
        self.approvalStatus = approvalStatus
    }

    enum CodingKeys: String, CodingKey {
        case educationLevel
        case about
        case experience
        case categories
        case age
        case hourlyRate
        case dailyRate
        case profilePhotoName
        case profilePhotoUrl
        case criminalRecordFileName
        case criminalRecordUrl
        case profilePhotoStatus
        case criminalRecordStatus
        case approvalStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            educationLevel: try container.decodeIfPresent(String.self, forKey: .educationLevel) ?? "",
            about: try container.decodeIfPresent(String.self, forKey: .about) ?? "",
            experience: try container.decodeIfPresent(String.self, forKey: .experience) ?? "",
            categories: try container.decodeIfPresent([String].self, forKey: .categories) ?? [],
            age: try container.decodeIfPresent(Int.self, forKey: .age),
            hourlyRate: try container.decodeIfPresent(Int.self, forKey: .hourlyRate),
            dailyRate: try container.decodeIfPresent(Int.self, forKey: .dailyRate),
            profilePhotoName: try container.decodeIfPresent(String.self, forKey: .profilePhotoName) ?? "",
            profilePhotoUrl: try container.decodeIfPresent(String.self, forKey: .profilePhotoUrl) ?? "",
            criminalRecordFileName: try container.decodeIfPresent(String.self, forKey: .criminalRecordFileName) ?? "",
            criminalRecordUrl: try container.decodeIfPresent(String.self, forKey: .criminalRecordUrl) ?? "",
            profilePhotoStatus: try container.decodeIfPresent(String.self, forKey: .profilePhotoStatus) ?? "MISSING",
            criminalRecordStatus: try container.decodeIfPresent(String.self, forKey: .criminalRecordStatus) ?? "MISSING",
            approvalStatus: try container.decodeIfPresent(String.self, forKey: .approvalStatus) ?? "PENDING"
        )
    }
}

struct ProviderOnboardingSummary: Codable {
    let account: ProviderAccount?
    let profile: ProviderOnboardingProfile

    init(account: ProviderAccount?, profile: ProviderOnboardingProfile = ProviderOnboardingProfile()) {
        self.account = account
        self.profile = profile
    }
}

struct UpsertProviderOnboardingProfileRequest: Codable {
    let educationLevel: String
    let about: String
    let categories: [String]
    let profilePhotoName: String
    let criminalRecordFileName: String
}

struct UpsertProviderProfileRequest: Codable {
    let fullName: String
    let educationLevel: String
    let about: String
    let experience: String
    let categories: [String]
    let age: Int
    let hourlyRate: Int
    let dailyRate: Int
    let profilePhotoName: String
    let criminalRecordFileName: String
}

struct ProviderProfileMutationResponse: Codable {
    let profile: ProviderProfileMutationState?
    let summary: ProviderOnboardingSummary?
}

struct ProviderProfileMutationState: Codable {
    let age: Int?
    let hourlyRate: Int?
    let dailyRate: Int?
    let approvalStatus: String?
}

enum ProviderCategoryMapper {
    private static let labelToService: [String: String] = [
        "Bebek Bakımı": "BABY_CARE",
        "Yürümeye Başlayan": "TODDLER_CARE",
        "Okul Öncesi": "PRESCHOOL",
        "Anaokulu": "KINDERGARTEN",
        "İlkokul Desteği": "PRIMARY_SCHOOL_SUPPORT",
        "Özel Ders": "TUTOR",
        "Özel Eğitim": "SPECIAL_ED",
    ]

    private static let serviceToLabel: [String: String] = [
        "BABY_CARE": "Bebek Bakımı",
        "TODDLER_CARE": "Yürümeye Başlayan",
        "PRESCHOOL": "Okul Öncesi",
        "KINDERGARTEN": "Anaokulu",
        "PRIMARY_SCHOOL_SUPPORT": "İlkokul Desteği",
        "BABYSITTER": "Bebek Bakımı",
        "TUTOR": "Özel Ders",
        "SPECIAL_ED": "Özel Eğitim",
    ]

    static func backendServices(from labels: [String]) -> [String] {
        let mapped = labels.map { labelToService[$0] ?? $0 }
        var seen = Set<String>()
        return mapped.filter { seen.insert($0).inserted }
    }

    static func displayLabels(from services: [String]) -> [String] {
        services.map { serviceToLabel[$0] ?? $0 }
    }
}

enum ProviderDocumentKind: String {
    case profilePhoto = "profile-photo"
    case criminalRecord = "criminal-record"
}

struct ProviderDocumentUploadResponse: Codable {
    let ok: Bool
    let kind: String
    let profile: ProviderOnboardingProfileUploadState?
    let url: String?
}

struct ProviderOnboardingProfileUploadState: Codable {
    let profilePhotoName: String?
    let profilePhotoUrl: String?
    let profilePhotoStatus: String?
    let criminalRecordFileName: String?
    let criminalRecordUrl: String?
    let criminalRecordStatus: String?
    let approvalStatus: String?
}
struct BrowseProvider: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let rating: Double
    let hourlyRate: Int
    let payoutStatus: String
    let age: Int
    let gender: String
    let locationName: String
    let distanceText: String
    let photoURL: String?
    let latitude: Double?
    let longitude: Double?
    let categories: [String]
    let reviewCount: Int
    let completedSittings: Int
    let availableDates: [String]
    let availableStartHour: Int
    let availableEndHour: Int

    init(
        id: String,
        displayName: String,
        rating: Double,
        hourlyRate: Int,
        payoutStatus: String,
        age: Int,
        gender: String,
        locationName: String,
        distanceText: String,
        photoURL: String?,
        latitude: Double?,
        longitude: Double?,
        categories: [String],
        reviewCount: Int,
        completedSittings: Int,
        availableDates: [String],
        availableStartHour: Int,
        availableEndHour: Int
    ) {
        self.id = id
        self.displayName = displayName
        self.rating = rating
        self.hourlyRate = hourlyRate
        self.payoutStatus = payoutStatus
        self.age = age
        self.gender = gender
        self.locationName = locationName
        self.distanceText = distanceText
        self.photoURL = photoURL
        self.latitude = latitude
        self.longitude = longitude
        self.categories = categories
        self.reviewCount = reviewCount
        self.completedSittings = completedSittings
        self.availableDates = availableDates
        self.availableStartHour = availableStartHour
        self.availableEndHour = availableEndHour
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case rating
        case hourlyRate
        case payoutStatus
        case age
        case gender
        case locationName
        case distanceText
        case photoURL = "photoUrl"
        case latitude
        case longitude
        case categories
        case reviewCount
        case completedSittings
        case availableDates
        case availableStartHour
        case availableEndHour
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            displayName: try container.decodeIfPresent(String.self, forKey: .displayName) ?? "Bakici",
            rating: try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0,
            hourlyRate: try container.decodeIfPresent(Int.self, forKey: .hourlyRate) ?? 600,
            payoutStatus: try container.decodeIfPresent(String.self, forKey: .payoutStatus) ?? "PENDING",
            age: try container.decodeIfPresent(Int.self, forKey: .age) ?? 0,
            gender: try container.decodeIfPresent(String.self, forKey: .gender) ?? "Kadin",
            locationName: try container.decodeIfPresent(String.self, forKey: .locationName) ?? "Konum bilgisi yakinda",
            distanceText: try container.decodeIfPresent(String.self, forKey: .distanceText) ?? "Mesafe bilgisi yakinda",
            photoURL: try container.decodeIfPresent(String.self, forKey: .photoURL),
            latitude: try container.decodeIfPresent(Double.self, forKey: .latitude),
            longitude: try container.decodeIfPresent(Double.self, forKey: .longitude),
            categories: ProviderCategoryMapper.displayLabels(from: try container.decodeIfPresent([String].self, forKey: .categories) ?? []),
            reviewCount: try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0,
            completedSittings: try container.decodeIfPresent(Int.self, forKey: .completedSittings) ?? 0,
            availableDates: try container.decodeIfPresent([String].self, forKey: .availableDates) ?? [],
            availableStartHour: try container.decodeIfPresent(Int.self, forKey: .availableStartHour) ?? 9,
            availableEndHour: try container.decodeIfPresent(Int.self, forKey: .availableEndHour) ?? 18
        )
    }
}

struct ProvidersResponse: Codable {
    let providers: [BrowseProvider]
}

struct ProviderDetailResponse: Codable {
    let provider: ProviderDetail
}

struct ProviderDetail: Codable, Identifiable {
    let id: String
    let displayName: String
    let rating: Double
    let hourlyRate: Int
    let payoutStatus: String
    let educationLevel: String
    let about: String
    let experience: String
    let experienceYears: Int
    let age: Int
    let completedSittings: Int
    let locationName: String
    let distanceText: String
    let photoURL: String?
    let latitude: Double?
    let longitude: Double?
    let skills: [String]
    let reviews: [ProviderReview]
    let availability: [ProviderAvailability]

    init(
        id: String,
        displayName: String,
        rating: Double,
        hourlyRate: Int,
        payoutStatus: String,
        educationLevel: String,
        about: String,
        experience: String,
        experienceYears: Int,
        age: Int,
        completedSittings: Int,
        locationName: String,
        distanceText: String,
        photoURL: String?,
        latitude: Double?,
        longitude: Double?,
        skills: [String],
        reviews: [ProviderReview],
        availability: [ProviderAvailability]
    ) {
        self.id = id
        self.displayName = displayName
        self.rating = rating
        self.hourlyRate = hourlyRate
        self.payoutStatus = payoutStatus
        self.educationLevel = educationLevel
        self.about = about
        self.experience = experience
        self.experienceYears = experienceYears
        self.age = age
        self.completedSittings = completedSittings
        self.locationName = locationName
        self.distanceText = distanceText
        self.photoURL = photoURL
        self.latitude = latitude
        self.longitude = longitude
        self.skills = skills
        self.reviews = reviews
        self.availability = availability
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case rating
        case hourlyRate
        case payoutStatus
        case educationLevel
        case about
        case experience
        case experienceYears
        case age
        case completedSittings
        case locationName
        case distanceText
        case photoURL = "photoUrl"
        case latitude
        case longitude
        case skills
        case reviews
        case availability
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            displayName: try container.decodeIfPresent(String.self, forKey: .displayName) ?? "Bakici",
            rating: try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0,
            hourlyRate: try container.decodeIfPresent(Int.self, forKey: .hourlyRate) ?? 600,
            payoutStatus: try container.decodeIfPresent(String.self, forKey: .payoutStatus) ?? "PENDING",
            educationLevel: try container.decodeIfPresent(String.self, forKey: .educationLevel) ?? "",
            about: try container.decodeIfPresent(String.self, forKey: .about) ?? "",
            experience: try container.decodeIfPresent(String.self, forKey: .experience) ?? "",
            experienceYears: try container.decodeIfPresent(Int.self, forKey: .experienceYears) ?? 0,
            age: try container.decodeIfPresent(Int.self, forKey: .age) ?? 0,
            completedSittings: try container.decodeIfPresent(Int.self, forKey: .completedSittings) ?? 0,
            locationName: try container.decodeIfPresent(String.self, forKey: .locationName) ?? "Konum bilgisi yakinda",
            distanceText: try container.decodeIfPresent(String.self, forKey: .distanceText) ?? "",
            photoURL: try container.decodeIfPresent(String.self, forKey: .photoURL),
            latitude: try container.decodeIfPresent(Double.self, forKey: .latitude),
            longitude: try container.decodeIfPresent(Double.self, forKey: .longitude),
            skills: ProviderCategoryMapper.displayLabels(from: try container.decodeIfPresent([String].self, forKey: .skills) ?? []),
            reviews: try container.decodeIfPresent([ProviderReview].self, forKey: .reviews) ?? [],
            availability: try container.decodeIfPresent([ProviderAvailability].self, forKey: .availability) ?? []
        )
    }
}

struct ProviderReview: Codable, Identifiable {
    let id: String
    let authorName: String
    let rating: Int
    let comment: String
    let createdAt: String
}

struct ProviderAvailability: Codable, Identifiable {
    var id: String { date }
    let date: String
    let status: String
}
