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
    @Published var account: ProviderAccount? = nil

    @Published var address = ""
    @Published var contactName = ""
    @Published var contactSurname = ""
    @Published var email = ""
    @Published var gsmNumber = ""
    @Published var storeName = ""
    @Published var iban = ""
    @Published var identityNumber = ""

    @Published var isLoading = false
    @Published var message: String? = nil
    @Published var errorMessage: String? = nil

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
            let res = try await service.getPayoutAccount()
            account = res.account
            if let acc = res.account {
                address = acc.address
                contactName = acc.contactName
                contactSurname = acc.contactSurname
                email = acc.email
                gsmNumber = acc.gsmNumber
                storeName = acc.name
                iban = acc.iban
                identityNumber = acc.identityNumber
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Payout account okunamadı"
        }
    }

    func save() async {
        isLoading = true
        defer { isLoading = false }
        message = nil
        errorMessage = nil

        // normalize
        let normEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normIBAN = normalizeIBAN(iban)
        let normTCKN = onlyDigits(identityNumber, max: 11)
        let normGSM = normalizePhone(gsmNumber)

        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !contactSurname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !normEmail.isEmpty,
              !normGSM.isEmpty,
              !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !normIBAN.isEmpty,
              !normTCKN.isEmpty else {
            errorMessage = "Lütfen tüm alanları doldur."
            return
        }

        let req = UpsertPayoutAccountRequest(
            address: address,
            contactName: contactName,
            contactSurname: contactSurname,
            email: normEmail,
            gsmNumber: normGSM,
            name: storeName,
            iban: normIBAN,
            identityNumber: normTCKN
        )

        do {
            let res = try await service.upsertPayoutAccount(req)
            account = res.account
            // kaydetten sonra formu normalize edilmiş hale çek
            email = normEmail
            iban = prettyIBAN(normIBAN)
            identityNumber = normTCKN
            gsmNumber = normGSM
            message = "Kaydedildi ✅"
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Kaydetme başarısız"
        }
    }

    // MARK: - Helpers

    private func onlyDigits(_ s: String, max: Int) -> String {
        let digits = s.filter { $0.isNumber }
        return String(digits.prefix(max))
    }

    private func normalizeIBAN(_ s: String) -> String {
        let up = s.uppercased()
        let cleaned = up.filter { $0.isNumber || ($0 >= "A" && $0 <= "Z") }
        return cleaned
    }

    func prettyIBAN(_ iban: String) -> String {
        let clean = normalizeIBAN(iban)
        return stride(from: 0, to: clean.count, by: 4).map { i in
            let start = clean.index(clean.startIndex, offsetBy: i)
            let end = clean.index(start, offsetBy: min(4, clean.count - i))
            return String(clean[start..<end])
        }.joined(separator: " ")
    }

    private func normalizePhone(_ s: String) -> String {
        // + ve rakam kalsın, diğerleri gitsin
        var cleaned = s.filter { $0.isNumber || $0 == "+" }
        // başta + yoksa ekleme yapma zorunlu değil ama TR için genelde +90
        // İstersen burada otomatik +90 ekleyebiliriz.
        // örnek: 0555... -> +90555...
        if cleaned.hasPrefix("0"), cleaned.count >= 10 {
            cleaned.removeFirst()
            cleaned = "+90" + cleaned
        }
        return cleaned
    }
}
