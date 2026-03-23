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
    struct PendingUpload {
        let fileName: String
        let mimeType: String
        let data: Data
    }

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
    @Published var profilePhotoURL = ""
    @Published var criminalRecordFileName = ""
    @Published var criminalRecordURL = ""

    @Published var isLoading = false
    @Published var message: String?
    @Published var errorMessage: String?

    private let service: ProviderService
    private(set) var pendingProfilePhotoUpload: PendingUpload?
    private(set) var pendingCriminalRecordUpload: PendingUpload?

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
            selectedCategories = ProviderCategoryMapper.displayLabels(from: summary.profile.categories)
            profilePhotoName = summary.profile.profilePhotoName
            profilePhotoURL = summary.profile.profilePhotoUrl
            criminalRecordFileName = summary.profile.criminalRecordFileName
            criminalRecordURL = summary.profile.criminalRecordUrl
            pendingProfilePhotoUpload = nil
            pendingCriminalRecordUpload = nil
        } catch {
            errorMessage = "Kayıt bilgileri şu anda alınamadı. Formu doldurup tekrar deneyebilirsin."
        }
    }

    func setProfilePhoto(data: Data, fileName: String, mimeType: String) {
        pendingProfilePhotoUpload = PendingUpload(fileName: fileName, mimeType: mimeType, data: data)
        profilePhotoName = fileName
    }

    func setCriminalRecord(data: Data, fileName: String, mimeType: String) {
        pendingCriminalRecordUpload = PendingUpload(fileName: fileName, mimeType: mimeType, data: data)
        criminalRecordFileName = fileName
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

            let res = try await service.upsertPayoutAccount(req)
            account = res.account

            if let pendingProfilePhotoUpload {
                let uploaded = try await service.uploadDocument(
                    kind: .profilePhoto,
                    fileName: pendingProfilePhotoUpload.fileName,
                    data: pendingProfilePhotoUpload.data,
                    mimeType: pendingProfilePhotoUpload.mimeType
                )
                profilePhotoName = uploaded.profile?.profilePhotoName ?? profilePhotoName
                profilePhotoURL = uploaded.profile?.profilePhotoUrl ?? uploaded.url ?? profilePhotoURL
                self.pendingProfilePhotoUpload = nil
            }

            if let pendingCriminalRecordUpload {
                let uploaded = try await service.uploadDocument(
                    kind: .criminalRecord,
                    fileName: pendingCriminalRecordUpload.fileName,
                    data: pendingCriminalRecordUpload.data,
                    mimeType: pendingCriminalRecordUpload.mimeType
                )
                criminalRecordFileName = uploaded.profile?.criminalRecordFileName ?? criminalRecordFileName
                criminalRecordURL = uploaded.profile?.criminalRecordUrl ?? uploaded.url ?? criminalRecordURL
                self.pendingCriminalRecordUpload = nil
            }

            let profileReq = UpsertProviderOnboardingProfileRequest(
                educationLevel: educationLevel,
                about: about,
                categories: ProviderCategoryMapper.backendServices(from: selectedCategories),
                profilePhotoName: profilePhotoName,
                criminalRecordFileName: criminalRecordFileName
            )

            do {
                if let summary = try await service.upsertOnboardingProfile(profileReq) {
                    if let account = summary.account {
                        self.account = account
                    }
                    educationLevel = summary.profile.educationLevel
                    about = summary.profile.about
                    selectedCategories = ProviderCategoryMapper.displayLabels(from: summary.profile.categories)
                    profilePhotoName = summary.profile.profilePhotoName
                    profilePhotoURL = summary.profile.profilePhotoUrl
                    criminalRecordFileName = summary.profile.criminalRecordFileName
                    criminalRecordURL = summary.profile.criminalRecordUrl
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
            errorMessage = error.localizedDescription
            return false
        }
    }
}
