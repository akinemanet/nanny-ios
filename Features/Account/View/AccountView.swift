//
//  AccountView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

private enum AccountPreferenceKeys {
    static let newsletter = "accountPreferenceNewsletter"
    static let textMessages = "accountPreferenceTextMessages"
    static let phoneCalls = "accountPreferencePhoneCalls"
    static let pushAlerts = "accountPreferencePushAlerts"
    static let marketingEmails = "accountPreferenceMarketingEmails"
    static let preferredLanguage = "accountPreferencePreferredLanguage"
    static let preferredCurrency = "accountPreferencePreferredCurrency"
    static let quietHoursEnabled = "accountPreferenceQuietHoursEnabled"
    static let quietHoursStart = "accountPreferenceQuietHoursStart"
    static let quietHoursEnd = "accountPreferenceQuietHoursEnd"
    static let bookingConfirmedNotifications = "accountPreferenceBookingConfirmedNotifications"
    static let bookingRejectedNotifications = "accountPreferenceBookingRejectedNotifications"
    static let bookingCompletedNotifications = "accountPreferenceBookingCompletedNotifications"
}

private enum AccountProfileKeys {
    static let displayName = "accountProfileDisplayName"
    static let email = "accountProfileEmail"
    static let aboutFamily = "accountProfileAboutFamily"
}

