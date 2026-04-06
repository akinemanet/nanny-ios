//
//  BookingListView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BookingListView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferencePreferredCurrency") private var preferredCurrency = "TRY"
    @State private var selectedTab = 0
    @State private var bookings: [BookingItem] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Rezervasyonlar")
                        .font(.largeTitle.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal)

                Picker("Durum", selection: $selectedTab) {
                    Text("Aktif").tag(0)
                    Text("Tamamlanan").tag(1)
                    Text("İptal").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }

                    if !isLoading, filteredBookings.isEmpty, errorMessage == nil {
                        emptyState(
                            title: emptyStateTitle,
                            systemImage: emptyStateSystemImage,
                            description: emptyStateDescription
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    ForEach(filteredBookings) { booking in
                        NavigationLink {
                            BookingDetailView(booking: booking) { updatedBooking in
                                applyBookingUpdate(updatedBooking)
                            }
                        } label: {
                            bookingRow(for: booking)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                await loadBookings()
            }
            .task {
                await loadBookings()
            }
        }
    }

    private var filteredBookings: [BookingItem] {
        if selectedTab == 0 {
            return bookings.filter {
                let status = $0.status.uppercased()
                return status != "COMPLETED" && status != "CANCELED" && status != "CANCELLED"
            }
        }
        if selectedTab == 1 {
            return bookings.filter { $0.status.uppercased() == "COMPLETED" }
        }
        return bookings.filter {
            let status = $0.status.uppercased()
            return status == "CANCELED" || status == "CANCELLED"
        }
    }

    private func loadBookings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            bookings = try await session.deps.bookingService.listBookings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyBookingUpdate(_ updatedBooking: BookingItem) {
        guard let index = bookings.firstIndex(where: { $0.id == updatedBooking.id }) else { return }
        bookings[index] = updatedBooking
    }

    private func formattedDate(_ value: String) -> String {
        let out = DateFormatter()
        out.locale = Locale(identifier: "tr_TR")
        out.dateStyle = .medium
        if let date = parseISODate(value) {
            return out.string(from: date)
        }
        return value
    }

    private func formattedTime(_ value: String) -> String {
        let out = DateFormatter()
        out.locale = Locale(identifier: "tr_TR")
        out.timeStyle = .short
        if let date = parseISODate(value) {
            return out.string(from: date)
        }
        return value
    }

    private func parseISODate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }

    private func localizedService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first
            ?? service.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func localizedStatus(_ status: String) -> String {
        BookingStatusPresentation.make(for: status).localizedStatus
    }

    private func statusChip(for status: String) -> some View {
        let appearance = bookingStatusAppearance(status)
        return Text(localizedStatus(status))
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(appearance.background)
            .foregroundStyle(appearance.foreground)
            .clipShape(Capsule())
    }

    private func bookingRow(for booking: BookingItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DS.Colors.surface)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "calendar")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.primary)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(booking.provider.displayName)
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(1)

                    Spacer(minLength: 8)

                    statusChip(for: booking.status)
                        .fixedSize()
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(localizedService(booking.service))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .layoutPriority(1)

                    Spacer(minLength: 8)

                    if booking.totalPrice > 0 {
                        Text(CurrencyFormatting.formattedAmount(booking.totalPrice, currencyCode: preferredCurrency))
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                Text("\(formattedDate(booking.startTime)) • \(formattedTime(booking.startTime)) - \(formattedTime(booking.endTime))")
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if !bookingActivityCues(for: booking).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(bookingActivityCues(for: booking), id: \.self) { cue in
                                Text(cue)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DS.Colors.primary.opacity(0.10))
                                    .foregroundStyle(DS.Colors.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Text(paymentStatusText(for: booking))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(paymentStatusColor(for: booking))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private func bookingStatusAppearance(_ status: String) -> (foreground: Color, background: Color) {
        let presentation = BookingStatusPresentation.make(for: status)
        return (
            toneColor(for: presentation.statusTone),
            toneBackground(for: presentation.statusTone)
        )
    }

    private func paymentStatusText(for booking: BookingItem) -> String {
        BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus).paymentSummaryText
    }

    private func paymentStatusColor(for booking: BookingItem) -> Color {
        toneColor(for: BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus).paymentSummaryTone)
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

        let presentation = BookingStatusPresentation.make(for: booking.status, paymentStatus: booking.paymentStatus)
        if presentation.canPay {
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
            return DS.Colors.textSecondary
        }
    }

    private func toneBackground(for tone: BookingPresentationTone) -> Color {
        toneColor(for: tone).opacity(tone == .neutral ? 0.2 : 0.16)
    }

    private var emptyStateTitle: String {
        switch selectedTab {
        case 0:
            return "Aktif Rezervasyon Yok"
        case 1:
            return "Tamamlanan Rezervasyon Yok"
        default:
            return "İptal Edilen Rezervasyon Yok"
        }
    }

    private var emptyStateSystemImage: String {
        switch selectedTab {
        case 0:
            return "calendar.badge.clock"
        case 1:
            return "checkmark.circle"
        default:
            return "xmark.circle"
        }
    }

    private var emptyStateDescription: String {
        switch selectedTab {
        case 0:
            return "Güncel rezervasyonların burada görünecek."
        case 1:
            return "Tamamlanan rezervasyonların burada görünecek."
        default:
            return "İptal edilen rezervasyonların burada görünecek."
        }
    }

    private func emptyState(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(DS.Colors.accent)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct BookingDetailView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferencePreferredCurrency") private var preferredCurrency = "TRY"
    let booking: BookingItem
    let contextBadgeText: String?
    let onBookingUpdated: (BookingItem) -> Void
    @State private var checkoutURL: URL?
    @State private var checkoutError: String?
    @State private var isLoadingCheckout = false
    @State private var showCheckout = false
    @State private var showRebook = false
    @State private var showReschedule = false
    @State private var showCancelConfirmation = false
    @State private var isCancelling = false
    @State private var isRescheduling = false
    @State private var localStatusOverride: String?
    @State private var localPaymentStatusOverride: String?
    @State private var localStartTimeOverride: String?
    @State private var localEndTimeOverride: String?
    @State private var conversations: [ConversationItem] = []
    @State private var selectedConversation: ConversationItem?
    @State private var showChatList = false
    @State private var cancellationNotice: String?
    @State private var cancellationError: String?
    @State private var rescheduleNotice: String?
    @State private var rescheduleError: String?

    init(
        booking: BookingItem,
        contextBadgeText: String? = nil,
        onBookingUpdated: @escaping (BookingItem) -> Void = { _ in }
    ) {
        self.booking = booking
        self.contextBadgeText = contextBadgeText
        self.onBookingUpdated = onBookingUpdated
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(for: booking)
                summaryTimeline
                pricingSummary
                paymentStatusCard
                if let contextBadgeText, !contextBadgeText.isEmpty {
                    detailContextBadge(text: contextBadgeText)
                }
                detailRow("Hizmet", value: localizedService(booking.service))
                detailRow("Bakıcı", value: resolvedProviderDisplayName)
                if let address = booking.address {
                    detailRow("Adres", value: address)
                }
                if let cancellationNotice {
                    infoCard(title: "Durum Güncellendi", message: cancellationNotice)
                }
                if let rescheduleNotice {
                    infoCard(title: "Rezervasyon Güncellendi", message: rescheduleNotice)
                }
                if let cancellationError {
                    Text(cancellationError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                if let rescheduleError {
                    Text(rescheduleError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                if let checkoutError {
                    Text(checkoutError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                if canPay {
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
                    .disabled(isLoadingCheckout)
                }
                if canRebook {
                    Button {
                        showRebook = true
                    } label: {
                        Text("Yeniden Rezervasyon Yap")
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Size.buttonHeight)
                    }
                    .background(DS.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
                if canReschedule {
                    Button {
                        showReschedule = true
                    } label: {
                        Group {
                            if isRescheduling {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DS.Size.buttonHeight)
                            } else {
                                Text("Tarih ve Saati Değiştir")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DS.Size.buttonHeight)
                            }
                        }
                    }
                    .background(DS.Colors.primary.opacity(0.14))
                    .foregroundStyle(DS.Colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                    .disabled(isRescheduling)
                }
                if canCancel {
                    Button(role: .destructive) {
                        showCancelConfirmation = true
                    } label: {
                        Group {
                            if isCancelling {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DS.Size.buttonHeight)
                            } else {
                                Text("İptal Talebi Oluştur")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DS.Size.buttonHeight)
                            }
                        }
                    }
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                    .disabled(isCancelling)
                }
                infoCard(
                    title: "Rezervasyon Bilgisi",
                    message: "Ödeme adımını burada tamamlayabilir, geçmiş rezervasyonlar için hızlıca yeni bir takvim oluşturabilir ve aktif kayıtlar için iptal talebi başlatabilirsin."
                )
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Rezervasyon Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedConversation) { conversation in
            ChatView(chatID: conversation.id, title: conversation.participantName)
        }
        .navigationDestination(isPresented: $showChatList) {
            ChatListView()
        }
        .navigationDestination(isPresented: $showRebook) {
            BookingCalendarView(provider: rebookProvider)
        }
        .sheet(isPresented: $showReschedule) {
            NavigationStack {
                BookingRescheduleView(
                    booking: currentBooking
                ) { selection in
                    Task {
                        await submitReschedule(selection: selection)
                    }
                }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCheckout, onDismiss: {
            Task {
                await refreshBookingAfterCheckout()
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
        .alert("İptal talebi oluşturulsun mu?", isPresented: $showCancelConfirmation) {
            Button("Vazgeç", role: .cancel) {}
            Button("İptal Talebi Gönder", role: .destructive) {
                Task {
                    await submitCancellationRequest()
                }
            }
        } message: {
            Text("İptal talebin şimdi gönderilecek. İşlem şu anda tamamlanamazsa rezervasyon durumu bu cihazda güncellenecek.")
        }
        .task {
            await loadConversations()
        }
    }

    private func header(for booking: BookingItem) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.Colors.primary.opacity(0.22), DS.Colors.accent.opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundStyle(DS.Colors.primary)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(resolvedProviderDisplayName)
                        .font(.title2.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(localizedStatus(effectiveStatus))
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusAppearance.background)
                        .foregroundStyle(statusAppearance.foreground)
                        .clipShape(Capsule())
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await openConversation()
                        }
                    } label: {
                        iconCircle("message")
                    }
                    .buttonStyle(.plain)

                    iconCircle("phone")
                }
            }

            if let address = booking.address {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(DS.Colors.accent)
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DS.Colors.accent)
            Text(value)
                .font(.body)
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private var summaryTimeline: some View {
        HStack(alignment: .top, spacing: 16) {
            timelineColumn("Başlangıç", detailFormattedDate(booking.startTime), detailFormattedTime(booking.startTime))

            VStack(spacing: 8) {
                Text(bookingDuration(booking))
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textSecondary)
                Image(systemName: "arrow.right")
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)

            timelineColumn("Bitiş", detailFormattedDate(booking.endTime), detailFormattedTime(booking.endTime))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private var pricingSummary: some View {
        HStack(spacing: 14) {
            metricCard(title: "Saatlik Ücret", value: hourlyRateText, tint: DS.Colors.primary)
            metricCard(
                title: "Toplam",
                value: booking.totalPrice > 0
                    ? CurrencyFormatting.formattedAmount(booking.totalPrice, currencyCode: preferredCurrency)
                    : "-",
                tint: DS.Colors.accent
            )
        }
    }

    private var paymentStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: paymentStatusIcon)
                    .foregroundStyle(paymentStatusTint)
                Text("Ödeme Durumu")
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Text(paymentStatusLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(paymentStatusTint.opacity(0.14))
                    .foregroundStyle(paymentStatusTint)
                    .clipShape(Capsule())
            }
            Text(paymentStatusDescription)
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func detailContextBadge(text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .foregroundStyle(DS.Colors.primary)
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(DS.Colors.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.Colors.primary.opacity(0.1))
        .clipShape(Capsule())
    }

    private func infoCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(DS.Colors.primary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
            }
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    private func timelineColumn(_ title: String, _ value: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DS.Colors.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconCircle(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.headline)
            .foregroundStyle(DS.Colors.primary)
            .frame(width: 42, height: 42)
            .background(.white)
            .clipShape(Circle())
            .overlay(Circle().stroke(DS.Colors.border, lineWidth: 1))
    }

    private func loadConversations() async {
        do {
            conversations = try await session.deps.chatService.listConversations().conversations
        } catch {
            conversations = []
        }
    }

    private func openConversation() async {
        if let conversation = DashboardRouting.conversation(
            forProviderID: booking.provider.id,
            participantName: resolvedProviderDisplayName,
            conversations: conversations
        ) {
            selectedConversation = conversation
        } else {
            do {
                let conversation = try await session.deps.chatService.startConversation(participantID: booking.provider.id)
                conversations.insert(conversation, at: 0)
                selectedConversation = conversation
            } catch {
                showChatList = true
            }
        }
    }

    private var hourlyRateText: String {
        guard booking.totalPrice > 0 else { return "-" }
        guard
            let start = parseISODate(booking.startTime),
            let end = parseISODate(booking.endTime)
        else {
            return "-"
        }

        let hours = max(end.timeIntervalSince(start) / 3600, 1)
        let rate = Int((Double(booking.totalPrice) / hours).rounded())
        return CurrencyFormatting.formattedHourlyRate(rate, currencyCode: preferredCurrency)
    }

    private var statusAppearance: (foreground: Color, background: Color) {
        let presentation = BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus)
        return (
            toneColor(for: presentation.statusTone),
            toneBackground(for: presentation.statusTone)
        )
    }

    private func detailFormattedDate(_ value: String) -> String {
        let out = DateFormatter()
        out.dateFormat = "EEEE,\nd MMM yyyy"
        out.locale = Locale(identifier: "tr_TR")
        if let date = parseISODate(value) {
            return out.string(from: date)
        }
        return value
    }

    private func detailFormattedTime(_ value: String) -> String {
        let out = DateFormatter()
        out.locale = Locale(identifier: "tr_TR")
        out.timeStyle = .short
        if let date = parseISODate(value) {
            return out.string(from: date)
        }
        return value
    }

    private func localizedService(_ service: String) -> String {
        ProviderCategoryMapper.displayLabels(from: [service]).first
            ?? service.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func localizedStatus(_ status: String) -> String {
        BookingStatusPresentation.make(for: status).localizedStatus
    }

    private func bookingDuration(_ booking: BookingItem) -> String {
        guard
            let start = parseISODate(booking.startTime),
            let end = parseISODate(booking.endTime)
        else {
            return "-"
        }

        let hours = max(0, Int(end.timeIntervalSince(start) / 3600))
        let minutes = max(0, Int(end.timeIntervalSince(start).truncatingRemainder(dividingBy: 3600) / 60))

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }

    private func parseISODate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }

    private var resolvedProviderDisplayName: String {
        let trimmed = booking.provider.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.lowercased() == "provider" || trimmed.lowercased() == "bakici" {
            return "Bakıcı"
        }
        return trimmed
    }

    private var canPay: Bool {
        BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).canPay
    }

    private var canRebook: Bool {
        BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).canRebook
    }

    private var canCancel: Bool {
        BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).canCancel
    }

    private var canReschedule: Bool {
        let uppercasedStatus = effectiveStatus.uppercased()
        return uppercasedStatus == "ACCEPTED" || uppercasedStatus == "CONFIRMED" || uppercasedStatus == "REQUESTED"
    }

    private var effectiveStatus: String {
        localStatusOverride ?? booking.status
    }

    private var effectivePaymentStatus: String? {
        localPaymentStatusOverride ?? booking.paymentStatus
    }

    private var currentBooking: BookingItem {
        BookingItem(
            id: booking.id,
            service: booking.service,
            status: effectiveStatus,
            startTime: localStartTimeOverride ?? booking.startTime,
            endTime: localEndTimeOverride ?? booking.endTime,
            totalPrice: booking.totalPrice,
            address: booking.address,
            paymentStatus: effectivePaymentStatus,
            provider: booking.provider
        )
    }

    private var paymentStatusLabel: String {
        BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).paymentLabel
    }

    private var paymentStatusDescription: String {
        BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).paymentDescription
    }

    private var paymentStatusTint: Color {
        toneColor(for: BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).paymentTone)
    }

    private var paymentStatusIcon: String {
        BookingStatusPresentation.make(for: effectiveStatus, paymentStatus: effectivePaymentStatus).paymentIcon
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
            return DS.Colors.textSecondary
        }
    }

    private func toneBackground(for tone: BookingPresentationTone) -> Color {
        toneColor(for: tone).opacity(tone == .neutral ? 0.2 : 0.16)
    }

    private var rebookProvider: BrowseProvider {
        BrowseProvider(
            id: booking.provider.id,
            displayName: resolvedProviderDisplayName,
            rating: 4.8,
            hourlyRate: booking.provider.hourlyRate ?? max(booking.totalPrice, 500),
            payoutStatus: "APPROVED",
            age: 30,
            gender: "Kadın",
            locationName: booking.address ?? "Konum daha sonra netleşecek",
            distanceText: "Daha önce rezervasyon yapıldı",
            photoURL: nil,
            latitude: nil,
            longitude: nil,
            categories: ["Tekrar Rezervasyon"],
            reviewCount: 0,
            completedSittings: 0,
            availableDates: [],
            availableStartHour: 9,
            availableEndHour: 18
        )
    }

    private func submitCancellationRequest() async {
        isCancelling = true
        cancellationError = nil
        cancellationNotice = nil
        checkoutError = nil
        defer { isCancelling = false }

        do {
            let canceledBooking = try await session.deps.bookingService.cancelBooking(bookingID: booking.id)
            let updatedBooking = canceledBooking ?? makeCancelledBooking()
            localStatusOverride = updatedBooking.status
            localPaymentStatusOverride = updatedBooking.paymentStatus
            cancellationNotice = "İptal talebin alındı ve rezervasyon durumu güncellendi."
            onBookingUpdated(updatedBooking)
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    let updatedBooking = makeCancelledBooking()
                    localStatusOverride = updatedBooking.status
                    localPaymentStatusOverride = updatedBooking.paymentStatus
                    cancellationNotice = "İptal talebin bu cihazda işlendi. Durum güncellendi."
                    onBookingUpdated(updatedBooking)
                } else {
                    cancellationError = error.localizedDescription
                }
            default:
                cancellationError = error.localizedDescription
            }
        } catch {
            cancellationError = error.localizedDescription
        }
    }

    private func makeCancelledBooking() -> BookingItem {
        BookingItem(
            id: booking.id,
            service: booking.service,
            status: "CANCELED",
            startTime: booking.startTime,
            endTime: booking.endTime,
            totalPrice: booking.totalPrice,
            address: booking.address,
            paymentStatus: booking.paymentStatus,
            provider: booking.provider
        )
    }

    private func submitReschedule(selection: BookingRescheduleSelection) async {
        isRescheduling = true
        rescheduleError = nil
        rescheduleNotice = nil
        cancellationError = nil
        cancellationNotice = nil
        defer { isRescheduling = false }

        do {
            let updatedBooking = try await session.deps.bookingService.rescheduleBooking(
                bookingID: booking.id,
                startAt: selection.startAt,
                endAt: selection.endAt
            ) ?? makeRescheduledBooking(selection: selection)

            localStartTimeOverride = updatedBooking.startTime
            localEndTimeOverride = updatedBooking.endTime
            localStatusOverride = updatedBooking.status
            localPaymentStatusOverride = updatedBooking.paymentStatus
            rescheduleNotice = "Rezervasyonun yeni tarih ve saat bilgisi kaydedildi."
            onBookingUpdated(updatedBooking)
            showReschedule = false
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: code) {
                    let updatedBooking = makeRescheduledBooking(selection: selection)
                    localStartTimeOverride = updatedBooking.startTime
                    localEndTimeOverride = updatedBooking.endTime
                    localStatusOverride = updatedBooking.status
                    localPaymentStatusOverride = updatedBooking.paymentStatus
                    rescheduleNotice = "Yeni tarih ve saat bu cihazda güncellendi."
                    onBookingUpdated(updatedBooking)
                    showReschedule = false
                } else {
                    rescheduleError = error.localizedDescription
                }
            default:
                rescheduleError = error.localizedDescription
            }
        } catch {
            rescheduleError = error.localizedDescription
        }
    }

    private func makeRescheduledBooking(selection: BookingRescheduleSelection) -> BookingItem {
        BookingItem(
            id: booking.id,
            service: booking.service,
            status: booking.status,
            startTime: selection.startAt,
            endTime: selection.endAt,
            totalPrice: booking.totalPrice,
            address: booking.address,
            paymentStatus: booking.paymentStatus,
            provider: booking.provider
        )
    }

    private func refreshBookingAfterCheckout() async {
        do {
            guard let refreshedBooking = try await session.deps.bookingService.booking(id: booking.id) else { return }
            localStatusOverride = refreshedBooking.status
            localPaymentStatusOverride = refreshedBooking.paymentStatus
            onBookingUpdated(refreshedBooking)
        } catch {
            checkoutError = error.localizedDescription
        }
    }

    private func openCheckout() async {
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
                checkoutError = "Ödeme şu anda kullanılamıyor. Lütfen daha sonra tekrar dene."
            } else {
                checkoutError = message
            }
        }
    }
}

