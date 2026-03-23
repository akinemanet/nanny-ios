//
//  ProviderOnboardingViewModel.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation
import Combine

@MainActor
final class ProviderOnboardingViewModel: ObservableObject {
    @Published var account: ProviderAccount?

    @Published var address = ""
    @Published var contactName = ""
    @Published var contactSurname = ""
    @Published var email = ""
    @Published var gsmNumber = ""
    @Published var storeName = ""
    @Published var iban = ""
    @Published var identityNumber = ""
    @Published var educationLevel = ""
    @Published var about = ""
    @Published var selectedCategories: [String] = []
    @Published var profilePhotoName = ""
    @Published var criminalRecordFileName = ""

    @Published var isLoading = false
    @Published var message: String?
    @Published var errorMessage: String?

    private let service: ProviderService

    init(service: ProviderService) {
        self.service = service
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        message = nil
        errorMessage = nil

        do {
            let summary = try await service.getOnboardingSummary()
            account = summary.account
            if let acc = summary.account {
                address = acc.address
                contactName = acc.contactName
                contactSurname = acc.contactSurname
                email = acc.email
                gsmNumber = acc.gsmNumber
                storeName = acc.name
                iban = acc.iban
                identityNumber = acc.identityNumber
            }
            educationLevel = summary.profile.educationLevel
            about = summary.profile.about
            selectedCategories = summary.profile.categories
            profilePhotoName = summary.profile.profilePhotoName
            criminalRecordFileName = summary.profile.criminalRecordFileName
        } catch {
            errorMessage = "Kayıt bilgileri şu anda alınamadı. Formu doldurup tekrar deneyebilirsin."
        }
    }

    @discardableResult
    func save() async -> Bool {
        errorMessage = nil
        message = nil

        guard !profilePhotoName.isEmpty else {
            errorMessage = "Lütfen profil fotoğrafı ekle."
            return false
        }

        guard !educationLevel.isEmpty else {
            errorMessage = "Lütfen eğitim durumunu seç."
            return false
        }

        guard !about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Lütfen hakkında alanını doldur."
            return false
        }

        guard !selectedCategories.isEmpty else {
            errorMessage = "Lütfen en az bir kategori seç."
            return false
        }

        guard !criminalRecordFileName.isEmpty else {
            errorMessage = "Lütfen PDF sabıka kaydını ekle."
            return false
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let req = UpsertPayoutAccountRequest(
                address: address,
                contactName: contactName,
                contactSurname: contactSurname,
                email: email,
                gsmNumber: gsmNumber,
                name: storeName,
                iban: iban.replacingOccurrences(of: " ", with: ""),
                identityNumber: identityNumber
            )
            let profileReq = UpsertProviderOnboardingProfileRequest(
                educationLevel: educationLevel,
                about: about,
                categories: selectedCategories,
                profilePhotoName: profilePhotoName,
                criminalRecordFileName: criminalRecordFileName
            )

            let res = try await service.upsertPayoutAccount(req)
            account = res.account
            do {
                if let summary = try await service.upsertOnboardingProfile(profileReq) {
                    if let account = summary.account {
                        self.account = account
                    }
                    educationLevel = summary.profile.educationLevel
                    about = summary.profile.about
                    selectedCategories = summary.profile.categories
                    profilePhotoName = summary.profile.profilePhotoName
                    criminalRecordFileName = summary.profile.criminalRecordFileName
                    message = "Kaydedildi ve onboarding profili backend ile eszamanlandi."
                } else {
                    message = "Kaydedildi. Onboarding profil endpoint'i hazir oldugunda ek alanlar da backend'e tasinacak."
                }
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
                        message = "Kaydedildi. Onboarding profil endpoint'i hazir degil; ek alanlar simdilik cihaz tarafinda tutuluyor."
                    } else {
                        throw error
                    }
                default:
                    throw error
                }
            }
            return true
        } catch {
            errorMessage = "Bilgiler şu anda kaydedilemedi. Lütfen alanları kontrol edip tekrar dene."
            return false
        }
    }
}
