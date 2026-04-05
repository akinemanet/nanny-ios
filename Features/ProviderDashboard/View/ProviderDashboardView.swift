//
//  ProviderDashboardView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

private enum ProviderRequestFilter: String, CaseIterable {
    case all = "Hepsi"
    case veryNearby = "Çok Yakın"
    case withNotes = "Notu Olanlar"
    case nearbyFamilies = "Yakındaki Aileler"
}

struct ProviderDashboardView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("providerAvailabilitySelections") private var storedAvailabilitySelections = "{}"
    @AppStorage("providerAvailabilityWeeklyTemplates") private var storedWeeklyTemplates = "{}"
    @AppStorage("providerAvailabilityFocusedDate") private var focusedAvailabilityDate = ""
    @AppStorage("accountProfileDisplayName") private var familyDisplayName = ""
    @AppStorage("accountProfileAboutFamily") private var familyAbout = ""
    @AppStorage(StoredLocationKeys.name) private var familyLocationName = StoredLocation.fallback.name
    @AppStorage(StoredLocationKeys.latitude) private var providerLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var providerLongitude = StoredLocation.fallback.longitude
    let account: ProviderAccount?
    @State private var bookings: [BookingItem] = []
    @State private var todayBookings: [BookingItem] = []
    @State private var pendingRequestBookings: [BookingItem] = []
    @State private var conversations: [ConversationItem] = []
    @State private var unreadNotifications = 0
    @State private var unreadMessages = 0
    @State private var earningsSummaryOverride: ProviderEarningsSummary?
    @State private var providerSummaryError: String?
    @State private var bookingActionInFlightID: String?
    @State private var bookingActionNotice: String?
    @State private var recentlyApprovedBookingIDs: Set<String> = []
    @State private var selectedConversation: ConversationItem?
    @State private var selectedBooking: BookingItem?
    @State private var showChatList = false
    @State private var showAvailabilityManager = false
    @State private var selectedRequestFilter: ProviderRequestFilter = .all
    @State private var careRequests: [CareRequestItem] = []
    @State private var careRequestError: String?
    @State private var careRequestNotice: String?
    @State private var requestActionInFlightID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(account?.name.isEmpty == false ? account?.name ?? "Bakıcı Paneli" : "Bakıcı Paneli")
                            .font(.largeTitle.bold())
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text(account?.email ?? "Profilini, müsaitliğini ve ödeme onboarding durumunu yönet.")
                            .foregroundStyle(DS.Colors.textSecondary)
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Ödeme Durumu",
                            value: providerStatusText(account?.status ?? "PENDING")
                        )

                        DashboardCard(
                            title: "Para Birimi",
                            value: account?.currency ?? "TRY"
                        )
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Okunmamış Mesaj",
                            value: "\(unreadMessages)"
                        )

                        DashboardCard(
                            title: "Bildirim",
                            value: "\(unreadNotifications)"
                        )
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Kayıtlı Slot",
                            value: "\(ProviderAvailabilityLogic.totalSlotCount(in: availabilitySelections))"
                        )

                        DashboardCard(
                            title: "Sıradaki Müsaitlik",
                            value: nextAvailabilityLabel
                        )
                    }

                    if !weeklyTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Haftalık Şablon")
                                .font(.headline)
                                .foregroundStyle(DS.Colors.textPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(weeklyTemplateItems, id: \.weekday) { item in
                                    Button {
                                        focusAvailability(on: item.weekday)
                                    } label: {
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(item.title)
                                                .foregroundStyle(DS.Colors.textPrimary)
                                            Spacer(minLength: 8)
                                            Image(systemName: "chevron.right")
                                                .font(.caption.bold())
                                                .foregroundStyle(DS.Colors.textSecondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(radius: 3)
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Bugünkü Kazanç",
                            value: CurrencyFormatting.formattedAmount(
                                earningsSummary.todayEarnings,
                                currencyCode: account?.currency ?? "TRY"
                            )
                        )

                        DashboardCard(
                            title: "Bekleyen Ödeme",
                            value: CurrencyFormatting.formattedAmount(
                                earningsSummary.pendingPayout,
                                currencyCode: account?.currency ?? "TRY"
                            )
                        )
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Tamamlanan İş",
                            value: "\(earningsSummary.completedTodayCount)"
                        )

                        DashboardCard(
                            title: "Aktif Hizmet",
                            value: "\(earningsSummary.activeTodayCount)"
                        )
                    }

                    providerScheduleSection
                    familyCareRequestsSection
                    providerRequestsSection

                    DashboardCard(
                        title: "Alt Üye İşyeri Anahtarı",
                        value: account?.subMerchantKey ?? "Bekleniyor"
                    )

                    DashboardCard(
                        title: "IBAN",
                        value: maskedIBAN(account?.iban)
                    )

                    if let error = account?.lastError, !error.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Son Ödeme Hatası")
                                .font(.headline)
                                .foregroundStyle(DS.Colors.textPrimary)
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(radius: 3)
                    }

                    if let providerSummaryError {
                        Text(providerSummaryError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let careRequestError {
                        Text(careRequestError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let bookingActionNotice {
                        Text(bookingActionNotice)
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let careRequestNotice {
                        Text(careRequestNotice)
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    NavigationLink {
                        ProviderCalendarView()
                    } label: {
                        Label("Müsaitliği Yönet", systemImage: "calendar.badge.clock")
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                            .background(DS.Colors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bugünkü Odak")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        bullet("Müsaitlik takvimini güncel tut ve yeni slotlarını kaydet.")
                        bullet("Okunmamış mesajları hızlıca kontrol et.")
                        bullet("Ödeme onboarding ve IBAN bilgisini güncel tut.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 3)
                }
                .padding()
            }
            .navigationTitle("Panel")
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationDestination(item: $selectedBooking) { booking in
                ProviderBookingDetailView(
                    booking: booking,
                    conversation: matchingConversation(for: booking),
                    onMessageTap: { conversation in
                        selectedConversation = conversation
                    }
                )
            }
            .navigationDestination(item: $selectedConversation) { conversation in
                ChatView(chatID: conversation.id, title: conversation.participantName)
            }
            .navigationDestination(isPresented: $showChatList) {
                ChatListView()
            }
            .navigationDestination(isPresented: $showAvailabilityManager) {
                ProviderCalendarView()
            }
            .task(id: currentProviderID) {
                guard session.isLoggedIn else { return }
                await loadProviderSummary()
            }
            .refreshable {
                await loadProviderSummary()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active, session.isLoggedIn else { return }
                Task {
                    await loadProviderSummary()
                }
            }
        }
    }

    private var availabilitySelections: [String: [String]] {
        ProviderAvailabilityLogic.decodeSelections(storedAvailabilitySelections)
    }

    private var weeklyTemplates: [Int: [String]] {
        ProviderAvailabilityLogic.decodeWeeklyTemplates(storedWeeklyTemplates)
    }

    private var nextAvailabilityLabel: String {
        guard let next = ProviderAvailabilityLogic.nextAvailableDate(in: availabilitySelections) else {
            return "Planlanmadı"
        }

        return formattedDay(next)
    }

    private var weeklyTemplateItems: [(weekday: Int, title: String)] {
        weeklyTemplates
            .keys
            .sorted()
            .compactMap { weekday in
                guard let slots = weeklyTemplates[weekday], !slots.isEmpty else { return nil }
                let day = ProviderAvailabilityLogic.weekdayTitle(for: weekday)
                return (weekday, "\(day): \(ProviderAvailabilityLogic.sortedSlots(slots).joined(separator: ", "))")
            }
    }

    private func focusAvailability(on weekday: Int) {
        guard let targetDate = ProviderAvailabilityLogic.nextDate(for: weekday) else {
            showAvailabilityManager = true
            return
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        focusedAvailabilityDate = formatter.string(from: targetDate)
        showAvailabilityManager = true
    }

    private var providerScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bugünkü Program")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            if todaysBookings.isEmpty {
                emptyProviderCard(
                    title: "Bugün planlanmış iş yok",
                    message: "Müsaitlik takvimini güncel tutarak yeni talepler alabilirsin.",
                    systemImage: "calendar.badge.clock"
                )
            } else {
                ForEach(todaysBookings.prefix(3)) { booking in
                    providerBookingCard(
                        booking,
                        accent: DS.Colors.primary,
                        label: "Bugun",
                        showTodayActions: true
                    )
                }
            }
        }
    }

    private var providerRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yaklaşan Talepler")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            if selectedRequestFilter == .all, !veryNearbyPendingRequests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Öncelikli Talepler", systemImage: "bolt.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(DS.Colors.primary)

                    ForEach(veryNearbyPendingRequests.prefix(2)) { booking in
                        providerBookingCard(
                            booking,
                            accent: DS.Colors.primary,
                            label: "Çok Yakın",
                            showActions: true,
                            priorityHighlight: true
                        )
                    }
                }
            }

            requestFilterBar

            if filteredPendingRequests.isEmpty {
                emptyProviderCard(
                    title: "Bekleyen talep yok",
                    message: "Yeni rezervasyon talepleri geldiginde burada gorunecek.",
                    systemImage: "tray"
                )
            } else {
                ForEach(filteredPendingRequests.prefix(3)) { booking in
                    providerBookingCard(
                        booking,
                        accent: .orange,
                        label: "Onay Bekliyor",
                        showActions: true
                    )
                }
            }
        }
    }

    private var familyCareRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aile Talepleri")
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Text("\(visibleCareRequests.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DS.Colors.primary.opacity(0.14))
                    .foregroundStyle(DS.Colors.primary)
                    .clipShape(Capsule())
            }

            if visibleCareRequests.isEmpty {
                emptyProviderCard(
                    title: "Açık aile talebi yok",
                    message: "Aileler hızlı talep oluşturduğunda burada görüp aday olabileceksin.",
                    systemImage: "figure.2.and.child.holdinghands"
                )
            } else {
                ForEach(visibleCareRequests) { request in
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizedCareService(request.service))
                                        .font(.headline)
                                        .foregroundStyle(DS.Colors.textPrimary)
                                    Text(resolvedParentDisplayName(for: request))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DS.Colors.textSecondary)
                                    Text("\(formattedDate(request.startAt)) • \(formattedTime(request.startAt)) - \(formattedTime(request.endAt))")
                                        .font(.caption)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                }
                                Spacer()
                                Text(careRequestStatusLabel(for: request))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(careRequestStatusColor(for: request).opacity(0.14))
                                    .foregroundStyle(careRequestStatusColor(for: request))
                                    .clipShape(Capsule())
                            }

                            HStack(spacing: 12) {
                                careRequestMetaCard("Konum", request.locationName)
                                careRequestMetaCard("Aday", "\(request.candidates.count)")
                            }

                            if !request.note.isEmpty {
                                careRequestMetaCard("Not", request.note)
                            }

                            if request.assignedProviderUserID == currentProviderID {
                                careRequestMetaCard("Durum", "Aile bu işi sana atadı.")
                            } else if providerHasApplied(to: request) {
                                careRequestMetaCard("Durum", "Bu talebe aday oldun. Ailenin onayı bekleniyor.")
                            } else if request.isOpen {
                                Button {
                                    Task {
                                        await apply(to: request)
                                    }
                                } label: {
                                    HStack {
                                        if requestActionInFlightID == request.id {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        Text(requestActionInFlightID == request.id ? "Gönderiliyor" : "Aday Ol")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .frame(height: DS.Size.buttonHeight)
                                    .background(DS.Colors.primary)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .disabled(requestActionInFlightID == request.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var todaysBookings: [BookingItem] {
        todayBookings.isEmpty
            ? providerBookings.filter { isToday($0.startTime) }
            : todayBookings
    }

    private var pendingRequests: [BookingItem] {
        pendingRequestBookings.isEmpty
            ? providerBookings.filter {
                let status = $0.status.uppercased()
                return status == "REQUESTED" || status == "PENDING"
            }
            .sorted {
                let lhsContext = requestContext(for: $0)
                let rhsContext = requestContext(for: $1)
                if lhsContext.priority != rhsContext.priority {
                    return lhsContext.priority < rhsContext.priority
                }
                return $0.startTime < $1.startTime
            }
            : pendingRequestBookings
    }

    private var filteredPendingRequests: [BookingItem] {
        switch selectedRequestFilter {
        case .all:
            return pendingRequests
        case .veryNearby:
            return pendingRequests.filter {
                ProviderNearbyFamilyLogic.distanceBucketTitle(
                    providerLatitude: providerLatitude,
                    providerLongitude: providerLongitude,
                    familyLatitude: $0.familyLocationLatitude,
                    familyLongitude: $0.familyLocationLongitude
                ) == "0-3 km"
            }
        case .withNotes:
            return pendingRequests.filter {
                !(($0.familyAbout ?? familyAbout).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        case .nearbyFamilies:
            return pendingRequests.filter {
                ProviderNearbyFamilyLogic.isNearby(
                    providerLatitude: providerLatitude,
                    providerLongitude: providerLongitude,
                    familyLatitude: $0.familyLocationLatitude,
                    familyLongitude: $0.familyLocationLongitude,
                    fallbackLocationName: $0.familyLocationName ?? familyLocationName
                )
            }
        }
    }

    private var veryNearbyPendingRequests: [BookingItem] {
        pendingRequests.filter {
            ProviderNearbyFamilyLogic.distanceBucketTitle(
                providerLatitude: providerLatitude,
                providerLongitude: providerLongitude,
                familyLatitude: $0.familyLocationLatitude,
                familyLongitude: $0.familyLocationLongitude
            ) == "0-3 km"
        }
    }

    private var providerBookings: [BookingItem] {
        bookings.sorted { $0.startTime < $1.startTime }
    }

    private var currentProviderID: String {
        session.me?.user.id ?? ""
    }

    private var resolvedProviderDisplayName: String {
        if let name = account?.name, !name.isEmpty { return name }
        if let displayName = session.me?.user.displayName, !displayName.isEmpty { return displayName }
        if let email = session.me?.user.email, !email.isEmpty { return email }
        return session.me?.user.phone ?? "Bakıcı"
    }

    private var visibleCareRequests: [CareRequestItem] {
        careRequests.sorted { $0.startAt < $1.startAt }
    }

    private var earningsSummary: ProviderEarningsSummary {
        earningsSummaryOverride ?? ProviderEarningsSummary.make(bookings: providerBookings)
    }

    private func maskedIBAN(_ iban: String?) -> String {
        guard let iban, !iban.isEmpty else { return "Belirtilmedi" }
        let suffix = iban.suffix(4)
        return "****\(suffix)"
    }

    private func providerStatusText(_ status: String) -> String {
        switch status.uppercased() {
        case "APPROVED":
            return "Onaylandı"
        case "FAILED":
            return "Başarısız"
        case "PENDING":
            return "Beklemede"
        default:
            return status.capitalized
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DS.Colors.primary)
            Text(text)
                .foregroundStyle(DS.Colors.textSecondary)
        }
    }

    private var requestFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ProviderRequestFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedRequestFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedRequestFilter == filter ? DS.Colors.primary : .white)
                            .foregroundStyle(selectedRequestFilter == filter ? .white : DS.Colors.textPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func careRequestMetaCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textPrimary)
                .lineLimit(title == "Not" ? 4 : 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func loadProviderSummary() async {
        providerSummaryError = nil
        careRequestError = nil

        do {
            careRequests = try await session.deps.bookingService.listProviderCareRequests(providerUserID: currentProviderID)
        } catch {
            careRequests = []
            careRequestError = error.localizedDescription
        }

        do {
            let notifications = try await session.deps.notificationService.listNotifications()
            unreadNotifications = try await session.deps.notificationService.unreadNotificationCount(
                fallback: notifications.notifications
            )
        } catch {
            unreadNotifications = 0
        }

        do {
            let conversationsResponse = try await session.deps.chatService.listConversations()
            conversations = conversationsResponse.conversations
            unreadMessages = try await session.deps.chatService.unreadConversationCount(
                fallback: conversationsResponse.conversations
            )
        } catch {
            conversations = []
            unreadMessages = 0
        }

        do {
            let loadedBookings = try await session.deps.bookingService.listBookings()
            bookings = loadedBookings
            earningsSummaryOverride = try await session.deps.bookingService.providerEarningsSummary(
                fallback: loadedBookings
            )

            do {
                todayBookings = try await session.deps.bookingService.providerTodayBookings(fallback: loadedBookings)
                pendingRequestBookings = try await session.deps.bookingService.providerPendingRequests(fallback: loadedBookings)
            } catch {
                todayBookings = loadedBookings.filter { isToday($0.startTime) }.sorted { $0.startTime < $1.startTime }
                pendingRequestBookings = loadedBookings.filter {
                    let status = $0.status.uppercased()
                    return status == "REQUESTED" || status == "PENDING"
                }
                .sorted { $0.startTime < $1.startTime }
            }
        } catch {
            bookings = []
            todayBookings = []
            pendingRequestBookings = []
            earningsSummaryOverride = nil
            if providerSummaryError == nil {
                providerSummaryError = error.localizedDescription
            }
        }
    }

    private func formattedDay(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.dateStyle = .medium
        return output.string(from: date)
    }

    private func formattedDate(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.dateStyle = .medium
        return output.string(from: date)
    }

    private func formattedTime(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.timeStyle = .short
        return output.string(from: date)
    }

    private func isToday(_ value: String) -> Bool {
        guard let date = parseISODate(value) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private func parseISODate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: value)
    }

    private func resolvedParentDisplayName(for request: CareRequestItem) -> String {
        let trimmed = request.parentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == request.parentPhone || isLikelyPhoneNumber(trimmed) {
            return "Aile"
        }
        return trimmed
    }

    private func isLikelyPhoneNumber(_ value: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let scalarView = value.unicodeScalars
        guard !scalarView.isEmpty, scalarView.allSatisfy(allowed.contains) else { return false }
        let digits = value.filter(\.isNumber)
        return digits.count >= 10
    }

    private func providerHasApplied(to request: CareRequestItem) -> Bool {
        request.candidates.contains(where: { $0.providerUserID == currentProviderID })
    }

    private func apply(to request: CareRequestItem) async {
        guard let provider = session.me?.user else { return }
        requestActionInFlightID = request.id
        defer { requestActionInFlightID = nil }

        do {
            _ = try await session.deps.bookingService.applyToCareRequest(
                requestID: request.id,
                provider: provider,
                providerDisplayName: resolvedProviderDisplayName
            )
            careRequestNotice = "Aileye adaylığın iletildi."
            careRequestError = nil
            careRequests = try await session.deps.bookingService.listProviderCareRequests(providerUserID: currentProviderID)
        } catch {
            careRequestError = error.localizedDescription
        }
    }

    private func localizedCareService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first ?? service
    }

    private func careRequestStatusLabel(for request: CareRequestItem) -> String {
        if request.assignedProviderUserID == currentProviderID {
            return "Seçildin"
        }
        if providerHasApplied(to: request) {
            return "Aday oldun"
        }
        if request.isMatched {
            return "Dolu"
        }
        return "Açık"
    }

    private func careRequestStatusColor(for request: CareRequestItem) -> Color {
        if request.assignedProviderUserID == currentProviderID {
            return .green
        }
        if providerHasApplied(to: request) {
            return DS.Colors.primary
        }
        if request.isMatched {
            return .gray
        }
        return .orange
    }

    private func providerBookingCard(
        _ booking: BookingItem,
        accent: Color,
        label: String,
        showActions: Bool = false,
        showTodayActions: Bool = false,
        priorityHighlight: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let context = requestContext(for: booking)
            let wasJustApproved = recentlyApprovedBookingIDs.contains(booking.id)

            if priorityHighlight {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.badge.clock.fill")
                        .foregroundStyle(DS.Colors.primary)
                    Text("Bu talep sana çok yakın. Hızlı dönüş avantaj sağlar.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.primary)
                    Spacer()
                }
                .padding(10)
                .background(DS.Colors.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if wasJustApproved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Hızlı onay gönderildi")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Spacer()
                }
                .padding(10)
                .background(Color.green.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack {
                Text(resolvedFamilyName(for: booking))
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Text(label)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.14))
                    .foregroundStyle(accent)
                    .clipShape(Capsule())
            }

            Text(booking.service.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 12) {
                Label(formattedDay(booking.startTime.prefix(10).description), systemImage: "calendar")
                Label("\(formattedTime(booking.startTime)) - \(formattedTime(booking.endTime))", systemImage: "clock")
            }
            .font(.footnote)
            .foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 8) {
                if let badgeTitle = context.badgeTitle,
                   let badgeSystemImage = context.badgeSystemImage {
                    Label(badgeTitle, systemImage: badgeSystemImage)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.Colors.accent.opacity(0.12))
                        .foregroundStyle(DS.Colors.accent)
                        .clipShape(Capsule())
                }

                if let distanceBucketTitle = context.distanceBucketTitle {
                    Text(distanceBucketTitle)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.Colors.primary.opacity(0.1))
                        .foregroundStyle(DS.Colors.primary)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(DS.Colors.accent)
                Text(familyPreviewText(for: booking))
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(2)
            }

            if priorityHighlight, let estimatedTravelTime = estimatedTravelTimeText(for: booking) {
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .foregroundStyle(DS.Colors.primary)
                    Text("Tahmini ulasim: \(estimatedTravelTime)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.primary)
                    Spacer()
                }
                .padding(.horizontal, 2)
            }

            if showActions {
                HStack(spacing: 10) {
                    Button {
                        Task { await handleProviderDecision(for: booking, status: "CONFIRMED") }
                    } label: {
                        if bookingActionInFlightID == booking.id {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                        } else {
                            Text("Onayla")
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                        }
                    }
                    .background(DS.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(bookingActionInFlightID == booking.id)

                    Button {
                        Task { await handleProviderDecision(for: booking, status: "CANCELED") }
                    } label: {
                        Text("Reddet")
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(bookingActionInFlightID == booking.id)
                }
            }

            if showTodayActions {
                HStack(spacing: 10) {
                    if canCheckIn(booking) {
                        Button {
                            Task { await handleProviderDecision(for: booking, status: "IN_PROGRESS") }
                        } label: {
                            todayActionLabel(
                                title: "Check-in Yap",
                                bookingID: booking.id
                            )
                        }
                        .background(DS.Colors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(bookingActionInFlightID == booking.id)
                    }

                    if canComplete(booking) {
                        Button {
                            Task { await handleProviderDecision(for: booking, status: "COMPLETED") }
                        } label: {
                            todayActionLabel(
                                title: "Tamamla",
                                bookingID: booking.id
                            )
                        }
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(bookingActionInFlightID == booking.id)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    selectedBooking = booking
                } label: {
                    Text("Detayi Ac")
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .background(DS.Colors.primary.opacity(0.1))
                .foregroundStyle(DS.Colors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    if let conversation = matchingConversation(for: booking) {
                        selectedConversation = conversation
                    } else {
                        showChatList = true
                    }
                } label: {
                    Text("Mesaja Git")
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .background(DS.Colors.accent.opacity(0.12))
                .foregroundStyle(DS.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if priorityHighlight {
                HStack(spacing: 10) {
                    Button {
                        Task { await handleProviderDecision(for: booking, status: "CONFIRMED") }
                    } label: {
                        if bookingActionInFlightID == booking.id {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        } else {
                            Label("Hemen Onayla", systemImage: "bolt.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                    }
                    .background(DS.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(bookingActionInFlightID == booking.id)

                    Button {
                        showAvailabilityManager = true
                    } label: {
                        Label("Takvimi Kontrol Et", systemImage: "calendar.badge.clock")
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .background(DS.Colors.primary.opacity(0.1))
                    .foregroundStyle(DS.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            recentlyApprovedBookingIDs.contains(booking.id)
            ? Color.green.opacity(0.05)
            : (priorityHighlight ? DS.Colors.primary.opacity(0.04) : .white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            if recentlyApprovedBookingIDs.contains(booking.id) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.green.opacity(0.28), lineWidth: 1.2)
            } else if priorityHighlight {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(DS.Colors.primary.opacity(0.22), lineWidth: 1)
            }
        }
        .shadow(radius: 3)
    }

    private func todayActionLabel(title: String, bookingID: String) -> some View {
        Group {
            if bookingActionInFlightID == bookingID {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            } else {
                Text(title)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
        }
    }

    private func emptyProviderCard(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(DS.Colors.accent)
            Text(title)
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 3)
    }

    private func handleProviderDecision(for booking: BookingItem, status: String) async {
        bookingActionInFlightID = booking.id
        providerSummaryError = nil
        bookingActionNotice = nil
        defer { bookingActionInFlightID = nil }

        do {
            if let updated = try await session.deps.bookingService.providerUpdateBookingStatus(
                bookingID: booking.id,
                status: status
            ) {
                applyBookingUpdate(updated)
                markRecentlyApprovedIfNeeded(bookingID: updated.id, status: status)
                let notificationNote = await notifyFamilyIfNeeded(for: updated, status: status)
                bookingActionNotice = providerDecisionNotice(for: status, fallback: false)
                    + notificationNote
                return
            }

            let fallbackBooking = localDecisionBooking(from: booking, status: status)
            applyBookingUpdate(fallbackBooking)
            markRecentlyApprovedIfNeeded(bookingID: fallbackBooking.id, status: status)
            let notificationNote = await notifyFamilyIfNeeded(for: fallbackBooking, status: status)
            bookingActionNotice = providerDecisionNotice(for: status, fallback: true)
                + notificationNote
        } catch let error as APIError {
            switch error {
                case .http(let code, _):
                    if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                        let fallbackBooking = localDecisionBooking(from: booking, status: status)
                        applyBookingUpdate(fallbackBooking)
                        markRecentlyApprovedIfNeeded(bookingID: fallbackBooking.id, status: status)
                        let notificationNote = await notifyFamilyIfNeeded(for: fallbackBooking, status: status)
                        bookingActionNotice = providerDecisionNotice(for: status, fallback: true)
                            + notificationNote
                    } else {
                        providerSummaryError = error.localizedDescription
                }
            default:
                providerSummaryError = error.localizedDescription
            }
        } catch {
            providerSummaryError = error.localizedDescription
        }
    }

    private func applyBookingUpdate(_ booking: BookingItem) {
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index] = booking
        } else {
            bookings.append(booking)
        }
    }

    private func localDecisionBooking(from booking: BookingItem, status: String) -> BookingItem {
        BookingItem(
            id: booking.id,
            service: booking.service,
            status: status,
            startTime: booking.startTime,
            endTime: booking.endTime,
            totalPrice: booking.totalPrice,
            address: booking.address,
            paymentStatus: booking.paymentStatus,
            provider: booking.provider,
            parentUserID: booking.parentUserID,
            familyDisplayName: booking.familyDisplayName,
            familyAbout: booking.familyAbout,
            familyLocationName: booking.familyLocationName,
            familyLocationLatitude: booking.familyLocationLatitude,
            familyLocationLongitude: booking.familyLocationLongitude
        )
    }

    private func matchingConversation(for booking: BookingItem) -> ConversationItem? {
        DashboardRouting.conversation(
            forProviderID: booking.parentUserID ?? booking.provider.id,
            participantName: resolvedFamilyName(for: booking),
            conversations: conversations
        )
    }

    private func canCheckIn(_ booking: BookingItem) -> Bool {
        let status = booking.status.uppercased()
        return status == "CONFIRMED" || status == "ACCEPTED"
    }

    private func canComplete(_ booking: BookingItem) -> Bool {
        booking.status.uppercased() == "IN_PROGRESS"
    }

    private func providerDecisionNotice(for status: String, fallback: Bool) -> String {
        switch status.uppercased() {
        case "CONFIRMED":
            return fallback
                ? "Talep lokal olarak onaylandı. Backend endpoint'i hazır değil."
                : "Talep onaylandı."
        case "CANCELED":
            return fallback
                ? "Talep lokal olarak reddedildi. Backend endpoint'i hazır değil."
                : "Talep reddedildi."
        case "IN_PROGRESS":
            return fallback
                ? "Check-in lokal olarak başlatıldı. Durum panelde güncellendi."
                : "Hizmet başlatıldı."
        case "COMPLETED":
            return fallback
                ? "Hizmet lokal olarak tamamlandı. Kazanç özeti güncellendi."
                : "Hizmet tamamlandı. Kazanç özeti güncellendi."
        default:
            return fallback
                ? "Durum lokal olarak güncellendi."
                : "Durum güncellendi."
        }
    }

    private func notifyFamilyIfNeeded(for booking: BookingItem, status: String) async -> String {
        let normalizedStatus = status.uppercased()
        guard normalizedStatus == "CONFIRMED" || normalizedStatus == "CANCELED" || normalizedStatus == "COMPLETED" else {
            return ""
        }
        guard let parentUserID = booking.parentUserID, !parentUserID.isEmpty else {
            return " Aile bildirimi için parent user bilgisi bulunamadı."
        }

        do {
            try await session.deps.notificationService.sendBookingStatusNotification(
                parentUserID: parentUserID,
                providerName: booking.provider.displayName,
                bookingID: booking.id,
                service: booking.service,
                status: normalizedStatus,
                startAt: booking.startTime,
                familyDisplayName: booking.familyDisplayName,
                proximityText: notificationProximityText(for: booking)
            )
            return familyNotificationNotice(for: normalizedStatus, fallback: false)
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if NotificationMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                    return familyNotificationNotice(for: normalizedStatus, fallback: true)
                }
                providerSummaryError = error.localizedDescription
                return ""
            default:
                providerSummaryError = error.localizedDescription
                return ""
            }
        } catch {
            providerSummaryError = error.localizedDescription
            return ""
        }
    }

    private func familyNotificationNotice(for status: String, fallback: Bool) -> String {
        switch status {
        case "CONFIRMED":
            return fallback
                ? " Aile onay bildirimi endpoint'i hazır değil."
                : " Aileye onay bildirimi gönderildi."
        case "CANCELED":
            return fallback
                ? " Aile red bildirimi endpoint'i hazır değil."
                : " Aileye red bildirimi gönderildi."
        default:
            return fallback
                ? " Aile tamamlanma bildirimi endpoint'i hazır değil."
                : " Aileye tamamlanma bildirimi gönderildi."
        }
    }

    private func familyPreviewText(for booking: BookingItem) -> String {
        let trimmedAbout = (booking.familyAbout ?? familyAbout).trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAbout.isEmpty {
            return trimmedAbout
        }
        let resolvedName = resolvedFamilyName(for: booking)
        let resolvedLocation = distancePreview(for: booking) ?? booking.familyLocationName ?? familyLocationName
        if !resolvedName.isEmpty {
            return "\(resolvedName) • \(resolvedLocation)"
        }
        return resolvedLocation
    }

    private func requestContext(for booking: BookingItem) -> ProviderRequestContextPresentation {
        ProviderRequestContextPresentation.make(
            familyDisplayName: booking.familyDisplayName ?? familyDisplayName,
            familyAbout: booking.familyAbout ?? familyAbout,
            familyLocationName: booking.familyLocationName ?? familyLocationName,
            providerLatitude: providerLatitude,
            providerLongitude: providerLongitude,
            familyLatitude: booking.familyLocationLatitude,
            familyLongitude: booking.familyLocationLongitude
        )
    }

    private func distancePreview(for booking: BookingItem) -> String? {
        guard let distance = StoredLocation.distanceInKilometers(
            from: providerLatitude,
            originLongitude: providerLongitude,
            to: booking.familyLocationLatitude,
            destinationLongitude: booking.familyLocationLongitude
        ) else {
            return nil
        }

        return String(format: "%.1f km uzaklikta", distance)
    }

    private func estimatedTravelTimeText(for booking: BookingItem) -> String? {
        guard let distance = StoredLocation.distanceInKilometers(
            from: providerLatitude,
            originLongitude: providerLongitude,
            to: booking.familyLocationLatitude,
            destinationLongitude: booking.familyLocationLongitude
        ) else {
            return nil
        }

        let estimatedMinutes = max(5, Int((distance / 25.0 * 60.0).rounded()))
        return "\(estimatedMinutes) dk"
    }

    private func notificationProximityText(for booking: BookingItem) -> String? {
        guard let distance = StoredLocation.distanceInKilometers(
            from: providerLatitude,
            originLongitude: providerLongitude,
            to: booking.familyLocationLatitude,
            destinationLongitude: booking.familyLocationLongitude
        ) else {
            let fallbackLocation = booking.familyLocationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return fallbackLocation.isEmpty ? nil : fallbackLocation
        }

        if distance < 3 {
            return "sana cok yakin"
        }

        return String(format: "%.1f km uzakta", distance)
    }

    private func markRecentlyApprovedIfNeeded(bookingID: String, status: String) {
        if status.uppercased() == "CONFIRMED" {
            recentlyApprovedBookingIDs.insert(bookingID)
        } else {
            recentlyApprovedBookingIDs.remove(bookingID)
        }
    }

    private func resolvedFamilyName(for booking: BookingItem) -> String {
        let bookingName = booking.familyDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !bookingName.isEmpty {
            return bookingName
        }

        let storedName = familyDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !storedName.isEmpty {
            return storedName
        }

        return "Aile"
    }
}

private struct ProviderBookingDetailView: View {
    @AppStorage("accountProfileDisplayName") private var familyDisplayName = ""
    @AppStorage("accountProfileEmail") private var familyEmail = ""
    @AppStorage("accountProfileAboutFamily") private var familyAbout = ""
    @AppStorage(StoredLocationKeys.name) private var familyLocationName = StoredLocation.fallback.name
    let booking: BookingItem
    let conversation: ConversationItem?
    let onMessageTap: (ConversationItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(resolvedFamilyName)
                        .font(.title2.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(booking.service.replacingOccurrences(of: "_", with: " ").capitalized)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                detailCard("Durum", BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus).localizedStatus)
                detailCard("Ödeme", BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus).paymentSummaryText)
                detailCard("Tarih", formattedDay(booking.startTime.prefix(10).description))
                detailCard("Saat", "\(formattedTime(booking.startTime)) - \(formattedTime(booking.endTime))")

                if let address = booking.address, !address.isEmpty {
                    detailCard("Adres", address)
                }

                familyProfileCard

                if let conversation {
                    Button {
                        onMessageTap(conversation)
                    } label: {
                        Text("Bu Kisiyle Mesajlas")
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    }
                    .background(DS.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Talep Detayi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var familyProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aile Profili")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            HStack(spacing: 12) {
                detailCardInline("Ad Soyad", resolvedFamilyName)
                detailCardInline("E-posta", resolvedFamilyEmail)
            }

            detailCardInline("Konum", resolvedFamilyLocationName)

            if !familyAboutText.isEmpty {
                detailCardInline("Not", familyAboutText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailCardInline(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(title == "Not" ? 4 : 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var resolvedFamilyName: String {
        if let bookingName = booking.familyDisplayName, !bookingName.isEmpty { return bookingName }
        if !familyDisplayName.isEmpty { return familyDisplayName }
        if !familyEmail.isEmpty { return familyEmail }
        return "Aile"
    }

    private var resolvedFamilyEmail: String {
        familyEmail.isEmpty ? "Belirtilmedi" : familyEmail
    }

    private var familyAboutText: String {
        if let bookingAbout = booking.familyAbout?.trimmingCharacters(in: .whitespacesAndNewlines), !bookingAbout.isEmpty {
            return bookingAbout
        }
        return familyAbout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedFamilyLocationName: String {
        if let bookingLocation = booking.familyLocationName, !bookingLocation.isEmpty {
            return bookingLocation
        }
        return familyLocationName
    }

    private func formattedDay(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.dateStyle = .medium
        return output.string(from: date)
    }

    private func formattedTime(_ value: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.timeStyle = .short
        return output.string(from: date)
    }
}
