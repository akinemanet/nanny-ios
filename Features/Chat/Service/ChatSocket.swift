import Foundation
import Combine

enum ChatSocketEvent: Equatable {
    case typing(chatID: String, isTyping: Bool)
    case message(chatID: String, text: String, createdAt: String)
}

final class ChatSocket: ObservableObject {
    @Published private(set) var lastEvent: ChatSocketEvent?

    private let heartbeatInterval: TimeInterval = 20

    private var session: URLSession?
    private var webSocket: URLSessionWebSocketTask?
    private var currentToken: String?
    private var heartbeatTimer: Timer?
    private var reconnectWorkItem: DispatchWorkItem?
    private var isConnected = false
    private var reconnectAttempt = 0

    func connect(token: String) {
        reconnectWorkItem?.cancel()

        if ChatSocketReconnectPlan.shouldReuseOpenConnection(
            currentToken: currentToken,
            incomingToken: token,
            isConnected: isConnected,
            hasSocket: webSocket != nil
        ) {
            return
        }

        currentToken = token
        reconnectAttempt = 0

        let url = URL(string: "wss://api.clickajans.net/ws?token=\(token)")!
        let session = URLSession(configuration: .default)
        self.session = session

        heartbeatTimer?.invalidate()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        isConnected = true
        startHeartbeat()

        listen()
    }

    func listen() {
        webSocket?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handle(text: text)
                default:
                    break
                }
                self.listen()
            case .failure(let error):
                print("WS error:", error)
                self.handleDisconnect()
            }
        }
    }

    func send(_ text: String) {
        webSocket?.send(.string(text)) { error in
            if let error = error {
                print(error)
            }
        }
    }

    func sendTyping(chatID: String, isTyping: Bool) {
        let payload: [String: Any] = [
            "type": "typing",
            "chat_id": chatID,
            "is_typing": isTyping
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else {
            return
        }

        send(text)
    }

    private func handle(text: String) {
        guard let parsedEvent = ChatSocketPayloadParser.event(from: text) else { return }

        DispatchQueue.main.async { [weak self] in
            switch parsedEvent {
            case .typing(let chatID, let isTyping):
                self?.lastEvent = .typing(chatID: chatID, isTyping: isTyping)
            case .message(let chatID, let text, let createdAt):
                self?.lastEvent = .message(chatID: chatID, text: text, createdAt: createdAt)
            }
        }
    }

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }

    private func sendHeartbeat() {
        webSocket?.sendPing { [weak self] error in
            if let error {
                print("WS ping error:", error)
                self?.handleDisconnect()
            }
        }
    }

    private func handleDisconnect() {
        guard
            ChatSocketReconnectPlan.shouldScheduleReconnect(currentToken: currentToken),
            let token = currentToken
        else {
            return
        }

        isConnected = false
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        reconnectWorkItem?.cancel()
        let delay = ChatSocketReconnectPlan.reconnectDelay(forAttempt: reconnectAttempt)
        reconnectAttempt += 1

        let workItem = DispatchWorkItem { [weak self] in
            self?.webSocket?.cancel(with: .goingAway, reason: nil)
            self?.webSocket = nil
            self?.connect(token: token)
        }

        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}
