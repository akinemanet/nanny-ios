//
//  BookingCalendarView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BookingCalendarView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferencePreferredCurrency") private var preferredCurrency = "TRY"
    @AppStorage(StoredLocationKeys.latitude) private var selectedLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var selectedLongitude = StoredLocation.fallback.longitude
    let provider: BrowseProvider

    @State private var selectedDate = Date()
    @State private var selectedTime = ""
    @State private var showReview = false

    private let times = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DatePicker("Tarih Seç", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                Divider()
                Text("Uygun Saatler").font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(times, id: \.self) { time in
                        TimeSlotView(
                            time: time,
                            isSelected: selectedTime == time
                        ) {
                            selectedTime = time
                        }
                    }
                }

                Button {
                    showReview = true
                } label: {
                    Text("Rezervasyonu Onayla")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedTime.isEmpty)
            }
            .padding()
            .padding(.bottom, 120)
        }
        .navigationTitle(provider.displayName)
        .navigationDestination(isPresented: $showReview) {
            ReviewBookingView(
                provider: provider,
                selectedDate: selectedDate,
                selectedTime: selectedTime,
                selectedLatitude: selectedLatitude,
                selectedLongitude: selectedLongitude,
                bookingService: session.deps.bookingService,
                preferredCurrency: preferredCurrency
            )
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 92)
        }
    }
}

private struct ReviewBookingView: View {
    @AppStorage("accountProfileDisplayName") private var familyDisplayName = ""
    @AppStorage("accountProfileEmail") private var familyEmail = ""
    @AppStorage("accountProfileAboutFamily") private var familyAbout = ""
    @AppStorage(StoredLocationKeys.name) private var familyLocationName = StoredLocation.fallback.name
    let provider: BrowseProvider
    let selectedDate: Date
    let selectedTime: String
    let selectedLatitude: Double
    let selectedLongitude: Double
    let bookingService: BookingService
    let preferredCurrency: String

    @StateObject private var bookingVM: BookingViewModel
    @State private var showSuccess = false

    init(
        provider: BrowseProvider,
        selectedDate: Date,
        selectedTime: String,
        selectedLatitude: Double,
        selectedLongitude: Double,
        bookingService: BookingService,
        preferredCurrency: String
    ) {
        self.provider = provider
        self.selectedDate = selectedDate
        self.selectedTime = selectedTime
        self.selectedLatitude = selectedLatitude
        self.selectedLongitude = selectedLongitude
        self.bookingService = bookingService
        self.preferredCurrency = preferredCurrency
        _bookingVM = StateObject(wrappedValue: BookingViewModel(service: bookingService))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            detailBlock("Tarih ve Saat", value: formattedDate, subtitle: selectedTime + " - " + endTime)
            detailBlock("Bakıcı", value: provider.displayName, subtitle: "Müsait")
            detailBlock("Adres", value: provider.locationName, subtitle: resolvedDistanceText)
            detailBlock(
                "Aile Profili",
                value: resolvedFamilyName,
                subtitle: familyProfileSubtitle
            )
            detailBlock("Ödeme Yöntemi", value: "Apple Pay", subtitle: "Kayıtlı ödeme yöntemi")

            VStack(alignment: .leading, spacing: 8) {
                Text("Fiyat")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatting.formattedHourlyRate(provider.hourlyRate, currencyCode: preferredCurrency))
                    .font(.headline)
                Text("Toplam \(CurrencyFormatting.formattedAmount(provider.hourlyRate, currencyCode: preferredCurrency))")
                    .font(.headline.bold())
            }