private final class AccountPreferenceService {
    private struct Empty: Encodable {}
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchPreferences() async throws -> NotificationPreferenceSnapshot? {
        var lastError: Error?

        for candidate in AccountSettingsSummaryPlan.fetchCandidates() {
            do {
                let response: PreferenceEnvelope = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.snapshot
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

        if let lastError { throw lastError }
        return nil
    }

    func savePreferences(_ snapshot: NotificationPreferenceSnapshot) async throws {
        var lastError: Error?
        let body = PreferenceUpdateRequest(snapshot: snapshot)

        for candidate in PreferenceSyncPlan.saveCandidates() {
            do {
                let _: PreferenceMutationResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: body,
                    needsAuth: true
                )
                return
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
}

private final class AccountProfileService {
    private struct Empty: Encodable {}
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchProfile() async throws -> AccountProfileSnapshot? {
        var lastError: Error?

        for candidate in AccountProfileSummaryPlan.fetchCandidates() {
            do {
                let response: AccountProfileEnvelope = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.snapshot
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

        if let lastError { throw lastError }
        return nil
    }

    func saveProfile(_ snapshot: AccountProfileSnapshot) async throws -> AccountProfileSnapshot? {
        var lastError: Error?
        let body = AccountProfileUpdateRequest(snapshot: snapshot)

        for candidate in AccountProfileMutationPlan.saveCandidates() {
            do {
                let response: AccountProfileMutationResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: body,
                    needsAuth: true
                )
                return response.snapshot
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
}

private struct PreferenceEnvelope: Decodable {
    let snapshot: NotificationPreferenceSnapshot?

    init(from decoder: Decoder) throws {
        if let nested = try? NestedPreferences(from: decoder), let nestedSnapshot = nested.snapshot {
            snapshot = nestedSnapshot
            return
        }

        snapshot = try NotificationPreferenceSnapshot(from: decoder)
    }

    private struct NestedPreferences: Decodable {
        let snapshot: NotificationPreferenceSnapshot?

        enum CodingKeys: String, CodingKey {
            case preferences
            case settings
            case summary
            case profileSummary
            case profile
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            snapshot =
                try container.decodeIfPresent(NotificationPreferenceSnapshot.self, forKey: .preferences)
                ?? container.decodeIfPresent(NotificationPreferenceSnapshot.self, forKey: .settings)
                ?? container.decodeIfPresent(NotificationPreferenceSnapshot.self, forKey: .summary)
                ?? container.decodeIfPresent(NotificationPreferenceSnapshot.self, forKey: .profileSummary)
                ?? container.decodeIfPresent(NotificationPreferenceSnapshot.self, forKey: .profile)
        }
    }
}

private struct AccountProfileEnvelope: Decodable {
    let snapshot: AccountProfileSnapshot?

    init(from decoder: Decoder) throws {
        if let nested = try? NestedProfile(from: decoder), let nestedSnapshot = nested.snapshot {
            snapshot = nestedSnapshot
            return
        }

        if let me = try? MeResponse(from: decoder) {
            snapshot = AccountProfileSnapshot(
                displayName: me.user.displayName ?? "",
                email: me.user.email ?? "",
                phone: me.user.phone,
                aboutFamily: ""
            )
            return
        }

        snapshot = try AccountProfileSnapshot(from: decoder)
    }

    private struct NestedProfile: Decodable {
        let snapshot: AccountProfileSnapshot?

        enum CodingKeys: String, CodingKey {
            case summary
            case profileSummary
            case profile
            case user
            case me
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            snapshot =
                try container.decodeIfPresent(AccountProfileSnapshot.self, forKey: .summary)
                ?? container.decodeIfPresent(AccountProfileSnapshot.self, forKey: .profileSummary)
                ?? container.decodeIfPresent(AccountProfileSnapshot.self, forKey: .profile)
                ?? container.decodeIfPresent(AccountProfileSnapshot.self, forKey: .user)
                ?? container.decodeIfPresent(AccountProfileSnapshot.self, forKey: .me)
        }
    }
}

private struct PreferenceUpdateRequest: Encodable {
    let newsletter: Bool
    let textMessages: Bool
    let phoneCalls: Bool
    let pushAlerts: Bool
    let marketingEmails: Bool
    let preferredLanguage: String
    let preferredCurrency: String
    let bookingConfirmedNotifications: Bool
    let bookingRejectedNotifications: Bool
    let bookingCompletedNotifications: Bool
    let quietHoursEnabled: Bool
    let quietHoursStart: String
    let quietHoursEnd: String
    let locationName: String
    let locationLatitude: Double
    let locationLongitude: Double

    init(snapshot: NotificationPreferenceSnapshot) {
        newsletter = snapshot.newsletter
        textMessages = snapshot.textMessages
        phoneCalls = snapshot.phoneCalls
        pushAlerts = snapshot.pushAlerts
        marketingEmails = snapshot.marketingEmails
        preferredLanguage = snapshot.preferredLanguage
        preferredCurrency = snapshot.preferredCurrency
        bookingConfirmedNotifications = snapshot.bookingConfirmed
        bookingRejectedNotifications = snapshot.bookingRejected
        bookingCompletedNotifications = snapshot.bookingCompleted
        quietHoursEnabled = snapshot.quietHoursEnabled
        quietHoursStart = snapshot.quietHoursStart
        quietHoursEnd = snapshot.quietHoursEnd
        locationName = snapshot.locationName
        locationLatitude = snapshot.locationLatitude
        locationLongitude = snapshot.locationLongitude
    }
}

private struct AccountProfileUpdateRequest: Encodable {
    let displayName: String
    let email: String
    let aboutFamily: String

    init(snapshot: AccountProfileSnapshot) {
        displayName = snapshot.displayName
        email = snapshot.email
        aboutFamily = snapshot.aboutFamily
    }
}

private struct PreferenceMutationResponse: Decodable {
    let ok: Bool?
}

private struct AccountProfileMutationResponse: Decodable {
    let ok: Bool?
    let snapshot: AccountProfileSnapshot?

    init(from decoder: Decoder) throws {
        if let nested = try? AccountProfileEnvelope(from: decoder) {
            snapshot = nested.snapshot
        } else {
            snapshot = nil
        }

        let container = try? decoder.container(keyedBy: CodingKeys.self)
        ok = try? container?.decodeIfPresent(Bool.self, forKey: .ok)
    }

    private enum CodingKeys: String, CodingKey {
        case ok
    }
}

private struct NotificationPreferenceSnapshot: Equatable, Decodable {
    let newsletter: Bool
    let textMessages: Bool
    let phoneCalls: Bool
    let pushAlerts: Bool
    let marketingEmails: Bool
    let preferredLanguage: String
    let preferredCurrency: String
    let bookingConfirmed: Bool
    let bookingRejected: Bool
    let bookingCompleted: Bool
    let quietHoursEnabled: Bool
    let quietHoursStart: String
    let quietHoursEnd: String
    let locationName: String
    let locationLatitude: Double
    let locationLongitude: Double

    private struct NestedLocation: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    enum CodingKeys: String, CodingKey {
        case newsletter
        case textMessages
        case phoneCalls
        case pushAlerts
        case marketingEmails
        case preferredLanguage
        case preferredCurrency
        case bookingConfirmed = "bookingConfirmedNotifications"
        case bookingRejected = "bookingRejectedNotifications"
        case bookingCompleted = "bookingCompletedNotifications"
        case quietHoursEnabled
        case quietHoursStart
        case quietHoursEnd
        case locationName
        case locationLatitude
        case locationLongitude
        case smsNotifications
        case callNotifications
        case marketingOptIn
        case language
        case currency
        case location
    }

    init(
        newsletter: Bool,
        textMessages: Bool,
        phoneCalls: Bool,
        pushAlerts: Bool,
        marketingEmails: Bool,
        preferredLanguage: String,
        preferredCurrency: String,
        bookingConfirmed: Bool,
        bookingRejected: Bool,
        bookingCompleted: Bool,
        quietHoursEnabled: Bool,
        quietHoursStart: String,
        quietHoursEnd: String,
        locationName: String,
        locationLatitude: Double,
        locationLongitude: Double
    ) {
        self.newsletter = newsletter
        self.textMessages = textMessages
        self.phoneCalls = phoneCalls
        self.pushAlerts = pushAlerts
        self.marketingEmails = marketingEmails
        self.preferredLanguage = preferredLanguage
        self.preferredCurrency = preferredCurrency
        self.bookingConfirmed = bookingConfirmed
        self.bookingRejected = bookingRejected
        self.bookingCompleted = bookingCompleted
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedLocation = try container.decodeIfPresent(NestedLocation.self, forKey: .location)
        newsletter = try container.decodeIfPresent(Bool.self, forKey: .newsletter) ?? true
        textMessages =
            try container.decodeIfPresent(Bool.self, forKey: .textMessages)
            ?? container.decodeIfPresent(Bool.self, forKey: .smsNotifications)
            ?? false
        phoneCalls =
            try container.decodeIfPresent(Bool.self, forKey: .phoneCalls)
            ?? container.decodeIfPresent(Bool.self, forKey: .callNotifications)
            ?? false
        pushAlerts = try container.decodeIfPresent(Bool.self, forKey: .pushAlerts) ?? true
        marketingEmails =
            try container.decodeIfPresent(Bool.self, forKey: .marketingEmails)
            ?? container.decodeIfPresent(Bool.self, forKey: .marketingOptIn)
            ?? false
        preferredLanguage =
            try container.decodeIfPresent(String.self, forKey: .preferredLanguage)
            ?? container.decodeIfPresent(String.self, forKey: .language)
            ?? "Turkce"
        preferredCurrency =
            try container.decodeIfPresent(String.self, forKey: .preferredCurrency)
            ?? container.decodeIfPresent(String.self, forKey: .currency)
            ?? "TRY"
        bookingConfirmed = try container.decodeIfPresent(Bool.self, forKey: .bookingConfirmed) ?? true
        bookingRejected = try container.decodeIfPresent(Bool.self, forKey: .bookingRejected) ?? true
        bookingCompleted = try container.decodeIfPresent(Bool.self, forKey: .bookingCompleted) ?? true
        quietHoursEnabled = try container.decodeIfPresent(Bool.self, forKey: .quietHoursEnabled) ?? false
        quietHoursStart = try container.decodeIfPresent(String.self, forKey: .quietHoursStart) ?? "22:00"
        quietHoursEnd = try container.decodeIfPresent(String.self, forKey: .quietHoursEnd) ?? "07:00"
        locationName =
            try container.decodeIfPresent(String.self, forKey: .locationName)
            ?? nestedLocation?.name
            ?? StoredLocation.fallback.name
        locationLatitude =
            try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
            ?? nestedLocation?.latitude
            ?? StoredLocation.fallback.latitude
        locationLongitude =
            try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
            ?? nestedLocation?.longitude
            ?? StoredLocation.fallback.longitude
    }
}

private struct AccountProfileSnapshot: Equatable, Decodable {
    let displayName: String
    let email: String
    let phone: String
    let aboutFamily: String

    enum CodingKeys: String, CodingKey {
        case displayName
        case fullName
        case name
        case email
        case phone
        case aboutFamily
        case bio
        case about
    }

    init(displayName: String, email: String, phone: String, aboutFamily: String) {
        self.displayName = displayName
        self.email = email
        self.phone = phone
        self.aboutFamily = aboutFamily
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayName =
            try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? container.decodeIfPresent(String.self, forKey: .fullName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        aboutFamily =
            try container.decodeIfPresent(String.self, forKey: .aboutFamily)
            ?? container.decodeIfPresent(String.self, forKey: .bio)
            ?? container.decodeIfPresent(String.self, forKey: .about)
            ?? ""
    }
}

private enum ProviderAssetKind {
    case profilePhoto
    case criminalRecord
}

private struct ProviderAssetStatusPresentation {
    let title: String
    let tint: Color
    let icon: String
}

struct AccountView: View {
    @EnvironmentObject var session: SessionStore
    @AppStorage(AccountPreferenceKeys.pushAlerts) private var pushAlerts = true
    @AppStorage(AccountPreferenceKeys.newsletter) private var newsletter = true
    @AppStorage(AccountPreferenceKeys.textMessages) private var textMessages = false
    @AppStorage(AccountPreferenceKeys.phoneCalls) private var phoneCalls = false
    @AppStorage(AccountPreferenceKeys.preferredLanguage) private var preferredLanguage = "Turkce"
    @AppStorage(AccountPreferenceKeys.preferredCurrency) private var preferredCurrency = "TRY"
    @AppStorage(AccountPreferenceKeys.quietHoursEnabled) private var quietHoursEnabled = false
    @AppStorage(AccountPreferenceKeys.quietHoursStart) private var quietHoursStart = "22:00"
    @AppStorage(AccountPreferenceKeys.quietHoursEnd) private var quietHoursEnd = "07:00"
    @AppStorage(AccountPreferenceKeys.bookingConfirmedNotifications) private var bookingConfirmedNotifications = true
    @AppStorage(AccountPreferenceKeys.bookingRejectedNotifications) private var bookingRejectedNotifications = true
    @AppStorage(AccountPreferenceKeys.bookingCompletedNotifications) private var bookingCompletedNotifications = true
    @AppStorage(AccountProfileKeys.displayName) private var profileDisplayName = ""
    @AppStorage(AccountProfileKeys.email) private var profileEmail = ""
    @AppStorage(AccountProfileKeys.aboutFamily) private var profileAboutFamily = ""
    @AppStorage(StoredLocationKeys.name) private var selectedLocationName = StoredLocation.fallback.name
    @AppStorage(StoredLocationKeys.latitude) private var selectedLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var selectedLongitude = StoredLocation.fallback.longitude
    @State private var showSettings = false
    @State private var showProfileEditor = false
    @State private var showProviderProfileEditor = false
    @State private var showProviderMediaEditor = false
    @State private var showAddCard = false
    @State private var showLocationPicker = false
    @State private var paymentMethods: [PaymentMethodItem] = []
    @State private var paymentMethodsError: String?
    @State private var profileService: AccountProfileService?
    @State private var profileSyncNotice: String?
    @State private var profileSyncError: String?
    @State private var didLoadRemoteProfile = false
    @State private var providerSummary: ProviderOnboardingSummary?
    @State private var providerAccount: ProviderAccount?
    @State private var providerProfileNotice: String?
    @State private var providerAccountError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Hesap")
                            .font(.largeTitle.bold())
                            .foregroundStyle(DS.Colors.textPrimary)
                        Spacer()
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.headline)
                                .foregroundStyle(DS.Colors.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                        }
                    }

                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 86, height: 86)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayTitle)
                                .font(.title2.bold())
                                .foregroundStyle(DS.Colors.textPrimary)
                            Text(displaySubtitle)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }

                        Spacer()
                    }

                    preferenceSummaryCard
                    profileSummaryCard

                    if isProvider {
                        providerOperationsCard
                    } else {
                        accountRow("Hesap Kredisi", trailing: "\(CurrencyFormatting.symbol(for: preferredCurrency))0,00")
                        NavigationLink {
                            FavoritesGridView()
                        } label: {
                            accountRow("Favoriler", trailing: "Tümünü gör")
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Adres")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        accountRow("Kayıtlı Konum", trailing: selectedLocationName)
                        accountRow(
                            "Koordinat",
                            trailing: StoredLocation.coordinateLabel(
                                latitude: selectedLatitude,
                                longitude: selectedLongitude
                            )
                        )
                        Button("Konumu güncelle") {
                            showLocationPicker = true
                        }
                        .foregroundStyle(DS.Colors.primary)
                    }

                    if !isProvider {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ödeme Kartları")
                                .font(.headline)
                                .foregroundStyle(DS.Colors.textPrimary)
                            if let paymentMethodsError {
                                Text(paymentMethodsError)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            } else if paymentMethods.isEmpty {
                                Text("Henüz ödeme yöntemi yok.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(paymentMethods) { method in
                                    accountRow(method.brand, trailing: "**** \(method.last4)")
                                }
                            }
                            Button {
                                showAddCard = true
                            } label: {
                                Text("Yeni kart ekle")
                                    .foregroundStyle(DS.Colors.primary)
                            }
                        }
                    }

                    NavigationLink("Push Hata Ayıklama") {
                        PushDebugView()
                    }
                    .foregroundStyle(DS.Colors.primary)

                    Button("Ayarlar") {
                        showSettings = true
                    }
                    .foregroundStyle(DS.Colors.primary)

                    Button("Çıkış Yap") {
                        session.logout()
                    }
                    .foregroundStyle(.red)
                }
                .padding()
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView(session: session)
                    .preferredColorScheme(.light)
                    .presentationBackground(DS.Colors.background)
            }
            .sheet(isPresented: $showProfileEditor) {
                NavigationStack {
                    ProfileEditView(
                        displayName: profileDisplayName.isEmpty ? displayTitle : profileDisplayName,
                        email: resolvedProfileEmail,
                        phone: resolvedProfilePhone,
                        aboutFamily: profileAboutFamily
                    ) { snapshot in
                        await saveProfile(snapshot)
                    }
                }
                .preferredColorScheme(.light)
                .presentationBackground(DS.Colors.background)
            }
            .sheet(isPresented: $showProviderProfileEditor) {
                NavigationStack {
                    ProviderProfileEditView(
                        account: providerAccount,
                        profile: providerSummary?.profile
                    ) { payload in
                        await saveProviderProfile(payload)
                    }
                }
                .preferredColorScheme(.light)
                .presentationBackground(DS.Colors.background)
            }
            .sheet(isPresented: $showProviderMediaEditor) {
                NavigationStack {
                    ProviderMediaEditView(
                        profilePhotoName: providerSummary?.profile.profilePhotoName ?? "",
                        criminalRecordFileName: providerSummary?.profile.criminalRecordFileName ?? ""
                    ) { payload in
                        await saveProviderMedia(payload)
                    }
                }
                .preferredColorScheme(.light)
                .presentationBackground(DS.Colors.background)
            }
            .sheet(isPresented: $showAddCard) {
                PaymentMethodCatalogView {
                    await loadPaymentMethods()
                }
                .preferredColorScheme(.light)
                .presentationBackground(DS.Colors.background)
            }
            .sheet(isPresented: $showLocationPicker) {
                NavigationStack {
                    MapSearchView(isSelectingLocation: true) { location in
                        selectedLocationName = location.name
                        selectedLatitude = location.latitude
                        selectedLongitude = location.longitude
                        showLocationPicker = false
                    }
                    .navigationTitle("Konum Sec")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .preferredColorScheme(.light)
                .presentationBackground(DS.Colors.background)
            }
            .task {
                if isProvider {
                    await loadProviderSummary()
                } else {
                    profileService = AccountProfileService(api: session.deps.api)
                    await loadRemoteProfileIfNeeded()
                    await loadPaymentMethods()
                }
            }
        }
    }

