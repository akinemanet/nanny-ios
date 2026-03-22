//
//  ProviderDashboardView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

private enum ProviderRequestFilter: String, CaseIterable {
    case all = "Hepsi"
    case veryNearby = "Cok Yakin"
    case withNotes = "Notu Olanlar"
    case nearbyFamilies = "Yakindaki Aileler"
}

struct ProviderDashboardView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("providerAvailabilitySelections") private var storedAvailabilitySelections = "{}"
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(account?.name.isEmpty == false ? account?.name ?? "Bakıcı Paneli" : "Bakıcı Paneli")
                            .font(.largeTitle.bold())
                        Text(account?.email ?? "Profilini, müsaitliğini ve ödeme onboarding durumunu yönet.")
                            .foregroundStyle(.secondary)
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
                            title: "Okunmamis Mesaj",
                            value: "\(unreadMessages)"
                        )

                        DashboardCard(
                            title: "Bildirim",
                            value: "\(unreadNotifications)"
                        )
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Kayitli Slot",
                            value: "\(ProviderAvailabilityLogic.totalSlotCount(in: availabilitySelections))"
                        )

                        DashboardCard(
                            title: "Siradaki Musaitlik",
                            value: nextAvailabilityLabel
                        )
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Bugunku Kazanc",
                            value: CurrencyFormatting.formattedAmount(
                                earningsSummary.todayEarnings,
                                currencyCode: account?.currency ?? "TRY"
                            )
                        )

                        DashboardCard(
                            title: "Bekleyen Odeme",
                            value: CurrencyFormatting.formattedAmount(
                                earningsSummary.pendingPayout,
                                currencyCode: account?.currency ?? "TRY"
                            )
                        )
                    }

                    HStack(spacing: 14) {
                        DashboardCard(
                            title: "Tamamlanan Is",
                            value: "\(earningsSummary.completedTodayCount)"
                        )

                        DashboardCard(
                            title: "Aktif Hizmet",
                            value: "\(earningsSummary.activeTodayCount)"
                        )
                    }

                    providerScheduleSection
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

                    if let bookingActionNotice {
                        Text(bookingActionNotice)
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
                        Text("Bugunku Odak")
                            .font(.headline)
                        bullet("Musaitlik takvimini guncel tut ve yeni slotlarini kaydet.")
                        bullet("Okunmamis mesajlari hizlica kontrol et.")
                        bullet("Odeme onboarding ve IBAN bilgisini guncel tut.")
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
            .task {
                await loadProviderSummary()
            }
            .refreshable {
                await loadProviderSummary()
            }
        }
    }

    private var availabilitySelections: [String: [String]] {
        ProviderAvailabilityLogic.decodeSelections(storedAvailabilitySelections)
    }

    private var nextAvailabilityLabel: String {
        guard let next = ProviderAvailabilityLogic.nextAvailableDate(in: availabilitySelections) else {
            return "Planlanmadi"
        }

        return formattedDay(next)
    }

    private var providerScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bugunku Program")
                .font(.headline)

            if todaysBookings.isEmpty {
                emptyProviderCard(
                    title: "Bugun planlanmis is yok",
                    message: "Musaitlik takvimini guncel tutarak yeni talepler alabilirsin.",
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
            Text("Yaklasan Talepler")
                .font(.headline)

            if selectedRequestFilter == .all, !veryNearbyPendingRequests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Oncelikli Talepler", systemImage: "bolt.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(DS.Colors.primary)

                    ForEach(veryNearbyPendingRequests.prefix(2)) { booking in
                        providerBookingCard(
                            booking,
                            accent: DS.Colors.primary,
                            label: "Cok Yakin",
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
                .foregroundStyle(.secondary)
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

    private func loadProviderSummary() async {
        async let notificationsTask = session.deps.notificationService.listNotifications()
        async let conversationsTask = session.deps.chatService.listConversations()
        async let bookingsTask = session.deps.bookingService.listBookings()

        do {
            let (notifications, conversations, bookings) = try await (notificationsTask, conversationsTask, bookingsTask)
            self.conversations = conversations.conversations
            self.bookings = bookings
            async let unreadNotificationSummaryTask = session.deps.notificationService.unreadNotificationCount(
                fallback: notifications.notifications
            )
            async let unreadMessageSummaryTask = session.deps.chatService.unreadConversationCount(
                fallback: conversations.conversations
            )
            async let earningsSummaryTask = session.deps.bookingService.providerEarningsSummary(
                fallback: bookings
            )

            unreadNotifications = try await unreadNotificationSummaryTask
            unreadMessages = try await unreadMessageSummaryTask
            earningsSummaryOverride = try await earningsSummaryTask
            do {
                todayBookings = try await session.deps.bookingService.providerTodayBookings(fallback: bookings)
                pendingRequestBookings = try await session.deps.bookingService.providerPendingRequests(fallback: bookings)
            } catch {
                todayBookings = bookings.filter { isToday($0.startTime) }.sorted { $0.startTime < $1.startTime }
                pendingRequestBookings = bookings.filter {
                    let status = $0.status.uppercased()
                    return status == "REQUESTED" || status == "PENDING"
                }
                .sorted { $0.startTime < $1.startTime }
            }
            providerSummaryError = nil
        } catch {
            unreadNotifications = 0
            unreadMessages = 0
            conversations = []
            bookings = []
            todayBookings = []
            pendingRequestBookings = []
            earningsSummaryOverride = nil
            providerSummaryError = error.localizedDescription
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

    private func formattedTime(_ value: String) -> String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.timeStyle = .short
        return output.string(from: date)
    }

    private func isToday(_ value: String) -> Bool {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: value) else { return false }
        return Calendar.current.isDateInToday(date)
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
                    Text("Bu talep sana cok yakin. Hizli donus avantaj saglar.")
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
                    Text("Hizli onay gonderildi")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Spacer()
                }
                .padding(10)
                .background(Color.green.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack {
                Text(booking.provider.displayName)
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
            forProviderID: booking.provider.id,
            participantName: booking.provider.displayName,
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
                ? "Talep lokal olarak onaylandi. Backend endpoint'i hazir degil."
                : "Talep onaylandi."
        case "CANCELED":
            return fallback
                ? "Talep lokal olarak reddedildi. Backend endpoint'i hazir degil."
                : "Talep reddedildi."
        case "IN_PROGRESS":
            return fallback
                ? "Check-in lokal olarak baslatildi. Durum panelde guncellendi."
                : "Hizmet baslatildi."
        case "COMPLETED":
            return fallback
                ? "Hizmet lokal olarak tamamlandi. Kazanc ozeti guncellendi."
                : "Hizmet tamamlandi. Kazanc ozeti guncellendi."
        default:
            return fallback
                ? "Durum lokal olarak guncellendi."
                : "Durum guncellendi."
        }
    }

    private func notifyFamilyIfNeeded(for booking: BookingItem, status: String) async -> String {
        let normalizedStatus = status.uppercased()
        guard normalizedStatus == "CONFIRMED" || normalizedStatus == "CANCELED" || normalizedStatus == "COMPLETED" else {
            return ""
        }
        guard let parentUserID = booking.parentUserID, !parentUserID.isEmpty else {
            return " Aile bildirimi icin parent user bilgisi bulunamadi."
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
                ? " Aile onay bildirimi endpoint'i hazir degil."
                : " Aileye onay bildirimi gonderildi."
        case "CANCELED":
            return fallback
                ? " Aile red bildirimi endpoint'i hazir degil."
                : " Aileye red bildirimi gonderildi."
        default:
            return fallback
                ? " Aile tamamlanma bildirimi endpoint'i hazir degil."
                : " Aileye tamamlanma bildirimi gonderildi."
        }
    }

    private func familyPreviewText(for booking: BookingItem) -> String {
        let trimmedAbout = (booking.familyAbout ?? familyAbout).trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAbout.isEmpty {
            return trimmedAbout
        }
        let resolvedName = booking.familyDisplayName ?? familyDisplayName
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
                    Text(booking.provider.displayName)
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
                detailCard("Odeme", BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus).paymentSummaryText)
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