            if let error = bookingVM.error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                Task {
                    await bookingVM.book(
                        providerId: provider.id,
                        date: selectedDate,
                        time: selectedTime,
                        familyDisplayName: familyDisplayName.isEmpty ? nil : familyDisplayName,
                        familyAbout: familyAbout.isEmpty ? nil : familyAbout,
                        familyLocationName: familyLocationName,
                        familyLocationLatitude: selectedLatitude,
                        familyLocationLongitude: selectedLongitude
                    )
                    if bookingVM.success {
                        showSuccess = true
                    }
                }
            } label: {
                Text(bookingVM.isLoading ? "Onaylanıyor..." : "Onayla")
                    .frame(maxWidth: .infinity)
                    .frame(height: DS.Size.buttonHeight)
                    .background(DS.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            }
            .disabled(bookingVM.isLoading)
        }
        .padding()
        .navigationTitle("Rezervasyonu Gözden Geçir")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSuccess) {
            BookingSuccessView(
                provider: provider,
                booking: bookingVM.createdBooking
            )
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 92)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    private var endTime: String {
        let parts = selectedTime.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]) else { return selectedTime }
        return String(format: "%02d:%@", hour + 1, String(parts[1]))
    }

    private var resolvedDistanceText: String {
        StoredLocation.distanceText(
            from: selectedLatitude,
            originLongitude: selectedLongitude,
            to: provider.latitude,
            destinationLongitude: provider.longitude,
            fallback: provider.distanceText
        )
    }

    private var resolvedFamilyName: String {
        if !familyDisplayName.isEmpty { return familyDisplayName }
        if !familyEmail.isEmpty { return familyEmail }
        return "Aile Profili"
    }

    private var familyProfileSubtitle: String {
        let description = familyAbout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            return description
        }
        return familyLocationName
    }

    private func detailBlock(_ title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct BookingSuccessView: View {
    @EnvironmentObject private var session: SessionStore
    let provider: BrowseProvider
    let booking: BookingRecord?
    @State private var checkoutURL: URL?
    @State private var checkoutError: String?
    @State private var isLoadingCheckout = false
    @State private var showCheckout = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 86))
                .foregroundStyle(.orange)
            Text("Tebrikler")
                .font(.largeTitle.bold())
            Text("Hizmetimizi tercih ettiğiniz ve çocuklarınızı bakıcılarımıza emanet ettiğiniz için teşekkür ederiz")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text(provider.displayName)
                    .font(.headline)
                if let booking {
                    Text("Rezervasyon No: \(booking.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(serviceText(booking.service)) • \(bookingStatusText(booking.status))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if let checkoutError {
                Text(checkoutError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Spacer()
            Button {
                Task { await openCheckout() }
            } label: {
                if isLoadingCheckout {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.Size.buttonHeight)
                } else {
                    Text("Ödemeye Devam Et")
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.Size.buttonHeight)
                }
            }
            .background(DS.Colors.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            .disabled(booking == nil || isLoadingCheckout)
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 92)
        }
        .sheet(isPresented: $showCheckout) {
            NavigationStack {
                if let checkoutURL {
                    CheckoutView(url: checkoutURL) { completion in
                        if completion == .success || completion == .cancelled {
                            showCheckout = false
                        }
                    }
                        .navigationTitle("Ödeme")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private func openCheckout() async {
        guard let booking else {
            checkoutError = "Rezervasyon verisi eksik."
            return
        }

        isLoadingCheckout = true
        checkoutError = nil
        defer { isLoadingCheckout = false }

        do {
            let urlString = try await session.deps.paymentService.checkout(bookingID: booking.id)
            guard let url = URL(string: urlString) else {
                checkoutError = "Ödeme bağlantısı geçersiz."
                return
            }
            checkoutURL = url
            showCheckout = true
        } catch {
            let message = error.localizedDescription
            if message.localizedCaseInsensitiveContains("iyzico keys not configured") {
                checkoutError = "Ödeme şu anda kullanılamıyor. Ödeme sağlayıcısı henüz backend tarafında yapılandırılmamış."
            } else if message.localizedCaseInsensitiveContains("http 500") {
                checkoutError = "Ödeme bağlantısı şu anda oluşturulamıyor. Lütfen daha sonra tekrar dene."
            } else {
                checkoutError = "Ödeme bağlantısı oluşturulamadı."
            }
        }
    }

    private func serviceText(_ value: String) -> String {
        switch value.uppercased() {
        case "BABYSITTER":
            return "Bakıcı"
        default:
            return value.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func bookingStatusText(_ value: String) -> String {
        switch value.uppercased() {
        case "REQUESTED":
            return "Talep Edildi"
        case "ACCEPTED":
            return "Kabul Edildi"
        case "CONFIRMED":
            return "Onaylandı"
        case "COMPLETED":
            return "Tamamlandı"
        case "CANCELED":
            return "İptal Edildi"
        default:
            return value
        }
    }
}
