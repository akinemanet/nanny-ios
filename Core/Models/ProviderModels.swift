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
    let categories: [String]
    let profilePhotoName: String
    let criminalRecordFileName: String

    init(
        educationLevel: String = "",
        about: String = "",
        categories: [String] = [],
        profilePhotoName: String = "",
        criminalRecordFileName: String = ""
    ) {
        self.educationLevel = educationLevel
        self.about = about
        self.categories = categories
        self.profilePhotoName = profilePhotoName
        self.criminalRecordFileName = criminalRecordFileName
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
struct BrowseProvider: Codable, Identifiable {
    let id: String
    let displayName: String
    let rating: Double
    let hourlyRate: Int
    let payoutStatus: String
    let age: Int
    let gender: String
    let locationName: String
    let distanceText: String
    let latitude: Double?
    let longitude: Double?
    let categories: [String]
    let reviewCount: Int
    let completedSittings: Int
    let availableDates: [String]
    let availableStartHour: Int
    let availableEndHour: Int
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
    let experienceYears: Int
    let age: Int
    let completedSittings: Int
    let locationName: String
    let distanceText: String
    let latitude: Double?
    let longitude: Double?
    let skills: [String]
    let reviews: [ProviderReview]
    let availability: [ProviderAvailability]
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
