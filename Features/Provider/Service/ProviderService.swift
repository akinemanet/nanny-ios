//
//  ProviderService.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation

final class ProviderService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func listProviders() async throws -> ProvidersResponse {
        struct Empty: Encodable {}
        do {
            let response: ProvidersResponse = try await api.request(
                "v1/providers",
                method: "GET",
                body: Optional<Empty>.none,
                needsAuth: false,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            if response.providers.isEmpty {
                return ProvidersResponse(providers: Self.seedProfiles.enumerated().map { index, seed in
                    makeBrowseProvider(
                        id: "seed-provider-\(index)",
                        payoutStatus: "APPROVED",
                        seed: seed
                    )
                })
            }
            return ProvidersResponse(providers: response.providers.map(normalizeBrowseProvider))
        } catch {
            return ProvidersResponse(providers: Self.seedProfiles.enumerated().map { index, seed in
                makeBrowseProvider(
                    id: "seed-provider-\(index)",
                    payoutStatus: "APPROVED",
                    seed: seed
                )
            })
        }
    }

    func getProviderDetail(id: String) async throws -> ProviderDetailResponse {
        struct Empty: Encodable {}

        do {
            let response: ProviderDetailResponse = try await api.request(
                "v1/providers/\(id)",
                method: "GET",
                body: Optional<Empty>.none,
                needsAuth: false,
                cachePolicy: .reloadIgnoringLocalCacheData
            )
            return ProviderDetailResponse(provider: normalizeProviderDetail(response.provider))
        } catch {
            let seed = Self.seedProfiles.first!
            return ProviderDetailResponse(
                provider: ProviderDetail(
                    id: id,
                    displayName: seed.displayName,
                    rating: seed.rating,
                    hourlyRate: seed.hourlyRate,
                    payoutStatus: "APPROVED",
                    educationLevel: seed.educationLevel,
                    about: seed.about,
                    experienceYears: seed.experienceYears,
                    age: seed.age,
                    completedSittings: seed.completedSittings,
                    locationName: seed.locationName,
                    distanceText: seed.distanceText,
                    latitude: seed.latitude,
                    longitude: seed.longitude,
                    skills: seed.skills,
                    reviews: seed.reviews,
                    availability: seed.availability
                )
            )
        }
    }

    func listFavorites() async throws -> FavoritesResponse {
        struct Empty: Encodable {}
        return try await api.request("v1/favorites", method: "GET", body: Optional<Empty>.none, needsAuth: true)
    }

    func addFavorite(providerID: String) async throws {
        struct Empty: Encodable {}
        let _: FavoriteMutationResponse = try await api.request(
            "v1/favorites/\(providerID)",
            method: "POST",
            body: Empty(),
            needsAuth: true
        )
    }

    func removeFavorite(providerID: String) async throws {
        struct Empty: Encodable {}
        let _: FavoriteMutationResponse = try await api.request(
            "v1/favorites/\(providerID)",
            method: "DELETE",
            body: Optional<Empty>.none,
            needsAuth: true
        )
    }

    func getPayoutAccount() async throws -> PayoutAccountResponse {
        struct Empty: Encodable {}
        return try await api.request("v1/providers/payout-account", method: "GET", body: Optional<Empty>.none, needsAuth: true)
    }