    private func accountRow(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Text(trailing)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding(.vertical, 6)
    }

    private func loadPaymentMethods() async {
        do {
            paymentMethods = try await session.deps.paymentService.listPaymentMethods().paymentMethods
            paymentMethodsError = nil
        } catch {
            paymentMethods = []
            paymentMethodsError = error.localizedDescription
        }
    }

    private var preferenceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tercihlerin")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            HStack(spacing: 12) {
                preferencePill(
                    title: pushAlerts ? "Push Acik" : "Push Kapali",
                    systemImage: pushAlerts ? "bell.badge.fill" : "bell.slash",
                    tint: pushAlerts ? DS.Colors.primary : DS.Colors.textSecondary
                )
                preferencePill(
                    title: newsletter ? "Bulten Acik" : "Bulten Kapali",
                    systemImage: newsletter ? "envelope.fill" : "envelope.open",
                    tint: newsletter ? DS.Colors.accent : DS.Colors.textSecondary
                )
                preferencePill(
                    title: quietHoursEnabled ? "Sessiz Saatler Acik" : "Sessiz Saatler Kapali",
                    systemImage: quietHoursEnabled ? "moon.fill" : "moon",
                    tint: quietHoursEnabled ? .indigo : DS.Colors.textSecondary
                )
            }

            HStack(spacing: 12) {
                accountInfoCard("Konum", selectedLocationName)
                accountInfoCard("Dil / Para", "\(preferredLanguage) • \(preferredCurrency)")
            }

            HStack(spacing: 12) {
                accountInfoCard("Bildirim Kanallari", notificationSummaryText)
                accountInfoCard("Durum Bildirimleri", bookingNotificationSummaryText)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    @ViewBuilder
    private var profileSummaryCard: some View {
        if isProvider {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Bakıcı Profili")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    Button("Profili Düzenle") {
                        showProviderProfileEditor = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Colors.primary)
                }

                HStack(spacing: 12) {
                    accountInfoCard("Ad Soyad", providerDisplayName)
                    accountInfoCard("E-posta", providerEmail)
                }

                HStack(spacing: 12) {
                    accountInfoCard("Telefon", providerPhone)
                    accountInfoCard("Eğitim", providerSummary?.profile.educationLevel.isEmpty == false ? providerSummary?.profile.educationLevel ?? "-" : "-")
                }

                if let providerAbout, !providerAbout.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hakkında")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text(providerAbout)
                            .font(.subheadline)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(3)
                    }
                    .padding()
                    .background(DS.Colors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if !providerCategories.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(providerCategories.prefix(3), id: \.self) { category in
                            Text(category)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DS.Colors.primary.opacity(0.12))
                                .foregroundStyle(DS.Colors.primary)
                                .clipShape(Capsule())
                        }
                    }
                }

                if let providerProfileNotice {
                    Text(providerProfileNotice)
                        .font(.footnote)
                        .foregroundStyle(DS.Colors.primary)
                } else if let providerAccountError {
                    Text(providerAccountError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        } else {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Aile Profili")
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Button("Profili Duzenle") {
                    showProfileEditor = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.primary)
            }

            HStack(spacing: 12) {
                accountInfoCard("Ad Soyad", displayTitle)
                accountInfoCard("E-posta", resolvedProfileEmail)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Aile Hakkinda")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.Colors.textSecondary)
                Text(profileAboutFamily.isEmpty ? "Aileni kisaca tanitman icin profil notu ekleyebilirsin." : profileAboutFamily)
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
            }
            .padding()
            .background(DS.Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let profileSyncNotice {
                Text(profileSyncNotice)
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.primary)
            } else if let profileSyncError {
                Text(profileSyncError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        }
    }

    private var providerOperationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Ödeme ve Onboarding")
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Button("Belgeleri Yönet") {
                    showProviderMediaEditor = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.primary)
            }

            HStack(spacing: 12) {
                accountInfoCard("Ödeme Durumu", providerStatusLabel)
                accountInfoCard("Para Birimi", providerAccount?.currency ?? preferredCurrency)
            }

            HStack(spacing: 12) {
                accountInfoCard("IBAN", maskedIBAN(providerAccount?.iban))
                accountInfoCard("Alt Üye İşyeri", subMerchantSummary)
            }

            HStack(spacing: 12) {
                providerStatusCard("Profil Fotoğrafı", presentation: providerAssetStatus(for: .profilePhoto))
                providerStatusCard("Belge Durumu", presentation: providerAssetStatus(for: .criminalRecord))
            }

            Text("Belge durumları mevcut onboarding yanıtından türetiliyor.")
                .font(.footnote)
                .foregroundStyle(DS.Colors.textSecondary)

            if let error = providerAccount?.lastError, !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            } else if let providerAccountError {
                Text(providerAccountError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private func preferencePill(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private func accountInfoCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func providerStatusCard(_ title: String, presentation: ProviderAssetStatusPresentation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)

            Label(presentation.title, systemImage: presentation.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(presentation.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var notificationSummaryText: String {
        let enabledChannels = [pushAlerts, newsletter, textMessages, phoneCalls].filter { $0 }.count
        return "\(enabledChannels) kanal acik"
    }

    private var bookingNotificationSummaryText: String {
        let enabledTypes = [bookingConfirmedNotifications, bookingRejectedNotifications, bookingCompletedNotifications]
            .filter { $0 }
            .count
        return "\(enabledTypes)/3 acik"
    }

    private var quietHoursSummaryText: String {
        guard quietHoursEnabled else { return "Kapali" }
        return "\(quietHoursStart) - \(quietHoursEnd)"
    }

    private var displayTitle: String {
        if isProvider {
            return providerDisplayName
        }
        if !profileDisplayName.isEmpty { return profileDisplayName }
        if let name = session.me?.user.displayName, !name.isEmpty { return name }
        if let email = session.me?.user.email, !email.isEmpty { return email }
        return "Hesap"
    }

    private var displaySubtitle: String {
        if isProvider {
            return providerEmail
        }
        return resolvedProfilePhone
    }

    private var isProvider: Bool {
        session.me?.user.role == "PROVIDER"
    }

    private var providerStatusLabel: String {
        switch (providerAccount?.status ?? "PENDING").uppercased() {
        case "APPROVED":
            return "Onaylandı"
        case "FAILED":
            return "Başarısız"
        case "PENDING", "PROCESSING":
            return "Beklemede"
        default:
            return providerAccount?.status.capitalized ?? "Beklemede"
        }
    }

    private var subMerchantSummary: String {
        if let key = providerAccount?.subMerchantKey, !key.isEmpty {
            return "Hazır"
        }
        return "Bekleniyor"
    }

    private func maskedIBAN(_ iban: String?) -> String {
        guard let iban, !iban.isEmpty else { return "-" }
        return "****\(iban.suffix(4))"
    }

    private var resolvedProfileEmail: String {
        if !profileEmail.isEmpty { return profileEmail }
        return session.me?.user.email ?? "-"
    }

    private var resolvedProfilePhone: String {
        session.me?.user.phone ?? "-"
    }

    private var providerDisplayName: String {
        let fullName = [providerAccount?.contactName, providerAccount?.contactSurname]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if !fullName.isEmpty { return fullName }
        if let storeName = providerAccount?.name, !storeName.isEmpty { return storeName }
        if let sessionName = session.me?.user.displayName, !sessionName.isEmpty { return sessionName }
        if let sessionEmail = session.me?.user.email, !sessionEmail.isEmpty { return sessionEmail }
        return "Bakıcı Hesabı"
    }

    private var providerEmail: String {
        if let email = providerAccount?.email, !email.isEmpty { return email }
        return session.me?.user.email ?? "-"
    }

    private var providerPhone: String {
        if let phone = providerAccount?.gsmNumber, !phone.isEmpty { return phone }
        return session.me?.user.phone ?? "-"
    }

    private var providerAbout: String? {
        let text = providerSummary?.profile.about.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private var providerCategories: [String] {
        providerSummary?.profile.categories ?? []
    }

    private func providerAssetStatus(for kind: ProviderAssetKind) -> ProviderAssetStatusPresentation {
        let hasAsset: Bool
        switch kind {
        case .profilePhoto:
            hasAsset = providerSummary?.profile.profilePhotoName.isEmpty == false
        case .criminalRecord:
            hasAsset = providerSummary?.profile.criminalRecordFileName.isEmpty == false
        }

        guard hasAsset else {
            return ProviderAssetStatusPresentation(
                title: "Eksik",
                tint: DS.Colors.textSecondary,
                icon: "exclamationmark.circle"
            )
        }

        if let lastError = providerAccount?.lastError, !lastError.isEmpty {
            return ProviderAssetStatusPresentation(
                title: "Reddedildi",
                tint: .red,
                icon: "xmark.seal.fill"
            )
        }

        switch (providerAccount?.status ?? "PENDING").uppercased() {
        case "APPROVED":
            return ProviderAssetStatusPresentation(
                title: "Onaylandı",
                tint: .green,
                icon: "checkmark.seal.fill"
            )
        case "FAILED":
            return ProviderAssetStatusPresentation(
                title: "Reddedildi",
                tint: .red,
                icon: "xmark.seal.fill"
            )
        default:
            return ProviderAssetStatusPresentation(
                title: "Beklemede",
                tint: .orange,
                icon: "clock.badge.exclamationmark"
            )
        }
    }

    private func loadRemoteProfileIfNeeded() async {
        guard !didLoadRemoteProfile, let profileService else { return }
        didLoadRemoteProfile = true

        do {
            if let remote = try await profileService.fetchProfile() {
                if !remote.displayName.isEmpty {
                    profileDisplayName = remote.displayName
                }
                if !remote.email.isEmpty {
                    profileEmail = remote.email
                }
                if !remote.aboutFamily.isEmpty {
                    profileAboutFamily = remote.aboutFamily
                }
                profileSyncNotice = "Profil backend'den eszamanlandi."
                profileSyncError = nil
            }
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    profileSyncNotice = "Profil simdilik bu cihazda saklaniyor. Summary endpoint'i hazir degil."
                } else {
                    profileSyncError = error.localizedDescription
                    profileSyncNotice = nil
                }
            default:
                profileSyncError = error.localizedDescription
                profileSyncNotice = nil
            }
        } catch {
            profileSyncError = error.localizedDescription
            profileSyncNotice = nil
        }
    }

    private func saveProfile(_ snapshot: AccountProfileSnapshot) async {
        profileDisplayName = snapshot.displayName
        profileEmail = snapshot.email
        profileAboutFamily = snapshot.aboutFamily

        do {
            if let remote = try await profileService?.saveProfile(snapshot) {
                if !remote.displayName.isEmpty {
                    profileDisplayName = remote.displayName
                }
                if !remote.email.isEmpty {
                    profileEmail = remote.email
                }
                profileAboutFamily = remote.aboutFamily
                profileSyncNotice = "Profil backend ile eszamanlandi."
            } else {
                profileSyncNotice = "Profil cihazda guncellendi. Summary endpoint'i hazir oldugunda backend ile eszamanlanacak."
            }
            profileSyncError = nil
            showProfileEditor = false
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    profileSyncNotice = "Profil cihazda guncellendi. Backend profil endpoint'i hazir degil."
                    profileSyncError = nil
                    showProfileEditor = false
                } else {
                    profileSyncError = error.localizedDescription
                    profileSyncNotice = nil
                }
            default:
                profileSyncError = error.localizedDescription
                profileSyncNotice = nil
            }
        } catch {
            profileSyncError = error.localizedDescription
            profileSyncNotice = nil
        }
    }

    private func loadProviderSummary() async {
        do {
            let summary = try await session.deps.providerService.getOnboardingSummary()
            providerSummary = summary
            providerAccount = summary.account
            providerProfileNotice = "Bakıcı profili backend'den eşzamanlandı."
            providerAccountError = nil
        } catch let error as APIError {
            providerSummary = nil
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    providerAccountError = "Ödeme onboarding bilgileri henüz backend'de hazır değil."
                } else {
                    providerAccountError = "Ödeme onboarding bilgileri şu anda alınamadı."
                }
            default:
                providerAccountError = "Ödeme onboarding bilgileri şu anda alınamadı."
            }
            providerProfileNotice = nil
        } catch {
            providerSummary = nil
            providerAccountError = "Ödeme onboarding bilgileri şu anda alınamadı."
            providerProfileNotice = nil
        }
    }

    private func saveProviderProfile(_ payload: ProviderProfileEditPayload) async {
        guard let currentAccount = providerAccount else {
            providerAccountError = "Bakıcı hesap bilgileri yüklenmeden profil güncellenemiyor."
            providerProfileNotice = nil
            return
        }

        providerAccountError = nil
        providerProfileNotice = nil

        let payoutRequest = UpsertPayoutAccountRequest(
            address: currentAccount.address,
            contactName: payload.contactName,
            contactSurname: payload.contactSurname,
            email: payload.email,
            gsmNumber: payload.phone,
            name: payload.storeName,
            iban: currentAccount.iban,
            identityNumber: currentAccount.identityNumber
        )

        let profileRequest = UpsertProviderOnboardingProfileRequest(
            educationLevel: payload.educationLevel,
            about: payload.about,
            categories: ProviderCategoryMapper.backendServices(from: payload.categories),
            profilePhotoName: providerSummary?.profile.profilePhotoName ?? "",
            criminalRecordFileName: providerSummary?.profile.criminalRecordFileName ?? ""
        )

        do {
            let payoutResponse = try await session.deps.providerService.upsertPayoutAccount(payoutRequest)
            providerAccount = payoutResponse.account

            do {
                if let updatedSummary = try await session.deps.providerService.upsertOnboardingProfile(profileRequest) {
                    providerSummary = updatedSummary
                    if let updatedAccount = updatedSummary.account {
                        providerAccount = updatedAccount
                    }
                    providerProfileNotice = "Bakıcı profili backend ile eşzamanlandı."
                } else {
                    providerProfileNotice = "Bakıcı profili güncellendi. Profil endpoint'i hazır olduğunda ek alanlar da backend'e taşınacak."
                }
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
                        providerProfileNotice = "Bakıcı profili güncellendi. Profil endpoint'i hazır olmadığından bazı alanlar cihazda tutuluyor."
                    } else {
                        throw error
                    }
                default:
                    throw error
                }
            }

            showProviderProfileEditor = false
        } catch let error as APIError {
            providerAccountError = error.localizedDescription
        } catch {
            providerAccountError = "Bakıcı profili şu anda kaydedilemedi."
        }
    }

    private func saveProviderMedia(_ payload: ProviderMediaEditPayload) async {
        let existingProfile = providerSummary?.profile ?? ProviderOnboardingProfile()
        var profilePhotoName = payload.profilePhotoName
        var profilePhotoURL = existingProfile.profilePhotoUrl
        var criminalRecordFileName = payload.criminalRecordFileName
        var criminalRecordURL = existingProfile.criminalRecordUrl

        providerAccountError = nil
        providerProfileNotice = nil

        do {
            if let profilePhoto = payload.profilePhotoUpload {
                let uploaded = try await session.deps.providerService.uploadDocument(
                    kind: .profilePhoto,
                    fileName: profilePhoto.fileName,
                    data: profilePhoto.data,
                    mimeType: profilePhoto.mimeType
                )
                profilePhotoName = uploaded.profile?.profilePhotoName ?? profilePhotoName
                profilePhotoURL = uploaded.profile?.profilePhotoUrl ?? uploaded.url ?? profilePhotoURL
            }

            if let criminalRecord = payload.criminalRecordUpload {
                let uploaded = try await session.deps.providerService.uploadDocument(
                    kind: .criminalRecord,
                    fileName: criminalRecord.fileName,
                    data: criminalRecord.data,
                    mimeType: criminalRecord.mimeType
                )
                criminalRecordFileName = uploaded.profile?.criminalRecordFileName ?? criminalRecordFileName
                criminalRecordURL = uploaded.profile?.criminalRecordUrl ?? uploaded.url ?? criminalRecordURL
            }

            let profileRequest = UpsertProviderOnboardingProfileRequest(
                educationLevel: existingProfile.educationLevel,
                about: existingProfile.about,
                categories: existingProfile.categories,
                profilePhotoName: profilePhotoName,
                criminalRecordFileName: criminalRecordFileName
            )

            if let updatedSummary = try await session.deps.providerService.upsertOnboardingProfile(profileRequest) {
                providerSummary = updatedSummary
                if let updatedAccount = updatedSummary.account {
                    providerAccount = updatedAccount
                }
                providerProfileNotice = "Profil fotoğrafı ve belge bilgileri backend ile eşzamanlandı."
            } else {
                providerSummary = ProviderOnboardingSummary(
                    account: providerAccount,
                    profile: ProviderOnboardingProfile(
                        educationLevel: existingProfile.educationLevel,
                        about: existingProfile.about,
                        categories: existingProfile.categories,
                        profilePhotoName: profilePhotoName,
                        profilePhotoUrl: profilePhotoURL,
                        criminalRecordFileName: criminalRecordFileName,
                        criminalRecordUrl: criminalRecordURL,
                        profilePhotoStatus: profilePhotoName.isEmpty ? "MISSING" : "PENDING",
                        criminalRecordStatus: criminalRecordFileName.isEmpty ? "MISSING" : "PENDING",
                        approvalStatus: existingProfile.approvalStatus
                    )
                )
                providerProfileNotice = "Profil fotoğrafı ve belge bilgileri güncellendi."
            }
            showProviderMediaEditor = false
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    providerSummary = ProviderOnboardingSummary(
                        account: providerAccount,
                        profile: ProviderOnboardingProfile(
                            educationLevel: existingProfile.educationLevel,
                            about: existingProfile.about,
                            categories: existingProfile.categories,
                            profilePhotoName: profilePhotoName,
                            profilePhotoUrl: profilePhotoURL,
                            criminalRecordFileName: criminalRecordFileName,
                            criminalRecordUrl: criminalRecordURL,
                            profilePhotoStatus: profilePhotoName.isEmpty ? "MISSING" : "PENDING",
                            criminalRecordStatus: criminalRecordFileName.isEmpty ? "MISSING" : "PENDING",
                            approvalStatus: existingProfile.approvalStatus
                        )
                    )
                    providerProfileNotice = "Belge alanları güncellendi. Backend endpoint'i hazır olmadığından cihazda tutuluyor."
                    showProviderMediaEditor = false
                } else {
                    providerAccountError = error.localizedDescription
                }
            default:
                providerAccountError = error.localizedDescription
            }
        } catch {
            providerAccountError = "Belge bilgileri şu anda güncellenemedi."
        }
    }
}

