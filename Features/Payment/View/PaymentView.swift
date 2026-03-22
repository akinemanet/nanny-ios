//
//  PaymentView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct PaymentView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferencePreferredCurrency") private var preferredCurrency = "TRY"
    @State private var paymentMethods: [PaymentMethodItem] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ödeme Özeti")
                                .font(.headline)
                            Text("Ödemeler, rezervasyon onayından sonra oluşturulur.")
                                .foregroundStyle(.secondary)
                            Text("Tercih edilen para birimi: \(preferredCurrency) \(CurrencyFormatting.symbol(for: preferredCurrency))")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DS.Colors.primary)
                            Text("Kayıtlı yöntemlerin aşağıda görünür ve ödeme sırasında tekrar kullanılabilir.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kayıtlı Yöntemler")
                            .font(.headline)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        } else if paymentMethods.isEmpty {
                            AppCard {
                                Text("Henüz ödeme yöntemi yok.")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(paymentMethods) { method in
                                AppCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(method.brand)
                                                .font(.headline)
                                            Text("**** \(method.last4)")
                                                .foregroundStyle(.secondary)
                                            Text("\(method.holderName) • \(String(format: "%02d", method.expMonth))/\(method.expYear)")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if method.isDefault {
                                            Text("Varsayılan")
                                                .font(.caption.bold())
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(DS.Colors.primary.opacity(0.15))
                                                .foregroundStyle(DS.Colors.primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    AppCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Sonraki Adım")
                                .font(.headline)
                            Text("Bu ödeme yöntemlerini kullanmak için bekleyen bir rezervasyonu açıp ödeme adımına devam et.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(24)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("Ödeme")
            .task {
                await loadPaymentMethods()
            }
            .refreshable {
                await loadPaymentMethods()
            }
        }
    }

    private func loadPaymentMethods() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            paymentMethods = try await session.deps.paymentService.listPaymentMethods().paymentMethods
        } catch {
            paymentMethods = []
            errorMessage = error.localizedDescription
        }
    }
}