    func getOnboardingSummary() async throws -> ProviderOnboardingSummary {
        struct Empty: Encodable {}
        var lastError: Error?

        for candidate in ProviderOnboardingSummaryPlan.candidates() {
            do {
                if candidate.path == "v1/providers/payout-account" {
                    let response: PayoutAccountResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: Optional<Empty>.none,
                        needsAuth: true
                    )
                    return ProviderOnboardingSummary(account: response.account)
                }

                let response: ProviderOnboardingSummaryResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.summary
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
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

    func upsertPayoutAccount(_ req: UpsertPayoutAccountRequest) async throws -> PayoutAccountResponse {
        try await api.request("v1/providers/payout-account", method: "POST", body: req, needsAuth: true)
    }

    func upsertOnboardingProfile(_ req: UpsertProviderOnboardingProfileRequest) async throws -> ProviderOnboardingSummary? {
        struct EmptyMutationResponse: Decodable {}
        var lastError: Error?

        for candidate in ProviderOnboardingMutationPlan.saveProfileCandidates() {
            do {
                if candidate.path.contains("summary") {
                    let response: ProviderOnboardingSummaryResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: req,
                        needsAuth: true
                    )
                    return response.summary
                }

                let _: EmptyMutationResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: req,
                    needsAuth: true
                )
                return nil
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
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

    func upsertProviderProfile(_ req: UpsertProviderProfileRequest) async throws -> ProviderProfileMutationResponse {
        try await api.request("v1/providers/profile", method: "POST", body: req, needsAuth: true)
    }

    func uploadDocument(kind: ProviderDocumentKind, fileName: String, data: Data, mimeType: String) async throws -> ProviderDocumentUploadResponse {
        try await api.uploadMultipart(
            "v1/providers/documents/\(kind.rawValue)",
            method: "POST",
            file: APIClient.MultipartFile(
                fieldName: "file",
                fileName: fileName,
                mimeType: mimeType,
                data: data
            ),
            needsAuth: true
        )
    }

    private func makeBrowseProvider(id: String, payoutStatus: String, seed: SeededProviderProfile) -> BrowseProvider {
        return BrowseProvider(
            id: id,
            displayName: seed.displayName,
            rating: seed.rating,
            hourlyRate: seed.hourlyRate,
            payoutStatus: payoutStatus,
            age: seed.age,
            gender: seed.gender,
            locationName: seed.locationName,
            distanceText: seed.distanceText,
            latitude: seed.latitude,
            longitude: seed.longitude,
            categories: seed.categories,
            reviewCount: seed.reviews.count,
            completedSittings: seed.completedSittings,
            availableDates: seed.availability
                .filter { $0.status == "AVAILABLE" }
                .map(\.date),
            availableStartHour: seed.availableStartHour,
            availableEndHour: seed.availableEndHour
        )
    }

    private func normalizeBrowseProvider(_ provider: BrowseProvider) -> BrowseProvider {
        BrowseProvider(
            id: provider.id,
            displayName: provider.displayName,
            rating: provider.rating,
            hourlyRate: provider.hourlyRate,
            payoutStatus: provider.payoutStatus,
            age: provider.age,
            gender: provider.gender,
            locationName: provider.locationName,
            distanceText: provider.distanceText,
            latitude: provider.latitude,
            longitude: provider.longitude,
            categories: ProviderCategoryMapper.displayLabels(from: provider.categories),
            reviewCount: provider.reviewCount,
            completedSittings: provider.completedSittings,
            availableDates: provider.availableDates,
            availableStartHour: provider.availableStartHour,
            availableEndHour: provider.availableEndHour
        )
    }

    private func normalizeProviderDetail(_ provider: ProviderDetail) -> ProviderDetail {
        ProviderDetail(
            id: provider.id,
            displayName: provider.displayName,
            rating: provider.rating,
            hourlyRate: provider.hourlyRate,
            payoutStatus: provider.payoutStatus,
            educationLevel: provider.educationLevel,
            about: provider.about,
            experienceYears: provider.experienceYears,
            age: provider.age,
            completedSittings: provider.completedSittings,
            locationName: provider.locationName,
            distanceText: provider.distanceText,
            latitude: provider.latitude,
            longitude: provider.longitude,
            skills: ProviderCategoryMapper.displayLabels(from: provider.skills),
            reviews: provider.reviews,
            availability: provider.availability
        )
    }
}

private struct ProviderOnboardingSummaryResponse: Decodable {
    let summary: ProviderOnboardingSummary

    enum CodingKeys: String, CodingKey {
        case account
        case profile
        case onboarding
        case categories
        case educationLevel
        case about
        case profilePhotoName
        case profilePhotoUrl
        case criminalRecordFileName
        case criminalRecordUrl
        case profilePhotoStatus
        case criminalRecordStatus
        case approvalStatus
    }

    init(from decoder: Decoder) throws {
        if let nested = try? NestedSummary(from: decoder), let summary = nested.summary {
            self.summary = summary
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let profile = ProviderOnboardingProfile(
            educationLevel: try container.decodeIfPresent(String.self, forKey: .educationLevel) ?? "",
            about: try container.decodeIfPresent(String.self, forKey: .about) ?? "",
            categories: try container.decodeIfPresent([String].self, forKey: .categories) ?? [],
            profilePhotoName: try container.decodeIfPresent(String.self, forKey: .profilePhotoName) ?? "",
            profilePhotoUrl: try container.decodeIfPresent(String.self, forKey: .profilePhotoUrl) ?? "",
            criminalRecordFileName: try container.decodeIfPresent(String.self, forKey: .criminalRecordFileName) ?? "",
            criminalRecordUrl: try container.decodeIfPresent(String.self, forKey: .criminalRecordUrl) ?? "",
            profilePhotoStatus: try container.decodeIfPresent(String.self, forKey: .profilePhotoStatus) ?? "MISSING",
            criminalRecordStatus: try container.decodeIfPresent(String.self, forKey: .criminalRecordStatus) ?? "MISSING",
            approvalStatus: try container.decodeIfPresent(String.self, forKey: .approvalStatus) ?? "PENDING"
        )
        summary = ProviderOnboardingSummary(
            account: try container.decodeIfPresent(ProviderAccount.self, forKey: .account),
            profile: profile
        )
    }

    private struct NestedSummary: Decodable {
        let summary: ProviderOnboardingSummary?

        enum CodingKeys: String, CodingKey {
            case onboarding
            case profile
            case account
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let onboarding = try container.decodeIfPresent(ProviderOnboardingSummary.self, forKey: .onboarding) {
                summary = onboarding
                return
            }

            let profile = try container.decodeIfPresent(ProviderOnboardingProfile.self, forKey: .profile)
            let account = try container.decodeIfPresent(ProviderAccount.self, forKey: .account)

            if account != nil || profile != nil {
                summary = ProviderOnboardingSummary(
                    account: account,
                    profile: profile ?? ProviderOnboardingProfile()
                )
            } else {
                summary = nil
            }
        }
    }
}

private struct SeededProviderProfile {
    let displayName: String
    let rating: Double
    let hourlyRate: Int
    let age: Int
    let gender: String
    let experienceYears: Int
    let completedSittings: Int
    let locationName: String
    let distanceText: String
    let latitude: Double
    let longitude: Double
    let educationLevel: String
    let about: String
    let categories: [String]
    let skills: [String]
    let reviews: [ProviderReview]
    let availability: [ProviderAvailability]
    let availableStartHour: Int
    let availableEndHour: Int
}

private extension ProviderService {
    static let seedProfiles: [SeededProviderProfile] = [
        SeededProviderProfile(
            displayName: "Zeynep Kaya",
            rating: 4.9,
            hourlyRate: 650,
            age: 29,
            gender: "Kadın",
            experienceYears: 7,
            completedSittings: 84,
            locationName: "Kadikoy, Istanbul",
            distanceText: "2.1 km uzaklıkta",
            latitude: 40.9917,
            longitude: 29.0277,
            educationLevel: "Çocuk Gelişimi Lisans",
            about: "Çocuk gelişimi mezunuyum. Yenidoğan bakımından okul öncesi döneme kadar farklı yaş gruplarıyla deneyimim var. Güvenli rutin kurma, oyun temelli gelişim ve ailelerle düzenli iletişim konularında özenliyim.",
            categories: ["Bebek", "Okul Öncesi"],
            skills: ["Bebek Bakımı", "İlk Yardım", "Oyun Planı", "Uyku Rutini"],
            reviews: [
                ProviderReview(id: "r1", authorName: "Selin T.", rating: 5, comment: "Zeynep Hanım çok ilgili ve dakikti. Kızımız kısa sürede alıştı.", createdAt: "2026-03-01"),
                ProviderReview(id: "r2", authorName: "Mert A.", rating: 5, comment: "İletişimi güçlü, güven veren bir bakıcı.", createdAt: "2026-02-18")
            ],
            availability: [
                ProviderAvailability(date: "2026-03-15", status: "AVAILABLE"),
                ProviderAvailability(date: "2026-03-16", status: "AVAILABLE"),
                ProviderAvailability(date: "2026-03-17", status: "BOOKED")
            ],
            availableStartHour: 8,
            availableEndHour: 18
        ),
        SeededProviderProfile(
            displayName: "Elif Demir",
            rating: 4.8,
            hourlyRate: 600,
            age: 31,
            gender: "Kadın",
            experienceYears: 9,
            completedSittings: 112,
            locationName: "Besiktas, Istanbul",
            distanceText: "3.4 km uzaklıkta",
            latitude: 41.0430,
            longitude: 29.0094,
            educationLevel: "Okul Öncesi Öğretmenliği Lisans",
            about: "Okul öncesi öğretmenliği geçmişim var. Yaratıcı etkinlikler, yemek düzeni ve ekran süresi yönetimi konusunda sistemli çalışırım. Ailelerin günlük akışına kolay uyum sağlarım.",
            categories: ["Okul Öncesi", "Anaokulu"],
            skills: ["Okul Öncesi", "Ödev Desteği", "Yemek Hazırlığı", "Etkinlik"],
            reviews: [
                ProviderReview(id: "r3", authorName: "Derya K.", rating: 5, comment: "Planlı ve sıcak yaklaşımıyla çok memnun kaldık.", createdAt: "2026-01-22"),
                ProviderReview(id: "r4", authorName: "Can B.", rating: 4, comment: "Oğlumla iletişimi çok iyiydi.", createdAt: "2026-01-10")
            ],
            availability: [
                ProviderAvailability(date: "2026-03-15", status: "BOOKED"),
                ProviderAvailability(date: "2026-03-16", status: "AVAILABLE"),
                ProviderAvailability(date: "2026-03-17", status: "AVAILABLE")
            ],
            availableStartHour: 10,
            availableEndHour: 19
        ),
        SeededProviderProfile(
            displayName: "Merve Aydin",
            rating: 4.7,
            hourlyRate: 550,
            age: 27,
            gender: "Kadın",
            experienceYears: 5,
            completedSittings: 63,
            locationName: "Bornova, Izmir",
            distanceText: "1.7 km uzaklıkta",
            latitude: 38.4622,
            longitude: 27.2176,
            educationLevel: "Çocuk Gelişimi Ön Lisans",
            about: "Özellikle hareketli ve meraklı çocuklarla güçlü bağ kuruyorum. Açık hava etkinlikleri, ödev takibi ve günlük bakım rutinlerinde destek sağlıyorum.",
            categories: ["Yürümeye Başlayan", "İlkokul"],
            skills: ["Yürümeye Başlayan", "Açık Hava Etkinliği", "Ödev Desteği", "İletişim"],
            reviews: [
                ProviderReview(id: "r5", authorName: "Aylin G.", rating: 5, comment: "Enerjisi çok yüksek, oğlum Merve ablayı çok seviyor.", createdAt: "2026-02-03")
            ],
            availability: [
                ProviderAvailability(date: "2026-03-15", status: "AVAILABLE"),
                ProviderAvailability(date: "2026-03-16", status: "BOOKED"),
                ProviderAvailability(date: "2026-03-17", status: "AVAILABLE")
            ],
            availableStartHour: 9,
            availableEndHour: 17
        ),
        SeededProviderProfile(
            displayName: "Dilan Arslan",
            rating: 4.9,
            hourlyRate: 700,
            age: 34,
            gender: "Kadın",
            experienceYears: 11,
            completedSittings: 146,
            locationName: "Cankaya, Ankara",
            distanceText: "4.6 km uzaklıkta",
            latitude: 39.9179,
            longitude: 32.8627,
            educationLevel: "Çocuk Gelişimi Yüksek Lisans",
            about: "Uzun yıllardır tam zamanlı çocuk bakımında çalışıyorum. Kriz anlarında sakin kalırım; düzen, hijyen ve güvenlik konularında yüksek hassasiyet gösteririm.",
            categories: ["Bebek", "Gece Bakımı"],
            skills: ["Bebek Bakımı", "Gece Bakımı", "İlaç Takibi", "Hijyen"],
            reviews: [
                ProviderReview(id: "r6", authorName: "Yasemin O.", rating: 5, comment: "Çok profesyonel ve güvenilir.", createdAt: "2026-02-12"),
                ProviderReview(id: "r7", authorName: "Onur H.", rating: 5, comment: "Bebeğimiz için gönül rahatlığıyla destek aldık.", createdAt: "2026-01-28")
            ],
            availability: [
                ProviderAvailability(date: "2026-03-15", status: "BOOKED"),
                ProviderAvailability(date: "2026-03-16", status: "BOOKED"),
                ProviderAvailability(date: "2026-03-17", status: "AVAILABLE")
            ],
            availableStartHour: 18,
            availableEndHour: 23
        )
    ]
}
