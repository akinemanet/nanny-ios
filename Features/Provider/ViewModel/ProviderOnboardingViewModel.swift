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
    @Published var experience = ""
    @Published var selectedCategories: [String] = []
    @Published var age = ""
    @Published var hourlyRate = ""
    @Published var dailyRate = ""
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
            experience = summary.profile.experience
            selectedCategories = ProviderCategoryMapper.displayLabels(from: summary.profile.categories)
            age = summary.profile.age.map(String.init) ?? age
            hourlyRate = summary.profile.hourlyRate.map(String.init) ?? hourlyRate
            dailyRate = summary.profile.dailyRate.map(String.init) ?? dailyRate
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

        guard !experience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Lütfen deneyim alanını doldur."
            return false
        }

        guard !selectedCategories.isEmpty else {
            errorMessage = "Lütfen en az bir kategori seç."
            return false
        }

        guard let parsedAge = Int(age.trimmingCharacters(in: .whitespacesAndNewlines)), parsedAge >= 18 else {
            errorMessage = "Lütfen geçerli bir yaş gir."
            return false
        }

        guard let parsedHourlyRate = Int(hourlyRate.trimmingCharacters(in: .whitespacesAndNewlines)),
              parsedHourlyRate >= 100 else {
            errorMessage = "Lütfen geçerli bir saatlik ücret gir."
            return false
        }

        guard let parsedDailyRate = Int(dailyRate.trimmingCharacters(in: .whitespacesAndNewlines)),
              parsedDailyRate >= parsedHourlyRate else {
            errorMessage = "Lütfen geçerli bir günlük ücret gir."
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

            let fullName = [contactName, contactSurname]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            let profileReq = UpsertProviderProfileRequest(
                fullName: fullName,
                educationLevel: educationLevel,
                about: about,
                experience: experience,
                categories: ProviderCategoryMapper.backendServices(from: selectedCategories),
                age: parsedAge,
                hourlyRate: parsedHourlyRate,
                dailyRate: parsedDailyRate,
                profilePhotoName: profilePhotoName,
                criminalRecordFileName: criminalRecordFileName
            )

            do {
                let response = try await service.upsertProviderProfile(profileReq)
                if let summary = response.summary {
                    if let account = summary.account {
                        self.account = account
                    }
                    educationLevel = summary.profile.educationLevel
                    about = summary.profile.about
                    experience = summary.profile.experience
                    selectedCategories = ProviderCategoryMapper.displayLabels(from: summary.profile.categories)
                    age = response.profile?.age.map(String.init) ?? summary.profile.age.map(String.init) ?? String(parsedAge)
                    hourlyRate = response.profile?.hourlyRate.map(String.init) ?? String(parsedHourlyRate)
                    dailyRate = response.profile?.dailyRate.map(String.init) ?? String(parsedDailyRate)
                    profilePhotoName = summary.profile.profilePhotoName
                    profilePhotoURL = summary.profile.profilePhotoUrl
                    criminalRecordFileName = summary.profile.criminalRecordFileName
                    criminalRecordURL = summary.profile.criminalRecordUrl
                    message = "Kaydedildi ve bakıcı profili backend ile eşzamanlandı."
                } else {
                    age = response.profile?.age.map(String.init) ?? String(parsedAge)
                    hourlyRate = response.profile?.hourlyRate.map(String.init) ?? String(parsedHourlyRate)
                    dailyRate = response.profile?.dailyRate.map(String.init) ?? String(parsedDailyRate)
                    message = "Kaydedildi ve fiyat bilgisi güncellendi."
                }
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
                        message = "Kaydedildi. Profil endpoint'i hazır değil; fiyat ve ek alanlar simdilik cihazda tutuluyor."
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