private struct ProviderProfileEditPayload {
    let contactName: String
    let contactSurname: String
    let storeName: String
    let email: String
    let phone: String
    let educationLevel: String
    let about: String
    let categories: [String]
}

private struct ProviderMediaEditPayload {
    struct PendingUpload {
        let fileName: String
        let mimeType: String
        let data: Data
    }

    let profilePhotoName: String
    let criminalRecordFileName: String
    let profilePhotoUpload: PendingUpload?
    let criminalRecordUpload: PendingUpload?
}

private struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    let phone: String
    let onSave: (AccountProfileSnapshot) async -> Void
    @State private var displayName: String
    @State private var email: String
    @State private var aboutFamily: String
    @State private var isSaving = false

    init(
        displayName: String,
        email: String,
        phone: String,
        aboutFamily: String,
        onSave: @escaping (AccountProfileSnapshot) async -> Void
    ) {
        self.phone = phone
        self.onSave = onSave
        _displayName = State(initialValue: displayName)
        _email = State(initialValue: email == "-" ? "" : email)
        _aboutFamily = State(initialValue: aboutFamily)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Aile Profili")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DS.Colors.textPrimary)

                AppTextField(placeholder: "Ad Soyad", text: $displayName)
                AppTextField(placeholder: "E-posta", text: $email, keyboardType: .emailAddress)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Aile Hakkinda")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    AppTextArea(placeholder: "Bakim ihtiyacini ve ailenizi kisaca anlatin", text: $aboutFamily)
                        .frame(minHeight: 140)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Telefon")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(phone)
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                Button {
                    Task {
                        isSaving = true
                        await onSave(
                            AccountProfileSnapshot(
                                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                phone: phone,
                                aboutFamily: aboutFamily.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        isSaving = false
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    } else {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    }
                }
                .background(DS.Colors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Profili Duzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kapat") { dismiss() }
                    .foregroundStyle(DS.Colors.primary)
            }
        }
    }
}

