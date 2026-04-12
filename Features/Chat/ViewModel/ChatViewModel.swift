import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [ConversationItem] = []
    @Published var messages: [ChatMessage] = []
    @Published var calls: [CallItem] = []
    @Published var error: String?
    @Published var isParticipantTyping = false
    @Published var latestConversationUpdate: ConversationItem?

    private let socket = ChatSocket()
    private var service: ChatService
    private var cancellables: Set<AnyCancellable> = []
    private var typingResetTask: Task<Void, Never>?
    private var typingStopTask: Task<Void, Never>?
    private var currentChatID: String?

    init(service: ChatService) {
        self.service = service
        socket.$lastEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleSocketEvent(event)
            }
            .store(in: &cancellables)
    }

    func replaceServiceIfNeeded(_ service: ChatService) {
        self.service = service
    }

    func connect(token: String) {
        socket.connect(token: token)
    }

    func send(text: String) {
        socket.send(text)
    }

    func beginChatSession(chatID: String) {
        currentChatID = chatID
        isParticipantTyping = false
    }

    func userTypingChanged(chatID: String, text: String) {
        guard !text.isEmpty else {
            typingStopTask?.cancel()
            socket.sendTyping(chatID: chatID, isTyping: false)
            return
        }

        socket.sendTyping(chatID: chatID, isTyping: true)
        typingStopTask?.cancel()
        typingStopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.socket.sendTyping(chatID: chatID, isTyping: false)
            }
        }
    }

    func loadConversations() async {
        do {
            conversations = try await service.listConversations().conversations
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadMessages(chatID: String) async {
        do {
            messages = try await service.listMessages(chatID: chatID).messages
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage(chatID: String, text: String) async {
        do {
            let message = try await service.sendMessage(chatID: chatID, text: text)
            messages.append(message)
            applyConversationPreviewUpdate(
                chatID: chatID,
                lastMessage: message.text,
                lastMessageAt: message.createdAt,
                unreadCount: 0
            )
            socket.sendTyping(chatID: chatID, isTyping: false)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadCalls() async {
        do {
            calls = try await service.listCalls().calls
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createCall(participantName: String, status: String) async {
        do {
            let created = try await service.createCall(
                participantName: participantName,
                direction: "OUTGOING",
                status: status
            )
            calls.insert(created, at: 0)
        } catch {
            // Call history should not block the native dialer/FaceTime handoff.
        }
    }

    func markConversationRead(chatID: String) async -> Bool {
        do {
            try await service.markConversationRead(chatID: chatID)
            return true
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    return true
                }
                self.error = error.localizedDescription
                return false
            default:
                self.error = error.localizedDescription
                return false
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
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

    private func handleSocketEvent(_ event: ChatSocketEvent?) {
        guard let event else { return }
        switch event {
        case .typing(let chatID, let isTyping):
            guard chatID == currentChatID else { return }
            isParticipantTyping = isTyping
            typingResetTask?.cancel()
            if isTyping {
                typingResetTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self?.isParticipantTyping = false
                    }
                }
            }
        case .message(let chatID, let text, let createdAt):
            applyConversationPreviewUpdate(
                chatID: chatID,
                lastMessage: text,
                lastMessageAt: createdAt,
                unreadCount: chatID == currentChatID ? 0 : nil
            )
            guard chatID == currentChatID else { return }
            messages.append(
                ChatMessage(
                    id: UUID().uuidString,
                    text: text,
                    isMine: false,
                    createdAt: createdAt
                )
            )
        }
    }

    func applyConversationPreviewUpdate(
        chatID: String,
        lastMessage: String,
        lastMessageAt: String,
        unreadCount: Int?
    ) {
        guard let index = conversations.firstIndex(where: { $0.id == chatID }) else { return }
        let existing = conversations[index]
        let updated = ConversationItem(
            id: existing.id,
            participantID: existing.participantID,
            participantName: existing.participantName,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt,
            unreadCount: unreadCount ?? existing.unreadCount + 1
        )
        conversations.remove(at: index)
        conversations.insert(updated, at: 0)
        latestConversationUpdate = updated
    }
}

final class ChatService {
    private struct Empty: Encodable {}
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func listConversations() async throws -> ConversationsResponse {
        return try await api.request(
            "v1/chats",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
    }

    func unreadConversationCount(fallback conversations: [ConversationItem]) async throws -> Int {
        var lastError: Error?

        for candidate in ProviderDashboardSummaryPlan.unreadMessageCandidates() {
            do {
                let response: ChatUnreadSummaryResponse = try await api.request(
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
        return conversations.reduce(0) { $0 + $1.unreadCount }
    }

    func listMessages(chatID: String) async throws -> MessagesResponse {
        return try await api.request(
            "v1/chats/\(chatID)/messages",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
    }

    func startConversation(participantID: String) async throws -> ConversationItem {
        let response: StartConversationResponse = try await api.request(
            "v1/chats",
            method: "POST",
            body: StartConversationReq(participantUserID: participantID),
            needsAuth: true
        )
        return response.conversation
    }

    func sendMessage(chatID: String, text: String) async throws -> ChatMessage {
        try await api.request(
            "v1/chats/\(chatID)/messages",
            method: "POST",
            body: SendMessageReq(text: text),
            needsAuth: true
        )
    }

    func listCalls() async throws -> CallsResponse {
        return try await api.request(
            "v1/calls",
            method: "GET",
            body: Optional<Empty>.none,
            needsAuth: true
        )
    }

    func createCall(participantName: String, direction: String, status: String) async throws -> CallItem {
        try await api.request(
            "v1/calls",
            method: "POST",
            body: CreateCallReq(
                participantName: participantName,
                direction: direction,
                status: status
            ),
            needsAuth: true
        )
    }

    func markConversationRead(chatID: String) async throws {
        let candidates: [(path: String, method: String)] = [
            ("v1/chats/\(chatID)/read", "POST"),
            ("v1/chats/\(chatID)/read", "PATCH"),
            ("v1/chats/\(chatID)", "PATCH")
        ]

        var lastError: Error?

        for candidate in candidates {
            do {
                if candidate.path.hasSuffix("/read") {
                    let _: ChatReadMutationResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: Optional<Empty>.none,
                        needsAuth: true
                    )
                } else {
                    let _: ChatReadMutationResponse = try await api.request(
                        candidate.path,
                        method: candidate.method,
                        body: ChatReadReq(read: true),
                        needsAuth: true
                    )
                }
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

private struct StartConversationReq: Encodable {
    let participantUserID: String

    enum CodingKeys: String, CodingKey {
        case participantUserID = "participant_user_id"
    }
}

private struct StartConversationResponse: Decodable {
    let conversation: ConversationItem
}

private struct CreateCallReq: Encodable {
    let participantName: String
    let direction: String
    let status: String
}

private struct ChatUnreadSummaryResponse: Decodable {
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

private struct ChatReadMutationResponse: Decodable {
    let ok: Bool?
}

private struct ChatReadReq: Encodable {
    let read: Bool
}
