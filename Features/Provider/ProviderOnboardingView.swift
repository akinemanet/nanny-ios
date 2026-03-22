//
//  ProviderOnboardingView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI

struct ProviderOnboardingView: View {
    @StateObject private var vm: ProviderOnboardingViewModel

    init(service: ProviderService) {
        _vm = StateObject(wrappedValue: ProviderOnboardingViewModel(service: service))
    }

    var body: some View {
        Form {
            Section("Durum") {
                if let acc = vm.account {
                    StatusPill(status: acc.status)

                    LabeledContent("Currency", value: acc.currency)

                    if let key = acc.subMerchantKey, !key.isEmpty {
                        CopyRow(title: "Sub Merchant Key", value: key)
                    }

                    if let err = acc.lastError, !err.isEmpty {
                        CopyRow(title: "Last Error", value: err)
                    }
                } else {
                    Text("Henüz kayıt yok. Formu doldurup kaydedebilirsin.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("İletişim") {
                TextField("Adres", text: $vm.address)

                TextField("Ad", text: $vm.contactName)
                TextField("Soyad", text: $vm.contactSurname)

                TextField("E-posta", text: $vm.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                TextField("Telefon (gsm) ör: +90555...", text: $vm.gsmNumber)
                    .keyboardType(.phonePad)
                    .onChange(of: vm.gsmNumber) { _, newValue in
                        // sadece + ve rakam bırak
                        let filtered = newValue.filter { $0.isNumber || $0 == "+" }
                        if filtered != newValue { vm.gsmNumber = filtered }
                    }
            }

            Section("Hesap") {
                TextField("Mağaza/İşletme Adı", text: $vm.storeName)

                TextField("IBAN (TR..)", text: $vm.iban)
                    .textInputAutocapitalization(.characters)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .onChange(of: vm.iban) { _, newValue in
                        // harf/rakam dışında temizle + büyük harf
                        let up = newValue.uppercased()
                        let clean = up.filter { $0.isNumber || ($0 >= "A" && $0 <= "Z") }
                        let pretty = vm.prettyIBAN(clean)
                        if pretty != newValue { vm.iban = pretty }
                    }

                TextField("TCKN (11 hane)", text: $vm.identityNumber)
                    .keyboardType(.numberPad)
                    .onChange(of: vm.identityNumber) { _, newValue in
                        let digits = newValue.filter { $0.isNumber }
                        let limited = String(digits.prefix(11))
                        if limited != newValue { vm.identityNumber = limited }
                    }
            }

            if let msg = vm.message {
                Section { Text(msg).foregroundStyle(.green) }
            }
            if let err = vm.errorMessage {
                Section { Text(err).foregroundStyle(.red) }
            }

            Section {
                Button {
                    Task { await vm.save() }
                } label: {
                    HStack { Spacer(); Text("Kaydet / Güncelle"); Spacer() }
                }
                .disabled(vm.isLoading)

                Button {
                    Task { await vm.load() }
                } label: {
                    HStack { Spacer(); Text("Yenile"); Spacer() }
                }
                .disabled(vm.isLoading)
            }
        }
        .navigationTitle("Provider Onboarding")
        .overlay {
            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .task { await vm.load() }
    }
}
