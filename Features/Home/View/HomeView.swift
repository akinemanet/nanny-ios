//
//  HomeView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI
import Combine

private enum ParentCareRequestSort: String, CaseIterable {
    case newest = "En Yeni"
    case mostCandidates = "En Çok Aday"
    case openFirst = "Önce Açık Olanlar"
}

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("accountPreferenceQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("accountPreferenceQuietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("accountPreferenceQuietHoursEnd") private var quietHoursEnd = "07:00"
    @AppStorage("accountProfileDisplayName") private var familyDisplayName = ""
    @AppStorage("accountProfileAboutFamily") private var familyAbout = ""
    @AppStorage(StoredLocationKeys.name) private var familyLocationName = StoredLocation.fallback.name
    @StateObject private var viewModel: HomeDashboardViewModel
    @State private var showBookingList = false
    @State private var showChatList = false
    @State private var selectedConversation: ConversationItem?
    @State private var selectedConversationContextBadge: String?
    @State private var showNotifications = false
    @State private var selectedBooking: BookingItem?
    @State private var selectedBookingContextBadge: String?
    @State private var checkoutURL: URL?
    @State private var checkoutError: String?
    @State private var isLoadingCheckout = false
    @State private var checkoutBookingID: String?
    @State private var showCheckout = false
    @State private var careRequests: [CareRequestItem] = []
    @State private var careRequestError: String?
    @State private var careRequestNotice: String?
    @State private var isLoadingCareRequests = false
    @State private var showCreateCareRequest = false
    @State private var showAllCareRequests = false
    @State private var selectedCandidateProvider: BrowseProvider?

    @MainActor
    init() {
        let deps = AppDependencies.live()
        _viewModel = StateObject(wrappedValue: HomeDashboardViewModel(
            bookingService: deps.bookingService,
            providerService: deps.providerService,
            notificationService: deps.notificationService,
            chatService: deps.chatService
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeCard
                    summaryGrid
                    quickActions
                    careRequestsSection
                    upcomingSection
                    conversationsSection
                    favoritesSection
                    notificationsSection
                }
                .padding()
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DS.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ana Sayfa")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
            .navigationDestination(isPresented: $showBookingList) {
                BookingListView()
            }
            .navigationDestination(isPresented: $showChatList) {
                ChatListView()
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView()
            }
            .navigationDestination(isPresented: $showAllCareRequests) {
                ParentCareRequestsListView(
                    careRequests: $careRequests,
                    selectedCandidateProvider: $selectedCandidateProvider,
                    onApprove: { candidate, request in
                        Task {
                            await approve(candidate: candidate, for: request)
                        }
                    }
                )
            }
            .navigationDestination(item: $selectedBooking) { booking in
                BookingDetailView(
                    booking: booking,
                    contextBadgeText: selectedBookingContextBadge
                ) { updatedBooking in
                    viewModel.applyBookingUpdate(updatedBooking)
                    if updatedBooking.status.uppercased() == "CANCELED" || updatedBooking.status.uppercased() == "CANCELLED" {
                        selectedBooking = updatedBooking
                    }
                }
            }
            .navigationDestination(item: $selectedConversation) { conversation in
                ChatView(
                    chatID: conversation.id,
                    title: conversation.participantName,
                    contextBadgeText: selectedConversationContextBadge,
                    onConversationRead: {
                        viewModel.markConversationReadLocally(chatID: conversation.id)
                    },
                    onConversationUpdated: { updatedConversation in
                        viewModel.applyConversationUpdate(updatedConversation)
                    }
                )
            }
            .navigationDestination(item: $selectedCandidateProvider) { provider in
                NannyProfileView(provider: provider)
            }
            .sheet(isPresented: $showCheckout, onDismiss: {
                Task {
                    await viewModel.load()
                }
            }) {
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
            .sheet(isPresented: $showCreateCareRequest) {
                NavigationStack {
                    ParentCareRequestComposer { draft in
                        try await createCareRequest(draft)
                    }
                }
            }
            .onAppear {
                Task {
                    viewModel.replaceServicesIfNeeded(
                        bookingService: session.deps.bookingService,
                        providerService: session.deps.providerService,
                        notificationService: session.deps.notificationService,
                        chatService: session.deps.chatService
                    )
                    await viewModel.load()
                    await loadCareRequests()
                }
            }
            .task {
                viewModel.replaceServicesIfNeeded(
                    bookingService: session.deps.bookingService,
                    providerService: session.deps.providerService,
                    notificationService: session.deps.notificationService,
                    chatService: session.deps.chatService
                )
                await viewModel.load()
                await loadCareRequests()
            }
            .refreshable {
                viewModel.replaceServicesIfNeeded(
                    bookingService: session.deps.bookingService,
                    providerService: session.deps.providerService,
                    notificationService: session.deps.notificationService,
                    chatService: session.deps.chatService
                )
                await viewModel.load()
                await loadCareRequests()
            }
            .onReceive(NotificationCenter.default.publisher(for: .appDidOpenRemoteNotification)) { payload in
                guard let notification = payload.object as? AppNotification else { return }
                Task {
                    await handleRemoteNotificationOpen(notification)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active, session.isLoggedIn else { return }
                Task {
                    viewModel.replaceServicesIfNeeded(
                        bookingService: session.deps.bookingService,
                        providerService: session.deps.providerService,
                        notificationService: session.deps.notificationService,
                        chatService: session.deps.chatService
                    )
                    await viewModel.load()
                    await loadCareRequests()
                }
            }
        }
    }

    private var welcomeCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(greetingTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text("Bugünkü planını, rezervasyonlarını ve yeni bildirimlerini tek ekranda takip et.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    homeBadge(title: "Rol", value: session.me?.user.role == "PROVIDER" ? "Bakıcı" : "Aile")
                    homeBadge(title: "Telefon", value: session.me?.user.phone ?? "-")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [DS.Colors.primary, DS.Colors.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
        }
        .background(Color.clear)
        .overlay(Color.clear)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: "Aktif Rezervasyon",
                value: "\(viewModel.activeBookings.count)",
                systemImage: "calendar.badge.clock",
                tint: DS.Colors.primary
            )

            summaryCard(
                title: "Tamamlanan",
                value: "\(viewModel.completedBookings.count)",
                systemImage: "checkmark.circle",
                tint: .green
            )

            summaryCard(
                title: "Favoriler",
                value: "\(viewModel.favorites.count)",
                systemImage: "heart.fill",
                tint: .pink
            )

            summaryCard(
                title: isQuietHoursActive ? "Sessiz Mod" : "Okunmamış",
                value: "\(viewModel.unreadNotifications)",
                systemImage: isQuietHoursActive ? "moon.zzz.fill" : "bell.badge.fill",
                tint: isQuietHoursActive ? .indigo : DS.Colors.accent
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Hızlı İşlemler")

            HStack(spacing: 12) {
                NavigationLink {
                    BrowseView()
                } label: {
                    quickActionCard(
                        title: "Bakıcı Keşfet",
                        subtitle: "Yeni profillere göz at",
                        systemImage: "magnifyingglass"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BookingListView()
                } label: {
                    quickActionCard(
                        title: "Rezervasyonlar",
                        subtitle: "Takvimini kontrol et",
                        systemImage: "calendar"
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                NavigationLink {
                    NotificationsView()
                } label: {
                    quickActionCard(
                        title: "Bildirimler",
                        subtitle: "Güncel gelişmeleri gör",
                        systemImage: "bell"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AccountView()
                } label: {
                    quickActionCard(
                        title: "Hesabım",
                        subtitle: "Kartlar ve ayarlar",
                        systemImage: "person.crop.circle"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var careRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Hızlı Bakıcı Talebi")
                Spacer()
                if careRequests.count > 3 {
                    Button("Tümünü Gör") {
                        showAllCareRequests = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Colors.primary)
                }
                Button {
                    showCreateCareRequest = true
                } label: {
                    Label("Talep Oluştur", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(DS.Colors.primary)
            }

            if let careRequestNotice {
                Text(careRequestNotice)
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.primary)
            }

            if let careRequestError {
                errorCard(message: careRequestError)
            } else if isLoadingCareRequests && careRequests.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else if careRequests.isEmpty {
                emptyCard(
                    title: "Henüz acil talep oluşturmadın",
                    message: "Akşam için ya da belirli bir gün-saat aralığı için hızlıca talep açabilir, aday olan bakıcıyı onaylayabilirsin.",
                    systemImage: "clock.badge.exclamationmark"
                )
            } else {
                ForEach(careRequests.prefix(3)) { request in
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
                                Text(careRequestStatusLabel(for: request))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(careRequestStatusColor(for: request).opacity(0.14))
                                    .foregroundStyle(careRequestStatusColor(for: request))
                                    .clipShape(Capsule())
                            }

                            if !parentLiveSignals(for: request).isEmpty {
                                liveSignalsRow(parentLiveSignals(for: request))
                            }

                            if !request.note.isEmpty {
                                Text(request.note)
                                    .font(.subheadline)
                                    .foregroundStyle(DS.Colors.textSecondary)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(DS.Colors.primary)
                                Text(parentSuggestedNextStep(for: request))
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(DS.Colors.primary)
                            }
                            .padding(.horizontal, 2)

                            if request.candidates.isEmpty {
                                Text("Henüz aday olan bakıcı yok.")
                                    .font(.footnote)
                                    .foregroundStyle(DS.Colors.textSecondary)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Aday Olan Bakıcılar")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(DS.Colors.textSecondary)

                                    ForEach(request.candidates) { candidate in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Button {
                                                    selectedCandidateProvider = BrowseProvider(
                                                        id: candidate.providerUserID,
                                                        displayName: candidate.providerDisplayName,
                                                        rating: 0,
                                                        hourlyRate: 0,
                                                        payoutStatus: "PENDING",
                                                        age: 0,
                                                        gender: "",
                                                        locationName: "",
                                                        distanceText: "",
                                                        photoURL: nil,
                                                        latitude: nil,
                                                        longitude: nil,
                                                        categories: [],
                                                        reviewCount: 0,
                                                        completedSittings: 0,
                                                        availableDates: [],
                                                        availableStartHour: 9,
                                                        availableEndHour: 18
                                                    )
                                                } label: {
                                                    Text(candidate.providerDisplayName)
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundStyle(DS.Colors.primary)
                                                }
                                                .buttonStyle(.plain)
                                                Text("Aday oldu: \(formattedTime(candidate.appliedAt))")
                                                    .font(.caption)
                                                    .foregroundStyle(DS.Colors.textSecondary)
                                            }
                                            Spacer()
                                            if request.assignedProviderUserID == candidate.providerUserID {
                                                Text("Seçildi")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.green)
                                            } else if request.isOpen {
                                                Button("Onayla") {
                                                    Task {
                                                        await approve(candidate: candidate, for: request)
                                                    }
                                                }
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(DS.Colors.primary)
                                            }
                                        }
                                        .padding(10)
                                        .background(DS.Colors.background)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                }
                            }

                            HStack(spacing: 10) {
                                secondaryActionButton(
                                    title: "Talebi Aç",
                                    systemImage: "list.bullet.rectangle"
                                ) {
                                    showAllCareRequests = true
                                }

                                if !request.candidates.isEmpty, request.isOpen {
                                    secondaryActionButton(
                                        title: "Adayları İncele",
                                        systemImage: "person.2"
                                    ) {
                                        showAllCareRequests = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Sıradaki Rezervasyonlar")

            if viewModel.isLoading && viewModel.bookings.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else if let errorMessage = viewModel.errorMessage, viewModel.bookings.isEmpty {
                errorCard(message: errorMessage)
            } else if viewModel.activeBookings.isEmpty {
                emptyCard(
                    title: "Planlanmış rezervasyonun yok",
                    message: "Uygun bakıcıları keşfedip yeni bir rezervasyon oluşturabilirsin.",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                ForEach(viewModel.activeBookings.prefix(3)) { booking in
                    bookingCard(for: booking)
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Favori Bakıcılar")

            if viewModel.favorites.isEmpty {
                emptyCard(
                    title: "Favori bakıcı eklemedin",
                    message: "Beğendiğin profilleri favorilere ekleyip burada hızlıca ulaşabilirsin.",
                    systemImage: "heart"
                )
            } else {
                ForEach(viewModel.favorites.prefix(3)) { favorite in
                    AppCard {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(.pink.opacity(0.14))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(.pink)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(favorite.displayName)
                                    .font(.headline)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Text("Puan: \(String(format: "%.1f", favorite.rating))")
                                    .font(.subheadline)
                                    .foregroundStyle(DS.Colors.textSecondary)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var conversationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Son Konuşmalar")
                Spacer()
                Button("Tümünü Gör") {
                    showChatList = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.primary)
            }

            if viewModel.conversations.isEmpty {
                emptyCard(
                    title: "Aktif konuşma yok",
                    message: "Mesajlaşmaların başladığında son konuşmalar burada görünecek.",
                    systemImage: "bubble.left.and.bubble.right"
                )
            } else {
                ForEach(viewModel.conversations.prefix(3)) { conversation in
                    Button {
                        selectedConversation = conversation
                    } label: {
                        AppCard {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(conversationAccent(for: conversation).opacity(0.14))
                                    .frame(width: 46, height: 46)
                                    .overlay {
                                        Text(conversationInitials(for: conversation))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(conversationAccent(for: conversation))
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(conversation.participantName)
                                            .font(.headline)
                                            .foregroundStyle(DS.Colors.textPrimary)
                                            .lineLimit(1)
                                        if conversation.unreadCount > 0 {
                                            Text("\(conversation.unreadCount)")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(dashboardUnreadConversationBackground)
                                                .foregroundStyle(dashboardUnreadConversationTint)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    if let badge = conversationBadge(for: conversation) {
                                        Text(badge)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(conversationAccent(for: conversation).opacity(0.14))
                                            .foregroundStyle(conversationAccent(for: conversation))
                                            .clipShape(Capsule())
                                    }
                                    if let activityCue = conversationActivityCue(for: conversation) {
                                        Text(activityCue)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(DS.Colors.accent.opacity(0.12))
                                            .foregroundStyle(DS.Colors.accent)
                                            .clipShape(Capsule())
                                    }

                                    Text(conversation.lastMessage)
                                        .font(.subheadline)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                        .lineLimit(2)

                                    Text(formattedConversationTime(conversation.lastMessageAt))
                                        .font(.caption)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                }

                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Son Bildirimler")
                Spacer()
                Button("Tümünü Gör") {
                    showNotifications = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.primary)
            }

            if isQuietHoursActive {
                HStack(spacing: 10) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.indigo)
                    Text("Sessiz saatler aktif. Bildirimler burada özetleniyor, ama banner ve ses azaltıldı.")
                        .font(.footnote)
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if viewModel.notifications.isEmpty {
                emptyCard(
                    title: "Yeni bildirim yok",
                    message: "Rezervasyon ve mesaj gelişmeleri burada görünecek.",
                    systemImage: "bell.slash"
                )
            } else {
                ForEach(viewModel.notifications.prefix(3)) { item in
                    Button {
                        openDestination(for: item)
                    } label: {
                        AppCard {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(item.read ? DS.Colors.border : dashboardNotificationBackground(for: item))
                                    .frame(width: 42, height: 42)
                                    .overlay {
                                        Image(systemName: item.read ? "bell" : dashboardNotificationIcon(for: item))
                                            .foregroundStyle(item.read ? DS.Colors.textSecondary : dashboardNotificationTint(for: item))
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundStyle(DS.Colors.textPrimary)
                                        if !item.read {
                                            Text(dashboardNotificationBadgeText(for: item))
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(dashboardNotificationTint(for: item).opacity(0.14))
                                                .foregroundStyle(dashboardNotificationTint(for: item))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(item.body)
                                        .font(.subheadline)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                        .lineLimit(2)
                                    if let highlight = dashboardNotificationPresentation(for: item).highlightText {
                                        Label(highlight, systemImage: "sparkles")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(dashboardNotificationTint(for: item))
                                    }
                                    if let proximityBadge = dashboardNotificationProximityBadge(for: item) {
                                        Text(proximityBadge)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(dashboardNotificationTint(for: item).opacity(0.12))
                                            .foregroundStyle(dashboardNotificationTint(for: item))
                                            .clipShape(Capsule())
                                    }
                                    if let activityCue = notificationActivityCue(for: item) {
                                        Text(activityCue)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(DS.Colors.accent.opacity(0.12))
                                            .foregroundStyle(DS.Colors.accent)
                                            .clipShape(Capsule())
                                    }
                                    familyContextLine
                                    Text(item.createdAt)
                                        .font(.caption)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                }

                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var greetingTitle: String {
        if let email = session.me?.user.email, !email.isEmpty {
            return "Hoş geldin, \(email)"
        }
        return "Hoş geldin"
    }

    private var isQuietHoursActive: Bool {
        QuietHoursLogic.isActive(
            enabled: quietHoursEnabled,
            start: quietHoursStart,
            end: quietHoursEnd
        )
    }

    private var unreadNotificationTint: Color {
        isQuietHoursActive ? .indigo : DS.Colors.accent
    }

    private var familyPreviewText: String {
        let trimmedAbout = familyAbout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAbout.isEmpty {
            return trimmedAbout
        }
        if !familyDisplayName.isEmpty {
            return "\(familyDisplayName) • \(familyLocationName)"
        }
        return familyLocationName
    }

    private var familyContextLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.text.rectangle")
            Text(familyPreviewText)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(DS.Colors.textSecondary)
    }

    private func dashboardNotificationTint(for item: AppNotification) -> Color {
        switch dashboardNotificationPresentation(for: item).tintKey {
        case "green":
            return .green
        case "red":
            return .red
        case "blue":
            return .blue
        default:
            return unreadNotificationTint
        }
    }

    private func dashboardNotificationBackground(for item: AppNotification) -> Color {
        dashboardNotificationTint(for: item).opacity(isQuietHoursActive ? 0.12 : 0.18)
    }

    private func dashboardNotificationIcon(for item: AppNotification) -> String {
        if isQuietHoursActive {
            return "moon.zzz.fill"
        }

        return dashboardNotificationPresentation(for: item).icon
    }

    private func dashboardNotificationBadgeText(for item: AppNotification) -> String {
        dashboardNotificationPresentation(for: item).badgeText
    }

    private func dashboardNotificationPresentation(for item: AppNotification) -> FamilyNotificationPresentation {
        FamilyNotificationPresentation.make(type: item.type)
    }

    private func dashboardNotificationProximityBadge(for item: AppNotification) -> String? {
        FamilyNotificationPresentation.proximityBadgeText(from: item.body)
    }

    private func notificationActivityCue(for item: AppNotification) -> String? {
        if !item.read {
            return "Yeni gelişme"
        }

        guard let date = parseISODate(item.createdAt) else { return nil }
        if Date().timeIntervalSince(date) < 6 * 60 * 60 {
            return "Yakın zamanda geldi"
        }

        return nil
    }

    private var unreadNotificationBackground: Color {
        isQuietHoursActive ? DS.Colors.primary.opacity(0.12) : DS.Colors.accent.opacity(0.18)
    }

    private var unreadNotificationIcon: String {
        isQuietHoursActive ? "moon.zzz.fill" : "bell.badge.fill"
    }

    private var dashboardUnreadConversationTint: Color {
        isQuietHoursActive ? .indigo : DS.Colors.accent
    }

    private var dashboardUnreadConversationBackground: Color {
        isQuietHoursActive ? .indigo.opacity(0.14) : DS.Colors.accent.opacity(0.16)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .foregroundStyle(DS.Colors.textPrimary)
    }

    private func summaryCard(title: String, value: String, systemImage: String, tint: Color) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.textPrimary)

                Text(title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func quickActionCard(title: String, subtitle: String, systemImage: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(DS.Colors.primary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        }
    }

    private func homeBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func bookingCard(for booking: BookingItem) -> some View {
        let presentation = bookingPresentation(for: booking)
        return AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DS.Colors.primary.opacity(0.12))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "calendar")
                                .foregroundStyle(DS.Colors.primary)
                        }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(localizedService(booking.service))
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text(booking.provider.displayName)
                            .font(.subheadline)
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text("\(formattedDate(booking.startTime)) • \(formattedTime(booking.startTime))")
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                        familyContextLine
                    }

                    Spacer()

                    Text(presentation.localizedStatus)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(toneBackground(for: presentation.statusTone))
                        .foregroundStyle(toneColor(for: presentation.statusTone))
                        .clipShape(Capsule())
                }

                if !bookingActivityCues(for: booking).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(bookingActivityCues(for: booking), id: \.self) { cue in
                                Text(cue)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(DS.Colors.primary.opacity(0.10))
                                    .foregroundStyle(DS.Colors.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    secondaryActionButton(
                        title: "Rezervasyonu Aç",
                        systemImage: "arrow.right.circle"
                    ) {
                        selectedBookingContextBadge = nil
                        selectedBooking = booking
                    }

                    secondaryActionButton(
                        title: "Mesaja Git",
                        systemImage: "message"
                    ) {
                        openConversation(for: booking)
                    }
                }

                if presentation.canPay {
                    Button {
                        Task {
                            await openCheckout(for: booking)
                        }
                    } label: {
                        HStack {
                            if isLoadingCheckout, checkoutBookingID == booking.id {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isLoadingCheckout && checkoutBookingID == booking.id ? "Bağlantı Hazırlanıyor" : "Ödemeye Devam Et")
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: DS.Size.buttonHeight)
                    }
                    .background(DS.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
                    .disabled(isLoadingCheckout)
                }

                if checkoutBookingID == booking.id, let checkoutError {
                    Text(checkoutError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func emptyCard(title: String, message: String, systemImage: String) -> some View {
        AppCard {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundStyle(DS.Colors.accent)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                Text(emptyCardSuggestedStep(for: title))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.Colors.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func errorCard(message: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Şu anda yüklenemedi")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("Önerilen adım: Birkaç saniye sonra tekrar dene. Sorun sürerse ekranı yenile.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.Colors.primary)
                Button("Tekrar Dene") {
                    Task {
                        await viewModel.load()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.primary)
            }
        }
    }

    private func emptyCardSuggestedStep(for title: String) -> String {
        let normalized = title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")).lowercased()

        if normalized.contains("talep") {
            return "Önerilen adım: Yeni bir talep oluşturup başvuruları burada takip et."
        }
        if normalized.contains("rezervasyon") {
            return "Önerilen adım: Uygun bakıcıları keşfedip yeni bir rezervasyon başlat."
        }
        if normalized.contains("favori") {
            return "Önerilen adım: Beğendiğin bir profili favorilere ekleyip burada hızlıca ulaş."
        }
        if normalized.contains("konusma") || normalized.contains("konuşma") {
            return "Önerilen adım: Bir bakıcıyla mesajlaşmaya başladığında son konuşmalar burada görünür."
        }
        if normalized.contains("bildirim") {
            return "Önerilen adım: Yeni mesajlar ve rezervasyon gelişmeleri burada toplanır."
        }

        return "Önerilen adım: İlgili işlemi başlatınca bu alan otomatik olarak dolacak."
    }

    private func secondaryActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(DS.Colors.background)
            .foregroundStyle(DS.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }
        let out = DateFormatter()
        out.locale = Locale(identifier: "tr_TR")
        out.dateStyle = .medium
        return out.string(from: date)
    }

    private func formattedTime(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }
        let out = DateFormatter()
        out.locale = Locale(identifier: "tr_TR")
        out.timeStyle = .short
        return out.string(from: date)
    }

    private func formattedConversationTime(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }

        let calendar = Calendar(identifier: .gregorian)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")

        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        }

        formatter.dateStyle = .short
        formatter.timeStyle = .none
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

    private func conversationInitials(for conversation: ConversationItem) -> String {
        let parts = conversation.participantName
            .split(separator: " ")
            .prefix(2)
        let initials = parts.compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "?" : initials
    }

    private func conversationBadge(for conversation: ConversationItem) -> String? {
        if let participantID = conversation.participantID,
           viewModel.activeBookings.contains(where: { $0.provider.id == participantID }) {
            return "Aktif Rezervasyon"
        }

        if let participantID = conversation.participantID,
           viewModel.favorites.contains(where: { $0.providerId == participantID }) {
            return "Favori Bakıcı"
        }

        return nil
    }

    private func conversationActivityCue(for conversation: ConversationItem) -> String? {
        if conversation.unreadCount > 0 {
            return "Yeni mesaj"
        }

        guard let date = parseISODate(conversation.lastMessageAt) else { return nil }
        if Date().timeIntervalSince(date) < 6 * 60 * 60 {
            return "Az önce hareket oldu"
        }

        return nil
    }

    private func conversationAccent(for conversation: ConversationItem) -> Color {
        if let participantID = conversation.participantID,
           viewModel.activeBookings.contains(where: { $0.provider.id == participantID }) {
            return DS.Colors.primary
        }

        if let participantID = conversation.participantID,
           viewModel.favorites.contains(where: { $0.providerId == participantID }) {
            return .pink
        }

        return DS.Colors.accent
    }

    private func localizedService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first
            ?? service.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func bookingPresentation(for booking: BookingItem) -> BookingStatusPresentation {
        BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus)
    }

    private func bookingActivityCues(for booking: BookingItem) -> [String] {
        var cues: [String] = []

        if let start = parseISODate(booking.startTime) {
            if Calendar.current.isDateInToday(start) {
                cues.append("Bugün")
            } else if Date().timeIntervalSince(start) < 0, start.timeIntervalSinceNow < 24 * 60 * 60 {
                cues.append("Yaklaşıyor")
            }
        }

        if bookingPresentation(for: booking).canPay {
            cues.append("Ödeme bekliyor")
        } else if booking.status.uppercased() == "ACCEPTED" {
            cues.append("Hazır")
        }

        return Array(cues.prefix(2))
    }

    private func toneColor(for tone: BookingPresentationTone) -> Color {
        switch tone {
        case .primary:
            return DS.Colors.primary
        case .accent:
            return DS.Colors.accent
        case .danger:
            return .red
        case .neutral:
            return .gray
        }
    }

    private func toneBackground(for tone: BookingPresentationTone) -> Color {
        toneColor(for: tone).opacity(tone == .neutral ? 0.2 : 0.14)
    }

    private func openCheckout(for booking: BookingItem) async {
        checkoutBookingID = booking.id
        checkoutError = nil
        isLoadingCheckout = true
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
                checkoutError = "Ödeme şu anda kullanılamıyor. Lütfen kısa süre sonra tekrar dene."
            } else if message.localizedCaseInsensitiveContains("http 500") {
                checkoutError = "Ödeme bağlantısı şu anda oluşturulamıyor. Lütfen daha sonra tekrar dene."
            } else {
                checkoutError = message
            }
        }
    }

    private func openConversation(for booking: BookingItem) {
        if let conversation = viewModel.conversation(
            providerID: booking.provider.id,
            participantName: booking.provider.displayName
        ) {
            clearNotificationContext()
            selectedConversation = conversation
        } else {
            showChatList = true
        }
    }

    private func openDestination(for notification: AppNotification) {
        switch viewModel.destination(for: notification) {
        case .conversation(let conversation):
            selectedConversationContextBadge = dashboardNotificationProximityBadge(for: notification)
            selectedBookingContextBadge = nil
            selectedConversation = conversation
        case .bookingDetail(let bookingID):
            if let booking = viewModel.bookings.first(where: { $0.id == bookingID }) {
                selectedConversationContextBadge = nil
                selectedBookingContextBadge = dashboardNotificationProximityBadge(for: notification)
                selectedBooking = booking
            } else {
                clearNotificationContext()
                showBookingList = true
            }
        case .bookings:
            clearNotificationContext()
            showBookingList = true
        case .chatList:
            clearNotificationContext()
            showChatList = true
        case .careRequests:
            clearNotificationContext()
            showAllCareRequests = true
        case .notifications:
            clearNotificationContext()
            showNotifications = true
        }
    }

    @MainActor
    private func handleRemoteNotificationOpen(_ notification: AppNotification) async {
        switch viewModel.destination(for: notification) {
        case .bookingDetail(let bookingID):
            selectedConversationContextBadge = nil
            selectedBookingContextBadge = dashboardNotificationProximityBadge(for: notification)
            if let booking = viewModel.bookings.first(where: { $0.id == bookingID }) {
                selectedBooking = booking
                return
            }

            do {
                if let booking = try await session.deps.bookingService.booking(id: bookingID) {
                    selectedBooking = booking
                } else {
                    clearNotificationContext()
                    showBookingList = true
                }
            } catch {
                clearNotificationContext()
                showBookingList = true
            }
        default:
            openDestination(for: notification)
        }
    }

    private func clearNotificationContext() {
        selectedConversationContextBadge = nil
        selectedBookingContextBadge = nil
    }

    private func loadCareRequests() async {
        guard let userID = session.me?.user.id else { return }
        isLoadingCareRequests = true
        defer { isLoadingCareRequests = false }

        do {
            careRequests = try await session.deps.bookingService.listParentCareRequests(parentUserID: userID)
            careRequestError = nil
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            careRequestError = error.localizedDescription
        }
    }

    private func createCareRequest(_ draft: ParentCareRequestDraft) async throws {
        guard let user = session.me?.user else {
            throw APIError.http(401, "Oturum bulunamadı.".data(using: .utf8))
        }

        let service: String
        switch draft.serviceLabel {
        case "Özel Ders":
            service = "TUTOR"
        case "Özel Eğitim":
            service = "SPECIAL_ED"
        default:
            service = "BABYSITTER"
        }

        do {
            _ = try await session.deps.bookingService.createCareRequest(
                input: CreateCareRequestInput(
                    service: service,
                    note: draft.note,
                    startAt: draft.startAt,
                    endAt: draft.endAt,
                    locationName: familyLocationName
                ),
                parent: user,
                parentDisplayName: resolvedFamilyRequesterName,
                parentPhone: user.phone,
                locationName: familyLocationName
            )
            careRequestNotice = "Talebin yayınlandı. Bakıcılar başvurdukça burada görüp içlerinden birini seçebilirsin."
            careRequestError = nil
            showCreateCareRequest = false
            await loadCareRequests()
        } catch {
            careRequestError = error.localizedDescription
            throw error
        }
    }

    private func approve(candidate: CareRequestCandidate, for request: CareRequestItem) async {
        guard let userID = session.me?.user.id else { return }

        do {
            _ = try await session.deps.bookingService.approveCareRequestCandidate(
                requestID: request.id,
                candidateProviderUserID: candidate.providerUserID,
                parentUserID: userID
            )
            careRequestNotice = "\(candidate.providerDisplayName) seçildi. Sıradaki adımda rezervasyon ve ödeme detayları açılacak."
            careRequestError = nil
            await loadCareRequests()
        } catch {
            careRequestError = error.localizedDescription
        }
    }

    private var resolvedFamilyRequesterName: String {
        let trimmedDisplayName = familyDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDisplayName.isEmpty { return trimmedDisplayName }
        if let displayName = session.me?.user.displayName, !displayName.isEmpty { return displayName }
        if let email = session.me?.user.email, !email.isEmpty { return email }
        return session.me?.user.phone ?? "Aile"
    }

    private func localizedCareService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first ?? localizedService(service)
    }

    private func careRequestStatusLabel(for request: CareRequestItem) -> String {
        if request.isMatched, let assigned = request.assignedProviderDisplayName {
            return "Atandı: \(assigned)"
        }
        if !request.candidates.isEmpty {
            return "\(request.candidates.count) aday"
        }
        return "Açık"
    }

    private func careRequestStatusColor(for request: CareRequestItem) -> Color {
        request.isMatched ? .green : DS.Colors.accent
    }

    private func parentLiveSignals(for request: CareRequestItem) -> [String] {
        var signals: [String] = []

        if request.isOpen, let latestCandidate = request.candidates.max(by: { $0.appliedAt < $1.appliedAt }),
           isRecentCareRequestUpdate(latestCandidate.appliedAt) {
            signals.append("Yeni aday var")
        }

        if !request.isMatched, !request.candidates.isEmpty {
            signals.append("Karar bekliyor")
        } else if isRecentCareRequestUpdate(request.createdAt) {
            signals.append("Bugün güncellendi")
        }

        return Array(signals.prefix(2))
    }

    @ViewBuilder
    private func liveSignalsRow(_ signals: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(signals, id: \.self) { signal in
                    Text(signal)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.Colors.accent.opacity(0.12))
                        .foregroundStyle(DS.Colors.accent)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func isRecentCareRequestUpdate(_ value: String) -> Bool {
        guard let date = parseISODate(value) else { return false }
        return Calendar.current.isDateInToday(date) || Date().timeIntervalSince(date) < 12 * 60 * 60
    }

    private func parentSuggestedNextStep(for request: CareRequestItem) -> String {
        if request.isMatched {
            return "Önerilen adım: Rezervasyon ve ödeme detaylarını kontrol et."
        }
        if !request.candidates.isEmpty {
            return "Önerilen adım: Adayları karşılaştırıp en uygun kişiyi seç."
        }
        return "Önerilen adım: Başvuruları takip et, istersen yeni bir saat aralığı da aç."
    }
}

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published var bookings: [BookingItem] = []
    @Published var favorites: [FavoriteItem] = []
    @Published var notifications: [AppNotification] = []
    @Published var conversations: [ConversationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var bookingService: BookingService
    private var providerService: ProviderService
    private var notificationService: NotificationService
    private var chatService: ChatService

    init(
        bookingService: BookingService,
        providerService: ProviderService,
        notificationService: NotificationService,
        chatService: ChatService
    ) {
        self.bookingService = bookingService
        self.providerService = providerService
        self.notificationService = notificationService
        self.chatService = chatService
    }

    var activeBookings: [BookingItem] {
        HomeDashboardSnapshot(
            bookings: bookings,
            favorites: favorites,
            notifications: notifications,
            conversations: conversations
        ).activeBookings
    }

    var completedBookings: [BookingItem] {
        HomeDashboardSnapshot(
            bookings: bookings,
            favorites: favorites,
            notifications: notifications,
            conversations: conversations
        ).completedBookings
    }

    var unreadNotifications: Int {
        HomeDashboardSnapshot(
            bookings: bookings,
            favorites: favorites,
            notifications: notifications,
            conversations: conversations
        ).unreadNotifications
    }

    func replaceServicesIfNeeded(
        bookingService: BookingService,
        providerService: ProviderService,
        notificationService: NotificationService,
        chatService: ChatService
    ) {
        self.bookingService = bookingService
        self.providerService = providerService
        self.notificationService = notificationService
        self.chatService = chatService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let bookingsTask = bookingService.listBookings()
        async let favoritesTask = providerService.listFavorites()
        async let notificationsTask = notificationService.listNotifications()
        async let conversationsTask = chatService.listConversations()

        do {
            let (bookings, favoritesResponse, notificationsResponse, conversationsResponse) = try await (
                bookingsTask,
                favoritesTask,
                notificationsTask,
                conversationsTask
            )
            let snapshot = HomeDashboardSnapshot.make(
                bookings: bookings,
                favoritesResponse: favoritesResponse,
                notificationsResponse: notificationsResponse,
                conversationsResponse: conversationsResponse
            )
            self.bookings = snapshot.bookings
            favorites = snapshot.favorites
            notifications = snapshot.notifications
            conversations = snapshot.conversations
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func conversation(providerID: String, participantName: String) -> ConversationItem? {
        DashboardRouting.conversation(
            forProviderID: providerID,
            participantName: participantName,
            conversations: conversations
        )
    }

    func conversation(matching notification: AppNotification) -> ConversationItem? {
        DashboardRouting.conversation(matching: notification, conversations: conversations)
    }

    func destination(for notification: AppNotification) -> DashboardNotificationDestination {
        DashboardRouting.destination(for: notification, conversations: conversations)
    }

    func applyBookingUpdate(_ updatedBooking: BookingItem) {
        guard let index = bookings.firstIndex(where: { $0.id == updatedBooking.id }) else { return }
        bookings[index] = updatedBooking
    }

    func markConversationReadLocally(chatID: String) {
        conversations = conversations.map { conversation in
            guard conversation.id == chatID else { return conversation }
            return ConversationItem(
                id: conversation.id,
                participantID: conversation.participantID,
                participantName: conversation.participantName,
                lastMessage: conversation.lastMessage,
                lastMessageAt: conversation.lastMessageAt,
                unreadCount: 0
            )
        }
    }

    func applyConversationUpdate(_ updatedConversation: ConversationItem) {
        guard let index = conversations.firstIndex(where: { $0.id == updatedConversation.id }) else { return }
        conversations.remove(at: index)
        conversations.insert(updatedConversation, at: 0)
    }
}

private struct ParentCareRequestsListView: View {
    @Binding var careRequests: [CareRequestItem]
    @Binding var selectedCandidateProvider: BrowseProvider?
    let onApprove: (CareRequestCandidate, CareRequestItem) -> Void
    @State private var selectedSort: ParentCareRequestSort = .newest

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Aday başvuruları çoğaldığında burada daha rahat karşılaştırıp onay verebilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)

                sortBar
                resultsSummary

                if careRequests.isEmpty {
                    emptyState
                } else {
                    ForEach(sortedRequests) { request in
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
                                    Text(careRequestStatusLabel(for: request))
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(careRequestStatusColor(for: request).opacity(0.14))
                                        .foregroundStyle(careRequestStatusColor(for: request))
                                        .clipShape(Capsule())
                                }

                                if !liveSignals(for: request).isEmpty {
                                    liveSignalsRow(liveSignals(for: request))
                                }

                                if !request.note.isEmpty {
                                    Text(request.note)
                                        .font(.subheadline)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                }

                                if request.candidates.isEmpty {
                                    Text("Henüz aday olan bakıcı yok.")
                                        .font(.footnote)
                                        .foregroundStyle(DS.Colors.textSecondary)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Aday Olan Bakıcılar")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(DS.Colors.textSecondary)

                                        ForEach(request.candidates) { candidate in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Button {
                                                        selectedCandidateProvider = BrowseProvider(
                                                            id: candidate.providerUserID,
                                                            displayName: candidate.providerDisplayName,
                                                            rating: 0,
                                                            hourlyRate: 0,
                                                            payoutStatus: "PENDING",
                                                            age: 0,
                                                            gender: "",
                                                            locationName: "",
                                                            distanceText: "",
                                                            photoURL: nil,
                                                            latitude: nil,
                                                            longitude: nil,
                                                            categories: [],
                                                            reviewCount: 0,
                                                            completedSittings: 0,
                                                            availableDates: [],
                                                            availableStartHour: 9,
                                                            availableEndHour: 18
                                                        )
                                                    } label: {
                                                        Text(candidate.providerDisplayName)
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(DS.Colors.primary)
                                                    }
                                                    .buttonStyle(.plain)
                                                    Text("Aday oldu: \(formattedTime(candidate.appliedAt))")
                                                        .font(.caption)
                                                        .foregroundStyle(DS.Colors.textSecondary)
                                                }
                                                Spacer()
                                                if request.assignedProviderUserID == candidate.providerUserID {
                                                    Text("Seçildi")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(.green)
                                                } else if request.isOpen {
                                                    Button("Onayla") {
                                                        onApprove(candidate, request)
                                                    }
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(DS.Colors.primary)
                                                }
                                            }
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
        .navigationTitle("Aile Talepleri")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedRequests: [CareRequestItem] {
        switch selectedSort {
        case .newest:
            return careRequests.sorted { $0.createdAt > $1.createdAt }
        case .mostCandidates:
            return careRequests.sorted {
                if $0.candidates.count == $1.candidates.count {
                    return $0.createdAt > $1.createdAt
                }
                return $0.candidates.count > $1.candidates.count
            }
        case .openFirst:
            return careRequests.sorted {
                if $0.isOpen == $1.isOpen {
                    return $0.createdAt > $1.createdAt
                }
                return $0.isOpen && !$1.isOpen
            }
        }
    }

    private var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ParentCareRequestSort.allCases, id: \.self) { option in
                    Button {
                        selectedSort = option
                    } label: {
                        Text(option.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedSort == option ? DS.Colors.primary : .white)
                            .foregroundStyle(selectedSort == option ? .white : DS.Colors.textPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func liveSignals(for request: CareRequestItem) -> [String] {
        var signals: [String] = []

        if request.isOpen, let latestCandidate = request.candidates.max(by: { $0.appliedAt < $1.appliedAt }),
           isRecentUpdate(latestCandidate.appliedAt) {
            signals.append("Yeni aday var")
        }

        if !request.isMatched, !request.candidates.isEmpty {
            signals.append("Karar bekliyor")
        } else if isRecentUpdate(request.createdAt) {
            signals.append("Bugün güncellendi")
        }

        return Array(signals.prefix(2))
    }

    @ViewBuilder
    private func liveSignalsRow(_ signals: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(signals, id: \.self) { signal in
                    Text(signal)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DS.Colors.accent.opacity(0.12))
                        .foregroundStyle(DS.Colors.accent)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func isRecentUpdate(_ value: String) -> Bool {
        guard let date = parseISODate(value) else { return false }
        return Calendar.current.isDateInToday(date) || Date().timeIntervalSince(date) < 12 * 60 * 60
    }

    private var resultsSummary: some View {
        HStack(spacing: 8) {
            Text("\(sortedRequests.count) talep")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DS.Colors.textPrimary)

            Text("•")
                .font(.footnote)
                .foregroundStyle(DS.Colors.textSecondary)

            Text(sortDescription)
                .font(.footnote)
                .foregroundStyle(DS.Colors.textSecondary)
        }
    }

    private var sortDescription: String {
        switch selectedSort {
        case .newest:
            return "en yeni başvurular üstte"
        case .mostCandidates:
            return "adayı çok olanlar üstte"
        case .openFirst:
            return "önce açık talepler gösteriliyor"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(DS.Colors.accent)
            Text("Henüz acil talep oluşturmadın")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            Text("Yeni taleplerin ve aday başvuruların burada tam liste halinde görünecek.")
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

    private func localizedCareService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first ?? service
    }

    private func careRequestStatusLabel(for request: CareRequestItem) -> String {
        if request.isMatched, let assigned = request.assignedProviderDisplayName {
            return "Atandı: \(assigned)"
        }
        if !request.candidates.isEmpty {
            return "\(request.candidates.count) aday"
        }
        return "Açık"
    }

    private func careRequestStatusColor(for request: CareRequestItem) -> Color {
        request.isMatched ? .green : DS.Colors.accent
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

private struct ParentCareRequestDraft {
    let serviceLabel: String
    let note: String
    let startAt: Date
    let endAt: Date
}

private struct ParentCareRequestComposer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedService = "Bebek Bakımı"
    @State private var note = ""
    @State private var date = Date()
    @State private var startTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date().addingTimeInterval(3 * 60 * 60)
    @State private var validationError: String?
    @State private var isSubmitting = false

    let onSubmit: (ParentCareRequestDraft) async throws -> Void

    private let services = ["Bebek Bakımı", "Özel Ders", "Özel Eğitim"]

    var body: some View {
        Form {
            Section("Talep Türü") {
                Picker("Hizmet", selection: $selectedService) {
                    ForEach(services, id: \.self) { service in
                        Text(service).tag(service)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Zaman") {
                DatePicker("Tarih", selection: $date, displayedComponents: .date)
                DatePicker("Başlangıç", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("Bitiş", selection: $endTime, displayedComponents: .hourAndMinute)
            }

            Section("Not") {
                TextEditor(text: $note)
                    .frame(minHeight: 120)
                Text("Örn. bugün akşam 18:00-21:00 arası dışarı çıkmam gerekiyor.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let validationError {
                Section {
                    Text(validationError)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Talep Oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Vazgeç") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Yayınla") {
                    Task {
                        await submit()
                    }
                }
                .fontWeight(.semibold)
                .disabled(isSubmitting)
            }
        }
    }

    private func submit() async {
        let calendar = Calendar.current
        let mergedStart = merge(date: date, time: startTime, calendar: calendar)
        let mergedEnd = merge(date: date, time: endTime, calendar: calendar)

        guard mergedEnd > mergedStart else {
            validationError = "Bitiş saati başlangıçtan sonra olmalı."
            return
        }

        validationError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await onSubmit(
                ParentCareRequestDraft(
                    serviceLabel: selectedService,
                    note: note,
                    startAt: mergedStart,
                    endAt: mergedEnd
                )
            )
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }

    private func merge(date: Date, time: Date, calendar: Calendar) -> Date {
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(from: DateComponents(
            year: dayComponents.year,
            month: dayComponents.month,
            day: dayComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? date
    }
}