private struct ProviderProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    let account: ProviderAccount?
    let profile: ProviderOnboardingProfile?
    let onSave: (ProviderProfileEditPayload) async -> Void

    @State private var contactName: String
    @State private var contactSurname: String
    @State private var storeName: String
    @State private var email: String
    @State private var phone: String
    @State private var educationLevel: String
    @State private var about: String
    @State private var selectedCategories: [String]
    @State private var isSaving = false

    private let educationOptions = [
        "Lise",
        "Ön Lisans",
        "Lisans",
        "Yüksek Lisans",
        "Doktora"
    ]

    private let categoryOptions = [
        "Bebek Bakımı",
        "Yürümeye Başlayan",
        "Okul Öncesi",
        "Anaokulu",
        "İlkokul Desteği",
        "Özel Ders"
    ]

    init(
        account: ProviderAccount?,
        profile: ProviderOnboardingProfile?,
        onSave: @escaping (ProviderProfileEditPayload) async -> Void
    ) {
        self.account = account
        self.profile = profile
        self.onSave = onSave
        _contactName = State(initialValue: account?.contactName ?? "")
        _contactSurname = State(initialValue: account?.contactSurname ?? "")
        _storeName = State(initialValue: account?.name ?? "")
        _email = State(initialValue: account?.email ?? "")
        _phone = State(initialValue: account?.gsmNumber ?? "")
        _educationLevel = State(initialValue: profile?.educationLevel ?? "")
        _about = State(initialValue: profile?.about ?? "")
        _selectedCategories = State(initialValue: ProviderCategoryMapper.displayLabels(from: profile?.categories ?? []))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Bakıcı Profili")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DS.Colors.textPrimary)

                AppTextField(placeholder: "Ad", text: $contactName)
                AppTextField(placeholder: "Soyad", text: $contactSurname)
                AppTextField(placeholder: "Profil / Mağaza Adı", text: $storeName)
                AppTextField(placeholder: "E-posta", text: $email, keyboardType: .emailAddress)
                AppTextField(placeholder: "Telefon", text: $phone, keyboardType: .phonePad)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Eğitim Durumu")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)

                    Menu {
                        ForEach(educationOptions, id: \.self) { option in
                            Button(option) {
                                educationLevel = option
                            }
                        }
                    } label: {
                        HStack {
                            Text(educationLevel.isEmpty ? "Eğitim seç" : educationLevel)
                                .foregroundStyle(educationLevel.isEmpty ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Hakkında")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    AppTextArea(
                        placeholder: "Deneyimini, yaklaşımını ve ailelere sunduğun desteği anlat.",
                        text: $about,
                        minHeight: 140
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Kategoriler")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        ForEach(categoryOptions, id: \.self) { category in
                            let isSelected = selectedCategories.contains(category)
                            Text(category)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isSelected ? .white : DS.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isSelected ? DS.Colors.primary : .white)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                                }
                                .onTapGesture {
                                    toggleCategory(category)
                                }
                        }
                    }
                }

                Button {
                    Task {
                        isSaving = true
                        await onSave(
                            ProviderProfileEditPayload(
                                contactName: contactName.trimmingCharacters(in: .whitespacesAndNewlines),
                                contactSurname: contactSurname.trimmingCharacters(in: .whitespacesAndNewlines),
                                storeName: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
                                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                                educationLevel: educationLevel,
                                about: about.trimmingCharacters(in: .whitespacesAndNewlines),
                                categories: selectedCategories
                            )
                        )
                        isSaving = false
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    } else {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    }
                }
                .background(DS.Colors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Profili Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kapat") {
                    dismiss()
                }
                .foregroundStyle(DS.Colors.primary)
            }
        }
    }

    private func toggleCategory(_ category: String) {
        if let index = selectedCategories.firstIndex(of: category) {
            selectedCategories.remove(at: index)
        } else {
            selectedCategories.append(category)
        }
    }
}