private struct BookingRescheduleSelection: Equatable {
    let startAt: String
    let endAt: String
}

private struct BookingRescheduleView: View {
    let booking: BookingItem
    let onSubmit: (BookingRescheduleSelection) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var selectedTime: String

    private let times = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00", "16:00", "17:00"]

    init(booking: BookingItem, onSubmit: @escaping (BookingRescheduleSelection) -> Void) {
        self.booking = booking
        self.onSubmit = onSubmit

        let formatter = ISO8601DateFormatter()
        let startDate = formatter.date(from: booking.startTime) ?? Date()
        _selectedDate = State(initialValue: startDate)
        _selectedTime = State(initialValue: Self.timeString(from: startDate))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Yeni tarih ve saat sec")
                    .font(.title2.bold())
                    .foregroundStyle(DS.Colors.textPrimary)

                DatePicker("Tarih", selection: $selectedDate, in: Date()..., displayedComponents: [.date])
                    .datePickerStyle(.graphical)

                Text("Uygun Saatler")
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(availableTimes, id: \.self) { time in
                        TimeSlotView(time: time, isSelected: selectedTime == time) {
                            selectedTime = time
                        }
                    }
                }

                if availableTimes.isEmpty {
                    Text("Bu tarih icin kalan uygun saat bulunmuyor. Lutfen baska bir gun sec.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Yeni Slot")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.textSecondary)
                    Text("\(formattedDate(makeSelection().startAt)) • \(formattedTime(makeSelection().startAt)) - \(formattedTime(makeSelection().endAt))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colors.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.Colors.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mevcut Saat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.textSecondary)
                    Text("\(formattedDate(booking.startTime)) • \(formattedTime(booking.startTime)) - \(formattedTime(booking.endTime))")
                        .font(.subheadline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 3)

                Button {
                    onSubmit(makeSelection())
                } label: {
                    Text("Yeni Saati Kaydet")
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.Size.buttonHeight)
                }
                .background(DS.Colors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                .disabled(selectedTime.isEmpty || availableTimes.isEmpty)
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Yeniden Planla")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !availableTimes.contains(selectedTime) {
                selectedTime = availableTimes.first ?? ""
            }
        }
        .onChange(of: selectedDate) { _, _ in
            if !availableTimes.contains(selectedTime) {
                selectedTime = availableTimes.first ?? ""
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Kapat") { dismiss() }
            }
        }
    }

    private func makeSelection() -> BookingRescheduleSelection {
        let calendar = Calendar.current
        let parts = selectedTime.split(separator: ":")
        let hour = Int(parts.first ?? "9") ?? 9
        let minute = Int(parts.last ?? "0") ?? 0
        let startDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate) ?? selectedDate
        let endDate = startDate.addingTimeInterval(60 * 60)
        let formatter = ISO8601DateFormatter()
        return BookingRescheduleSelection(
            startAt: formatter.string(from: startDate),
            endAt: formatter.string(from: endDate)
        )
    }

    private var availableTimes: [String] {
        let calendar = Calendar.current
        let now = Date()
        return times.filter { time in
            let parts = time.split(separator: ":")
            guard
                parts.count == 2,
                let hour = Int(parts[0]),
                let minute = Int(parts[1]),
                let slotDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: selectedDate)
            else {
                return false
            }

            if calendar.isDate(selectedDate, inSameDayAs: now) {
                return slotDate > now.addingTimeInterval(15 * 60)
            }

            return true
        }
    }

    private func formattedDate(_ value: String) -> String {
        let iso = ISO8601DateFormatter()
        let out = DateFormatter()
        out.locale = Locale(identifier: "tr_TR")
        out.dateStyle = .medium
        if let date = iso.date(from: value) {
            return out.string(from: date)
        }
        return value
    }

    private func formattedTime(_ value: String) -> String {
        let iso = ISO8601DateFormatter()
        let out = DateFormatter()
        out.timeStyle = .short
        if let date = iso.date(from: value) {
            return out.string(from: date)
        }
        return value
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
