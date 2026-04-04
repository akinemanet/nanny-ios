//
//  ChatView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferenceQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("accountPreferenceQuietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("accountPreferenceQuietHoursEnd") private var quietHoursEnd = "07:00"
    @AppStorage("accountProfileDisplayName") private var familyDisplayName = ""
    @AppStorage("accountProfileAboutFamily") private var familyAbout = ""
    @AppStorage(StoredLocationKeys.name) private var familyLocationName = StoredLocation.fallback.name
    let chatID: String
    let title: String
    let contextBadgeText: String?
    let onConversationRead: (() -> Void)?
    let onConversationUpdated: ((ConversationItem) -> Void)?

    @State private var message = ""
    @StateObject private var viewModel: ChatViewModel

    init(
        chatID: String,
        title: String,
        contextBadgeText: String? = nil,
        onConversationRead: (() -> Void)? = nil,
        onConversationUpdated: ((ConversationItem) -> Void)? = nil
    ) {
        self.chatID = chatID
        self.title = title
        self.contextBadgeText = contextBadgeText
        self.onConversationRead = onConversationRead
        self.onConversationUpdated = onConversationUpdated
        _viewModel = StateObject(
            wrappedValue: ChatViewModel(
                service: AppDependencies.live().chatService
            )
        )
    }

    var body: some View {
        VStack {
            if let error = viewModel.error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            profileContextBanner

            if viewModel.messages.isEmpty, viewModel.error == nil {
                ContentUnavailableView(
                    "Mesaj Yok",
                    systemImage: "message",
                    description: Text("Bu konuşmada henüz mesaj yok.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { item in
                            VStack(alignment: item.isMine ? .trailing : .leading, spacing: 4) {
                                ChatBubble(text: item.text, isMine: item.isMine)
                                Text(formattedTime(item.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: item.isMine ? .trailing : .leading)
                        }
                    }
                    .padding()
                }
            }

            if viewModel.isParticipantTyping {
                HStack(spacing: 8) {
                    Image(systemName: isQuietHoursActive ? "moon.zzz.fill" : "ellipsis.message.fill")
                        .foregroundStyle(typingIndicatorTint)
                    Text(isQuietHoursActive ? "Yazıyor, sessiz modda" : "Yazıyor...")
                        .font(.footnote)
                        .foregroundStyle(typingIndicatorTint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(typingIndicatorBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
                .padding(.bottom, 4)
                .transition(.opacity)
            }

            Divider()

            HStack {
                Button {
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(DS.Colors.primary)
                }

                TextField("Mesaj...", text: $message)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: message) { _, newValue in
                        viewModel.userTypingChanged(chatID: chatID, text: newValue.trimmingCharacters(in: .whitespacesAndNewlines))
                    }

                Button {
                    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    Task {
                        await viewModel.sendMessage(chatID: chatID, text: trimmed)
                    }
                    message = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Image(systemName: "video.fill")
                Image(systemName: "phone.fill")
            }
        }
        .task {
            viewModel.replaceServiceIfNeeded(session.deps.chatService)
            viewModel.beginChatSession(chatID: chatID)
            if let token = session.deps.tokenStore.getToken(), !token.isEmpty {
                viewModel.connect(token: token)
            }
            await viewModel.loadMessages(chatID: chatID)
            let didMarkAsRead = await viewModel.markConversationRead(chatID: chatID)
            if didMarkAsRead {
                onConversationRead?()
            }
        }
        .onReceive(viewModel.$latestConversationUpdate.compactMap { $0 }) { conversation in
            onConversationUpdated?(conversation)
        }
    }

    private var profileContextBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.text.rectangle.fill")
                .foregroundStyle(DS.Colors.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(resolvedFamilyBannerTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                if let contextBadgeText, !contextBadgeText.isEmpty {
                    Text(contextBadgeText)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DS.Colors.primary.opacity(0.12))
                        .foregroundStyle(DS.Colors.primary)
                        .clipShape(Capsule())
                }
                Text(resolvedFamilyBannerSubtitle)
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(DS.Colors.background)
    }

    private func formattedTime(_ value: String) -> String {
        guard let date = parseISODate(value) else { return value }

        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")

        if calendar.isDate(date, inSameDayAs: now) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return formatter.string(from: date)
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Dün \(formatter.string(from: date))"
        }

        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseISODate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) {
            return date
        }

        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: value)
    }

    private var isQuietHoursActive: Bool {
        QuietHoursLogic.isActive(
            enabled: quietHoursEnabled,
            start: quietHoursStart,
            end: quietHoursEnd
        )
    }

    private var typingIndicatorTint: Color {
        isQuietHoursActive ? .indigo : DS.Colors.textSecondary
    }

    private var typingIndicatorBackground: Color {
        isQuietHoursActive ? .indigo.opacity(0.08) : .clear
    }

    private var resolvedFamilyBannerTitle: String {
        if !familyDisplayName.isEmpty {
            return "\(familyDisplayName) profili aktif"
        }
        return "Profil bağlamı hazır"
    }

    private var resolvedFamilyBannerSubtitle: String {
        let trimmedAbout = familyAbout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedAbout.isEmpty {
            return trimmedAbout
        }
        return StoredLocation.localizedDisplayName(familyLocationName)
    }
}
