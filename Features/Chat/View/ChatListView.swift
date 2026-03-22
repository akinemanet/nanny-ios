//
//  ChatListView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("accountPreferenceQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("accountPreferenceQuietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("accountPreferenceQuietHoursEnd") private var quietHoursEnd = "07:00"
    @State private var selectedTab = 0
    @State private var showCallScreen = false
    @StateObject private var viewModel: ChatViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue: ChatViewModel(
                service: AppDependencies.live().chatService
            )
        )
    }

    init(viewModel: @autoclosure @escaping () -> ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Bağlan")
                        .font(.largeTitle.bold())
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal)

                if selectedTab == 0, isQuietHoursActive {
                    HStack(spacing: 10) {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(.indigo)
                        Text("Sessiz saatler aktif. Okunmamis sohbetler daha yumuşak vurguyla gösteriliyor.")
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                Picker("Görünüm", selection: $selectedTab) {
                    Text("Sohbetler").tag(0)
                    Text("Aramalar").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundStyle(.red)
                    }

                    if selectedTab == 0, viewModel.conversations.isEmpty, viewModel.error == nil {
                        emptyState(
                            title: "Sohbet Yok",
                            systemImage: "message",
                            description: "Henüz hiç konuşman yok."
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    if selectedTab == 1, viewModel.calls.isEmpty, viewModel.error == nil {
                        emptyState(
                            title: "Arama Yok",
                            systemImage: "phone",
                            description: "Henüz hiç arama geçmişin yok."
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    if selectedTab == 0 {
                        ForEach(viewModel.conversations) { chat in
                            NavigationLink {
                                ChatView(chatID: chat.id, title: chat.participantName) {
                                    viewModel.markConversationReadLocally(chatID: chat.id)
                                } onConversationUpdated: { conversation in
                                    viewModel.applyConversationPreviewUpdate(
                                        chatID: conversation.id,
                                        lastMessage: conversation.lastMessage,
                                        lastMessageAt: conversation.lastMessageAt,
                                        unreadCount: conversation.unreadCount
                                    )
                                }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 48, height: 48)

                                    VStack(alignment: .leading) {
                                        Text(chat.participantName)
                                            .font(.headline)
                                        Text(chat.lastMessage)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 6) {
                                        Text(chat.lastMessageAt)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if chat.unreadCount > 0 {
                                            Text("\(chat.unreadCount)")
                                                .font(.caption.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(unreadBadgeBackground)
                                                .foregroundStyle(unreadBadgeForeground)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(viewModel.calls) { call in
                            Button {
                                showCallScreen = true
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 48, height: 48)

                                    VStack(alignment: .leading) {
                                        Text(call.participantName)
                                            .font(.headline)
                                        Text(call.direction.capitalized)
                                            .foregroundStyle(call.status.uppercased() == "MISSED" ? .red : .green)
                                    }

                                    Spacer()

                                    Text(call.createdAt)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showCallScreen) {
                ActiveCallView()
            }
            .refreshable {
                await reload()
            }
            .task {
                viewModel.error = nil
                await reload()
            }
            .onAppear {
                viewModel.replaceServiceIfNeeded(session.deps.chatService)
            }
        }
    }

    private func reload() async {
        await viewModel.loadConversations()
        await viewModel.loadCalls()
    }

    private var isQuietHoursActive: Bool {
        QuietHoursLogic.isActive(
            enabled: quietHoursEnabled,
            start: quietHoursStart,
            end: quietHoursEnd
        )
    }

    private var unreadBadgeBackground: Color {
        isQuietHoursActive ? .indigo.opacity(0.14) : .orange
    }

    private var unreadBadgeForeground: Color {
        isQuietHoursActive ? .indigo : .white
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
                .foregroundStyle(DS.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

private struct ActiveCallView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accountPreferenceQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("accountPreferenceQuietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("accountPreferenceQuietHoursEnd") private var quietHoursEnd = "07:00"

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "message")
                        .foregroundStyle(.white)
                }
                .padding()

                Spacer()

                if isQuietHoursActive {
                    VStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo)
                        Text("Sessiz saatler aktif")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text("Arama devam eder, ancak ekran vurgusu ve dikkat cekici tonlar yumusatildi.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .padding(16)
                    .background(.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 32)
                }

                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                    .frame(width: 88, height: 118)
                    .overlay {
                        Text("Görüntülü")
                            .foregroundStyle(DS.Colors.textSecondary)
                    }

                Spacer()

                HStack(spacing: 24) {
                    callButton("video.fill", color: controlButtonColor)
                    callButton("mic.fill", color: controlButtonColor)
                    callButton("camera.fill", color: controlButtonColor)
                    callButton("phone.down.fill", color: hangupButtonColor)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var isQuietHoursActive: Bool {
        QuietHoursLogic.isActive(
            enabled: quietHoursEnabled,
            start: quietHoursStart,
            end: quietHoursEnd
        )
    }

    private var controlButtonColor: Color {
        isQuietHoursActive ? .gray.opacity(0.75) : .gray
    }

    private var hangupButtonColor: Color {
        isQuietHoursActive ? .red.opacity(0.75) : .red
    }

    private func callButton(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.title2)
            .frame(width: 64, height: 64)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(Circle())
    }
}