private struct ProviderMediaEditView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ProviderMediaEditPayload) async -> Void

    @State private var profilePhotoName: String
    @State private var criminalRecordFileName: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPDFPicker = false
    @State private var isSaving = false
    @State private var profilePhotoUpload: ProviderMediaEditPayload.PendingUpload?
    @State private var criminalRecordUpload: ProviderMediaEditPayload.PendingUpload?

    init(
        profilePhotoName: String,
        criminalRecordFileName: String,
        onSave: @escaping (ProviderMediaEditPayload) async -> Void
    ) {
        self.onSave = onSave
        _profilePhotoName = State(initialValue: profilePhotoName)
        _criminalRecordFileName = State(initialValue: criminalRecordFileName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Belgeler ve Medya")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DS.Colors.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Profil Fotoğrafı")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(profilePhotoName.isEmpty ? "Fotoğraf Seç" : "Fotoğrafı Güncelle")
                            Spacer()
                        }
                        .padding(16)
                        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Text(profilePhotoName.isEmpty ? "Henüz fotoğraf seçilmedi." : profilePhotoName)
                        .font(.footnote)
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Sabıka Kaydı")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)

                    Button {
                        showPDFPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text(criminalRecordFileName.isEmpty ? "PDF Seç" : "PDF'yi Güncelle")
                            Spacer()
                        }
                        .padding(16)
                        .background(DS.Colors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text(criminalRecordFileName.isEmpty ? "Henüz belge seçilmedi." : criminalRecordFileName)
                        .font(.footnote)
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                Button {
                    Task {
                        isSaving = true
                        await onSave(
                            ProviderMediaEditPayload(
                                profilePhotoName: profilePhotoName,
                                criminalRecordFileName: criminalRecordFileName,
                                profilePhotoUpload: profilePhotoUpload,
                                criminalRecordUpload: criminalRecordUpload
                            )
                        )
                        isSaving = false
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    } else {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    }
                }
                .background(DS.Colors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Belgeleri Yönet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kapat") {
                    dismiss()
                }
                .foregroundStyle(DS.Colors.primary)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                await loadImage(from: newItem)
            }
        }
        .fileImporter(
            isPresented: $showPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do {
                    let data = try Data(contentsOf: url)
                    criminalRecordFileName = url.lastPathComponent
                    criminalRecordUpload = .init(
                        fileName: url.lastPathComponent,
                        mimeType: "application/pdf",
                        data: data
                    )
                } catch {
                }
            case .failure:
                break
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                let mimeType: String
                if item.supportedContentTypes.first?.conforms(to: .png) == true {
                    mimeType = "image/png"
                } else if item.supportedContentTypes.first?.conforms(to: .heic) == true {
                    mimeType = "image/heic"
                } else {
                    mimeType = "image/jpeg"
                }

                let fileName = "profil-fotografi-guncel.\(ext)"
                profilePhotoName = fileName
                profilePhotoUpload = .init(fileName: fileName, mimeType: mimeType, data: data)
            }
        } catch {
        }
    }
}

