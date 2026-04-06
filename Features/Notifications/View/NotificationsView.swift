//
//  NotificationsView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

private enum ProviderNotificationFilter: String, CaseIterable {
    case all = "Hepsi"
    case requests = "Talepler"
    case operations = "Operasyon"
    case system = "Sistem"
}

struct NotificationsView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferenceQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("accountPreferenceQuietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("accountPreferenceQuietHoursEnd") private var quietHoursEnd = "07:00"
    @AppStorage("accountProfileDisplayName") private var familyDisplayName = ""
    @AppStorage("accountProfileAboutFamily") private var familyAbout = ""
    @AppStorage(StoredLocationKeys.name) private var familyLocationName = StoredLocation.fallback.name
    @State private var items: [AppNotification] = []
    @State private var conversations: [ConversationItem] = []
    @State private var errorMessage: String?
    @State private var isSubmittingReadState = false
    @State private var showBookingList = false
    @State private var showChatList = false
    @State private var showCareRequests = false
    @State private var selectedConversation: ConversationItem?
    @State private var selectedConversationContextBadge: String?
    @State private var selectedBooking: BookingItem?
    @State private var selectedBookingContextBadge: String?
    @State private var selectedProviderFilter: ProviderNotificationFilter = .all

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Bildirimler")
                        .font(.largeTitle.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    if unreadCount > 0 {
                        Button("Tumunu Okundu Yap") {
                            Task {
                                await markAllAsRead()
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colors.primary)
                        .disabled(isSubmittingReadState)
                    }
                }
                .padding(.horizontal)

                if isProvider {
                    HStack {
                        Text("Yeni talepleri, ödeme akışlarını ve sistem uyarılarını buradan takip et.")
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                if isQuietHoursActive {
                    quietHoursNotice
                        .padding(.horizontal)
                }

                if isProvider {
                    providerNotificationFilterBar
                        .padding(.horizontal)
                }

                List {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    if filteredItems.isEmpty, errorMessage == nil {
                        emptyState(
                            title: isProvider ? "Bildirim yok" : "Bildirim yok",
                            systemImage: "bell",
                            description: isProvider
                                ? "Yeni talepler ve operasyon bildirimleri burada görünecek."
                                : "Henüz hiç bildirimin yok."
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    ForEach(filteredItems) { item in
                        Button {
                            openNotification(item)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(notificationIndicatorBackground(for: item))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: notificationIndicatorIcon(for: item))
                                            .foregroundStyle(notificationIndicatorForeground(for: item))
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(item.title)
                                            .foregroundStyle(DS.Colors.textPrimary)
                                            .multilineTextAlignment(.leading)
                                        if !item.read && !isQuietHoursActive {
                                            Text("Yeni")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(DS.Colors.accent.opacity(0.16))
                                                .foregroundStyle(DS.Colors.accent)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(item.body)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                        .multilineTextAlignment(.leading)

                                    if let highlight = notificationPresentation(for: item).highlightText {
                                        Label(highlight, systemImage: "sparkles")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(notificationAccentColor(for: item))
                                    }
                                    if let proximityBadge = notificationProximityBadge(for: item) {
                                        Text(proximityBadge)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(notificationAccentColor(for: item).opacity(0.12))
                                            .foregroundStyle(notificationAccentColor(for: item))
                                            .clipShape(Capsule())
                                    }

                                    HStack(spacing: 6) {
                                        Image(systemName: "person.text.rectangle")
                                        Text(contextPreviewText)
                                            .lineLimit(1)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DS.Colors.textSecondary)

                                    HStack(spacing: 6) {
                                        Image(systemName: destinationIcon(for: item))
                                        Text(formattedNotificationTimestamp(item.createdAt))
                                    }
                                    .font(.caption)
                                    .foregroundStyle(DS.Colors.textSecondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 2)
                            .padding(14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(DS.Colors.border.opacity(0.55), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if !item.read {
                                Button("Okundu") {
                                    Task {
                                        await markAsRead(item)
                                    }
                                }
                                .tint(DS.Colors.primary)
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Ac") {
                                openNotification(item)
                            }
                            .tint(DS.Colors.accent)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationDestination(isPresented: $showBookingList) {
                BookingListView()
            }
            .navigationDestination(isPresented: $showChatList) {
                ChatListView()
            }
            .navigationDestination(isPresented: $showCareRequests) {
                NotificationCareRequestsView()
            }
            .navigationDestination(item: $selectedBooking) { booking in
                BookingDetailView(
                    booking: booking,
                    contextBadgeText: selectedBookingContextBadge
                )
            }
            .navigationDestination(item: $selectedConversation) { conversation in
                ChatView(
                    chatID: conversation.id,
                    title: conversation.participantName,
                    contextBadgeText: selectedConversationContextBadge
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    private var unreadCount: Int {
        items.filter { !$0.read }.count
    }

    private var isProvider: Bool {
        session.me?.user.role == "PROVIDER"
    }

    private var isQuietHoursActive: Bool {
        QuietHoursLogic.isActive(
            enabled: quietHoursEnabled,
            start: quietHoursStart,
            end: quietHoursEnd
        )
    }

    private var filteredItems: [AppNotification] {
        guard isProvider else { return items }

        switch selectedProviderFilter {
        case .all:
            return items
        case .requests:
            return items.filter { providerNotificationCategory(for: $0) == .requests }
        case .operations:
            return items.filter { providerNotificationCategory(for: $0) == .operations }
        case .system:
            return items.filter { providerNotificationCategory(for: $0) == .system }
        }
    }

    private func loadData() async {
        async let notificationsTask = session.deps.notificationService.listNotifications()
        async let conversationsTask = session.deps.chatService.listConversations()

        do {
            let (notificationsResponse, conversationsResponse) = try await (notificationsTask, conversationsTask)
            items = notificationsResponse.notifications
            conversations = conversationsResponse.conversations
            errorMessage = nil
        } catch {
            items = []
            conversations = []
            errorMessage = error.localizedDescription
        }
    }

    private func markAsReadLocally(_ notification: AppNotification) {
        items = items.map { item in
            guard item.id == notification.id else { return item }
            return AppNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                createdAt: item.createdAt,
                read: true,
                type: item.type,
                bookingID: item.bookingID
            )
        }
    }

    private func markAllAsReadLocally() {
        items = items.map { item in
            AppNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                createdAt: item.createdAt,
                read: true,
                type: item.type,
                bookingID: item.bookingID
            )
        }
    }

    private func markAsRead(_ notification: AppNotification) async {
        let previousItems = items
        errorMessage = nil
        markAsReadLocally(notification)

        do {
            try await session.deps.notificationService.markAsRead(notificationID: notification.id)
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    return
                }
                items = previousItems
                errorMessage = error.localizedDescription
            default:
                items = previousItems
                errorMessage = error.localizedDescription
            }
        } catch {
            items = previousItems
            errorMessage = error.localizedDescription
        }
    }

    private func markAllAsRead() async {
        let previousItems = items
        errorMessage = nil
        isSubmittingReadState = true
        markAllAsReadLocally()
        defer { isSubmittingReadState = false }

        do {
            try await session.deps.notificationService.markAllAsRead()
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    return
                }
                items = previousItems
                errorMessage = error.localizedDescription
            default:
                items = previousItems
                errorMessage = error.localizedDescription
            }
        } catch {
            items = previousItems
            errorMessage = error.localizedDescription
        }
    }

    private func openNotification(_ notification: AppNotification) {
        Task {
            await markAsRead(notification)
        }

        switch DashboardRouting.destination(for: notification, conversations: conversations) {
        case .conversation(let conversation):
            selectedConversationContextBadge = notificationProximityBadge(for: notification)
            selectedBookingContextBadge = nil
            selectedConversation = conversation
        case .bookingDetail(let bookingID):
            selectedConversationContextBadge = nil
            selectedBookingContextBadge = notificationProximityBadge(for: notification)
            Task {
                await openBookingDetail(bookingID: bookingID)
            }
        case .bookings:
            selectedConversationContextBadge = nil
            selectedBookingContextBadge = nil
            showBookingList = true
        case .chatList:
            selectedConversationContextBadge = nil
            selectedBookingContextBadge = nil
            showChatList = true
        case .careRequests:
            selectedConversationContextBadge = nil
            selectedBookingContextBadge = nil
            showCareRequests = true
        case .notifications:
            break
        }
    }

    private func destinationIcon(for notification: AppNotification) -> String {
        switch DashboardRouting.destination(for: notification, conversations: conversations) {
        case .conversation:
            return "message"
        case .bookingDetail:
            return "calendar.badge.checkmark"
        case .bookings:
            return "calendar"
        case .chatList:
            return "bubble.left.and.bubble.right"
        case .careRequests:
            return "list.bullet.rectangle"
        case .notifications:
            return "clock"
        }
    }

    private func openBookingDetail(bookingID: String) async {
        do {
            if let booking = try await session.deps.bookingService.booking(id: bookingID) {
                selectedBooking = booking
            } else {
                showBookingList = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showBookingList = true
        }
    }

    private func notificationIndicatorBackground(for item: AppNotification) -> Color {
        if item.read {
            return DS.Colors.border
        }

        let tint = notificationAccentColor(for: item)
        return isQuietHoursActive ? tint.opacity(0.12) : tint.opacity(0.18)
    }

    private func notificationIndicatorForeground(for item: AppNotification) -> Color {
        if item.read {
            return DS.Colors.textSecondary
        }

        return notificationAccentColor(for: item)
    }

    private func notificationIndicatorIcon(for item: AppNotification) -> String {
        if item.read {
            return "bell"
        }

        if isQuietHoursActive {
            return "moon.zzz.fill"
        }

        return notificationPresentation(for: item).icon
    }

    private func notificationAccentColor(for item: AppNotification) -> Color {
        switch notificationPresentation(for: item).tintKey {
        case "green":
            return .green
        case "red":
            return .red
        case "blue":
            return .blue
        default:
            return isQuietHoursActive ? .indigo : DS.Colors.accent
        }
    }

    private func notificationPresentation(for item: AppNotification) -> FamilyNotificationPresentation {
        FamilyNotificationPresentation.make(type: item.type)
    }

    private func notificationProximityBadge(for item: AppNotification) -> String? {
        FamilyNotificationPresentation.proximityBadgeText(from: item.body)
    }

    private var quietHoursNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.indigo)
            Text("Sessiz saatler acik. Bildirimler burada görünmeye devam eder, ama dikkat cekici vurgular azaltilir.")
                .font(.footnote)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var contextPreviewText: String {
        if isProvider {
            if let displayName = session.me?.user.displayName, !displayName.isEmpty {
                return "\(displayName) • bakıcı hesabı"
            }
            return "Bakıcı hesabı • operasyon akışı"
        }

        let trimmedAbout = familyAbout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAbout.isEmpty {
            return trimmedAbout
        }
        if !familyDisplayName.isEmpty {
            return "\(familyDisplayName) • \(familyLocationName)"
        }
        return familyLocationName
    }

    private var providerNotificationFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ProviderNotificationFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedProviderFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedProviderFilter == filter ? DS.Colors.primary : .white)
                            .foregroundStyle(selectedProviderFilter == filter ? .white : DS.Colors.textPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func formattedNotificationTimestamp(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }

        let calendar = Calendar.current
        let locale = Locale(identifier: "tr_TR")

        if calendar.isDateInToday(date) {
            return date.formatted(.dateTime.locale(locale).hour().minute())
        }

        if calendar.isDateInYesterday(date) {
            let timeText = date.formatted(.dateTime.locale(locale).hour().minute())
            return "Dün \(timeText)"
        }

        return date.formatted(
            .dateTime
                .locale(locale)
                .day()
                .month(.wide)
                .hour()
                .minute()
        )
    }

    private func parseISODate(_ value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private enum ProviderNotificationCategory {
        case requests
        case operations
        case system
    }

    private func providerNotificationCategory(for notification: AppNotification) -> ProviderNotificationCategory {
        let haystack = "\(notification.title) \(notification.body) \(notification.type ?? "")".lowercased()

        if haystack.contains("booking_confirmed")
            || haystack.contains("booking_rejected")
            || haystack.contains("talep")
            || haystack.contains("rezervasyon") {
            return .requests
        }

        if haystack.contains("booking_completed")
            || haystack.contains("ödeme")
            || haystack.contains("odeme")
            || haystack.contains("checkout")
            || haystack.contains("hesaba geçecek") {
            return .operations
        }

        return .system
    }

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(DS.Colors.accent)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(DS.Colors.textPrimary)
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Colors.textSecondary)
            Text("Önerilen adım: Yeni gelişmeler oldukça bu ekran otomatik olarak dolacak.")
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

private struct NotificationCareRequestsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var parentRequests: [CareRequestItem] = []
    @State private var providerRequests: [CareRequestItem] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(isProvider
                     ? "Burada ailelerden gelen açık talepleri daha rahat inceleyebilirsin."
                     : "Burada aday başvurularını ve açık taleplerini tek ekranda görebilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if visibleRequests.isEmpty {
                    emptyState(
                        title: isProvider ? "Açık talep yok" : "Gösterilecek talep yok",
                        systemImage: "tray",
                        description: isProvider
                            ? "Aileler yeni talep oluşturduğunda burada görünecek."
                            : "Yeni adaylar geldiğinde burada görünecek."
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(visibleRequests) { request in
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(localizedCareService(request.service))
                                            .font(.headline)
                                            .foregroundStyle(DS.Colors.textPrimary)
                                        Text("\(formattedDate(request.startAt)) • \(formattedTime(request.startAt)) - \(formattedTime(request.endAt))")
                                            .font(.subheadline)
                                            .foregroundStyle(DS.Colors.textSecondary)
                                        Text(request.locationName)
                                            .font(.caption)
                                            .foregroundStyle(DS.Colors.textSecondary)
                                    }
                                    Spacer()
                                    Text(statusLabel(for: request))
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(statusColor(for: request).opacity(0.14))
                                        .foregroundStyle(statusColor(for: request))
                                        .clipShape(Capsule())
                                }

                                if !request.note.isEmpty {
                                    Text(request.note)
                                        .font(.subheadline)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                }

                                if isProvider {
                                    infoRow(title: "Aday", value: "\(request.candidates.count)")
                                } else if request.candidates.isEmpty {
                                    infoRow(title: "Durum", value: "Henüz aday olan bakıcı yok.")
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Aday Olan Bakıcılar")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(DS.Colors.textSecondary)

                                        ForEach(request.candidates) { candidate in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(candidate.providerDisplayName)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(DS.Colors.textPrimary)
                                                Text("Başvuru zamanı: \(formattedTime(candidate.appliedAt))")
                                                    .font(.caption)
                                                    .foregroundStyle(DS.Colors.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(10)
                                            .background(DS.Colors.background)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle(isProvider ? "Aile Talepleri" : "Aile Talepleri")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCareRequests()
        }
        .refreshable {
            await loadCareRequests()
        }
    }

    private var isProvider: Bool {
        session.me?.user.role == "PROVIDER"
    }

    private var visibleRequests: [CareRequestItem] {
        (isProvider ? providerRequests : parentRequests).sorted { lhs, rhs in
            lhs.startAt < rhs.startAt
        }
    }

    private func loadCareRequests() async {
        guard let userID = session.me?.user.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if isProvider {
                providerRequests = try await session.deps.bookingService.listProviderCareRequests(providerUserID: userID)
                parentRequests = []
            } else {
                parentRequests = try await session.deps.bookingService.listParentCareRequests(parentUserID: userID)
                providerRequests = []
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            parentRequests = []
            providerRequests = []
        }
    }

    private func localizedCareService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first
            ?? service.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func statusLabel(for request: CareRequestItem) -> String {
        if request.isMatched {
            return "Eşleşti"
        }
        if !request.candidates.isEmpty && !isProvider {
            return "\(request.candidates.count) aday"
        }
        return "Açık"
    }

    private func statusColor(for request: CareRequestItem) -> Color {
        if request.isMatched {
            return .green
        }
        if !request.candidates.isEmpty && !isProvider {
            return DS.Colors.primary
        }
        return .orange
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func formattedDate(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedTime(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}

final class NotificationService {
    private struct Empty: Encodable {}
    private struct RegisterPushTokenReq: Encodable {
        let token: String
        let platform: String
    }
    private struct PushTokenMutationResponse: Decodable {
        let ok: Bool
    }
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func listNotifications() async throws -> NotificationsResponse {
        return try await api.request(
            "v1/notifications",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
    }

    func unreadNotificationCount(fallback notifications: [AppNotification]) async throws -> Int {
        var lastError: Error?

        for candidate in ProviderDashboardSummaryPlan.unreadNotificationCandidates() {
            do {
                let response: NotificationUnreadSummaryResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.unreadCount
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

        _ = lastError
        return notifications.filter { !$0.read }.count
    }

    func markAsRead(notificationID: String) async throws {
        var lastError: Error?

        for candidate in NotificationMutationPlan.markReadCandidates(notificationID: notificationID) {
            do {
                if candidate.sendsReadBody {
                    let _: NotificationMutationResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: NotificationReadReq(read: true),
                        needsAuth: true
                    )
                } else {
                    let _: NotificationMutationResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: Optional<Empty>.none,
                        needsAuth: true
                    )
                }
                return
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if NotificationMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
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

    func markAllAsRead() async throws {
        var lastError: Error?

        for candidate in NotificationMutationPlan.markAllReadCandidates() {
            do {
                if candidate.sendsReadBody {
                    let _: NotificationMutationResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: NotificationReadAllReq(read: true),
                        needsAuth: true
                    )
                } else {
                    let _: NotificationMutationResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: Optional<Empty>.none,
                        needsAuth: true
                    )
                }
                return
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if NotificationMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
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

    func registerPushToken(_ token: String, platform: String) async throws {
        let _: PushTokenMutationResponse = try await api.request(
            "v1/me/push-token",
            method: "POST",
            body: RegisterPushTokenReq(token: token, platform: platform),
            needsAuth: true
        )
    }

    func sendBookingStatusNotification(
        parentUserID: String,
        providerName: String,
        bookingID: String,
        service: String,
        status: String,
        startAt: String? = nil,
        familyDisplayName: String? = nil,
        proximityText: String? = nil
    ) async throws {
        var lastError: Error?
        let content = BookingStatusNotificationContent.make(
            providerName: providerName,
            service: service,
            status: status,
            startAt: startAt,
            familyDisplayName: familyDisplayName,
            proximityText: proximityText
        )
        let body = CreateNotificationReq(
            userID: parentUserID,
            title: content.title,
            body: content.body,
            type: content.type,
            bookingID: bookingID
        )

        for candidate in NotificationMutationPlan.bookingCompletedCandidates(parentUserID: parentUserID) {
            do {
                let _: NotificationMutationResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: body,
                    needsAuth: true
                )
                return
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if NotificationMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
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

private struct NotificationMutationResponse: Decodable {
    let ok: Bool?
}

private struct NotificationUnreadSummaryResponse: Decodable {
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case unreadCount
        case totalUnread
        case count
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unreadCount =
            try container.decodeIfPresent(Int.self, forKey: .unreadCount)
            ?? container.decodeIfPresent(Int.self, forKey: .totalUnread)
            ?? container.decodeIfPresent(Int.self, forKey: .count)
            ?? 0
    }
}

private struct NotificationReadReq: Encodable {
    let read: Bool
}

private struct NotificationReadAllReq: Encodable {
    let read: Bool
}

private struct CreateNotificationReq: Encodable {
    let userID: String
    let title: String
    let body: String
    let type: String
    let bookingID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case title
        case body
        case type
        case bookingID = "booking_id"
    }
}