private struct FavoritesGridView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var favorites: [FavoriteItem] = []
    @State private var errorMessage: String?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                ForEach(favorites) { item in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: 64, height: 64)
                            .overlay(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(.pink)
                                    .frame(width: 20, height: 20)
                                    .overlay {
                                        Image(systemName: "heart.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                    }
                            }
                        Text(item.displayName)
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text("★ \(String(format: "%.1f", item.rating))")
                            .font(.caption2)
                            .foregroundStyle(DS.Colors.accent)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .navigationTitle("Favoriler")
        .task {
            await loadFavorites()
        }
    }

    private func loadFavorites() async {
        do {
            favorites = try await session.deps.providerService.listFavorites().favorites
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PaymentMethodCatalogView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    let onSaved: () async -> Void
    @State private var brand = "VISA"
    @State private var cardNumber = ""
    @State private var holderName = ""
    @State private var expMonth = ""
    @State private var expYear = ""
    @State private var cvc = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Ödeme Yöntemi")
                        .font(.largeTitle.bold())
                        .foregroundStyle(DS.Colors.textPrimary)

                    HStack(spacing: 10) {
                        payChip("VISA", active: brand == "VISA")
                            .onTapGesture { brand = "VISA" }
                        payChip("MASTERCARD", active: brand == "MASTERCARD")
                            .onTapGesture { brand = "MASTERCARD" }
                        payChip("PAYPAL", active: brand == "PAYPAL")
                            .onTapGesture { brand = "PAYPAL" }
                        payChip("APPLEPAY", active: brand == "APPLEPAY")
                            .onTapGesture { brand = "APPLEPAY" }
                    }

                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.primary, DS.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 180)
                        .overlay(alignment: .topTrailing) {
                            Text(brand)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white.opacity(0.92))
                                .padding()
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Group {
                        AppTextField(placeholder: "Kart Numarası", text: $cardNumber, keyboardType: .numberPad)
                        AppTextField(placeholder: "Kart Sahibi", text: $holderName)
                        HStack {
                            AppTextField(placeholder: "Son Kullanma Ay", text: $expMonth, keyboardType: .numberPad)
                            AppTextField(placeholder: "Son Kullanma Yıl", text: $expYear, keyboardType: .numberPad)
                        }
                        AppTextField(placeholder: "CVC", text: $cvc, keyboardType: .numberPad)
                    }

                    Spacer(minLength: 12)

                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: DS.Size.buttonHeight)
                        } else {
                            Text("Tamam")
                                .frame(maxWidth: .infinity)
                                .frame(height: DS.Size.buttonHeight)
                        }
                    }
                    .background(DS.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
                .padding()
                .padding(.bottom, 20)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(DS.Colors.primary)
                }
            }
        }
        .tint(DS.Colors.primary)
    }

    private func payChip(_ title: String, active: Bool = false) -> some View {
        Text(title)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(active ? DS.Colors.primary : Color.gray.opacity(0.12))
            .foregroundStyle(active ? .white : DS.Colors.textPrimary)
            .clipShape(Capsule())
    }

    private func paymentRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func save() async {
        guard
            let month = Int(expMonth),
            let year = Int(expYear),
            !brand.isEmpty,
            !cardNumber.isEmpty,
            !holderName.isEmpty,
            !cvc.isEmpty
        else {
            errorMessage = "Tüm ödeme alanlarını doldur."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await session.deps.paymentService.createPaymentMethod(
                CreatePaymentMethodReq(
                    brand: brand,
                    cardNumber: cardNumber,
                    holderName: holderName,
                    expMonth: month,
                    expYear: year,
                    cvc: cvc
                )
            )
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let session: SessionStore
    @AppStorage(AccountPreferenceKeys.newsletter) private var newsletter = true
    @AppStorage(AccountPreferenceKeys.textMessages) private var textMessages = false
    @AppStorage(AccountPreferenceKeys.phoneCalls) private var phoneCalls = false
    @AppStorage(AccountPreferenceKeys.pushAlerts) private var pushAlerts = true
    @AppStorage(AccountPreferenceKeys.marketingEmails) private var marketingEmails = false
    @AppStorage(AccountPreferenceKeys.quietHoursEnabled) private var quietHoursEnabled = false
    @AppStorage(AccountPreferenceKeys.quietHoursStart) private var quietHoursStart = "22:00"
    @AppStorage(AccountPreferenceKeys.quietHoursEnd) private var quietHoursEnd = "07:00"
    @AppStorage(AccountPreferenceKeys.bookingConfirmedNotifications) private var bookingConfirmedNotifications = true
    @AppStorage(AccountPreferenceKeys.bookingRejectedNotifications) private var bookingRejectedNotifications = true
    @AppStorage(AccountPreferenceKeys.bookingCompletedNotifications) private var bookingCompletedNotifications = true
    @AppStorage(AccountPreferenceKeys.preferredLanguage) private var preferredLanguage = "Turkce"
    @AppStorage(AccountPreferenceKeys.preferredCurrency) private var preferredCurrency = "TRY"
    @AppStorage(StoredLocationKeys.name) private var selectedLocationName = StoredLocation.fallback.name
    @AppStorage(StoredLocationKeys.latitude) private var selectedLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var selectedLongitude = StoredLocation.fallback.longitude
    @State private var showLocationPicker = false
    @State private var preferenceService: AccountPreferenceService?
    @State private var syncError: String?
    @State private var syncNotice: String?
    @State private var isSyncingPreferences = false
    @State private var didLoadRemotePreferences = false

    private let languages = ["Turkce", "English"]
    private let currencies = ["TRY", "USD", "EUR"]
    private let quietHourOptions = [
        "21:00", "22:00", "23:00", "00:00",
        "01:00", "06:00", "07:00", "08:00", "09:00"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Hesap")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textSecondary)

                    settingsSummaryCard

                    VStack(spacing: 0) {
                        settingsStaticRow("Telefon", session.me?.user.phone ?? "-")
                        Divider()
                        settingsStaticRow("E-posta", session.me?.user.email ?? "-")
                        Divider()
                        settingsStaticRow("Konum", selectedLocationName)
                        Divider()
                        Button {
                            showLocationPicker = true
                        } label: {
                            settingsActionRow("Konumu Guncelle")
                        }
                        Divider()
                        Button("Çıkış Yap") {
                            session.logout()
                            dismiss()
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 4)

                    Text("Diğer Seçenekler")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textSecondary)

                    VStack(spacing: 0) {
                        Toggle("Push Bildirimleri", isOn: $pushAlerts)
                            .tint(DS.Colors.primary)
                            .padding()
                        Divider()
                        Toggle("Onay Bildirimleri", isOn: $bookingConfirmedNotifications)
                            .tint(.green)
                            .padding()
                        Divider()
                        Toggle("Red Bildirimleri", isOn: $bookingRejectedNotifications)
                            .tint(.red)
                            .padding()
                        Divider()
                        Toggle("Tamamlanma Bildirimleri", isOn: $bookingCompletedNotifications)
                            .tint(.blue)
                            .padding()
                        Divider()
                        Toggle("Bülten", isOn: $newsletter)
                            .tint(DS.Colors.primary)
                            .padding()
                        Divider()
                        Toggle("SMS Mesajları", isOn: $textMessages)
                            .tint(DS.Colors.primary)
                            .padding()
                        Divider()
                        Toggle("Telefon Aramaları", isOn: $phoneCalls)
                            .tint(DS.Colors.primary)
                            .padding()
                        Divider()
                        Toggle("Pazarlama E-postalari", isOn: $marketingEmails)
                            .tint(DS.Colors.primary)
                            .padding()
                        Divider()
                        Toggle("Sessiz Saatler", isOn: $quietHoursEnabled)
                            .tint(DS.Colors.primary)
                            .padding()
                        if quietHoursEnabled {
                            Divider()
                            preferencePickerRow(
                                title: "Baslangic",
                                selection: $quietHoursStart,
                                options: quietHourOptions
                            )
                            Divider()
                            preferencePickerRow(
                                title: "Bitis",
                                selection: $quietHoursEnd,
                                options: quietHourOptions
                            )
                        }
                        Divider()
                        preferencePickerRow(
                            title: "Para Birimi",
                            selection: $preferredCurrency,
                            options: currencies
                        )
                        Divider()
                        preferencePickerRow(
                            title: "Dil",
                            selection: $preferredLanguage,
                            options: languages
                        )
                        Divider()
                        settingsStaticRow("Koordinat", StoredLocation.coordinateLabel(latitude: selectedLatitude, longitude: selectedLongitude))
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
                }
                .padding()
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLocationPicker) {
                NavigationStack {
                    MapSearchView(isSelectingLocation: true) { location in
                        selectedLocationName = location.name
                        selectedLatitude = location.latitude
                        selectedLongitude = location.longitude
                        showLocationPicker = false
                    }
                    .navigationTitle("Konum Sec")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .tint(DS.Colors.primary)
        .task {
            preferenceService = AccountPreferenceService(api: session.deps.api)
            await loadRemotePreferencesIfNeeded()
        }
        .onChange(of: preferenceSnapshot) { _, _ in
            Task {
                await syncPreferences()
            }
        }
    }

    private func settingsActionRow(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var settingsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bildirim Ozetin")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            HStack(spacing: 12) {
                summaryMetricCard("Aktif Kanal", "\(enabledChannelCount)")
                summaryMetricCard("Durum Bildirimi", "\(enabledBookingNotificationCount)/3 acik")
            }

            Text("Konum: \(selectedLocationName)")
                .font(.footnote)
                .foregroundStyle(DS.Colors.textSecondary)
                .lineLimit(2)

            if isSyncingPreferences {
                Text("Tercihler eszamanlaniyor...")
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.textSecondary)
            } else if let syncNotice {
                Text(syncNotice)
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.primary)
            } else if let syncError {
                Text(syncError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    private func preferencePickerRow(
        title: String,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(DS.Colors.primary)
        }
        .padding()
    }

    private func summaryMetricCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingsRow(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(DS.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

    private func settingsStaticRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Text(value)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding()
    }

    private var enabledChannelCount: Int {
        [pushAlerts, newsletter, textMessages, phoneCalls, marketingEmails]
            .filter { $0 }
            .count
    }

    private var enabledBookingNotificationCount: Int {
        [bookingConfirmedNotifications, bookingRejectedNotifications, bookingCompletedNotifications]
            .filter { $0 }
            .count
    }

    private var preferenceSnapshot: NotificationPreferenceSnapshot {
        NotificationPreferenceSnapshot(
            newsletter: newsletter,
            textMessages: textMessages,
            phoneCalls: phoneCalls,
            pushAlerts: pushAlerts,
            marketingEmails: marketingEmails,
            preferredLanguage: preferredLanguage,
            preferredCurrency: preferredCurrency,
            bookingConfirmed: bookingConfirmedNotifications,
            bookingRejected: bookingRejectedNotifications,
            bookingCompleted: bookingCompletedNotifications,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
            locationName: selectedLocationName,
            locationLatitude: selectedLatitude,
            locationLongitude: selectedLongitude
        )
    }

    private func loadRemotePreferencesIfNeeded() async {
        guard !didLoadRemotePreferences, let preferenceService else { return }
        didLoadRemotePreferences = true

        do {
            if let remote = try await preferenceService.fetchPreferences() {
                newsletter = remote.newsletter
                textMessages = remote.textMessages
                phoneCalls = remote.phoneCalls
                pushAlerts = remote.pushAlerts
                marketingEmails = remote.marketingEmails
                preferredLanguage = remote.preferredLanguage
                preferredCurrency = remote.preferredCurrency
                bookingConfirmedNotifications = remote.bookingConfirmed
                bookingRejectedNotifications = remote.bookingRejected
                bookingCompletedNotifications = remote.bookingCompleted
                quietHoursEnabled = remote.quietHoursEnabled
                quietHoursStart = remote.quietHoursStart
                quietHoursEnd = remote.quietHoursEnd
                selectedLocationName = remote.locationName
                selectedLatitude = remote.locationLatitude
                selectedLongitude = remote.locationLongitude
                syncNotice = "Tercihler backend'den eszamanlandi."
                syncError = nil
            }
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    syncNotice = "Tercihler bu cihazda kaydediliyor. Backend ayar endpoint'i hazir degil."
                } else {
                    syncError = error.localizedDescription
                    syncNotice = nil
                }
            default:
                syncError = error.localizedDescription
                syncNotice = nil
            }
        } catch {
            syncError = error.localizedDescription
            syncNotice = nil
        }
    }

    private func syncPreferences() async {
        guard didLoadRemotePreferences, let preferenceService else { return }
        isSyncingPreferences = true
        defer { isSyncingPreferences = false }

        do {
            try await preferenceService.savePreferences(preferenceSnapshot)
            syncNotice = "Tercihler backend ile eszamanlandi."
            syncError = nil
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    syncNotice = "Tercihler cihazda guncellendi. Backend ayar endpoint'i hazir degil."
                } else {
                    syncError = error.localizedDescription
                    syncNotice = nil
                }
            default:
                syncError = error.localizedDescription
                syncNotice = nil
            }
        } catch {
            syncError = error.localizedDescription
            syncNotice = nil
        }
    }
}
