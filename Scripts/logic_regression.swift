import Foundation

@discardableResult
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if condition() {
        print("PASS: \(message)")
        return true
    }

    fputs("FAIL: \(message)\n", stderr)
    exit(1)
}

func expectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) {
    expect(lhs == rhs, message)
}

func smokeCoreDecodingAndRouting() throws {
    let conversation = try JSONDecoder().decode(
        ConversationItem.self,
        from: Data(#"{"id":"chat-1","participant_user_id":"provider-1","participantName":"Ayse Yilmaz","lastMessage":"Merhaba","lastMessageAt":"2026-03-21T10:00:00Z","unreadCount":1}"#.utf8)
    )

    expectEqual(conversation.participantID, "provider-1", "conversation fallback decode calisiyor")

    let notification = AppNotification(
        id: "notif-1",
        title: "Yeni mesaj",
        body: "Ayse Yilmaz sana yazdi",
        createdAt: "2026-03-21T10:00:00Z",
        read: false
    )

    expectEqual(
        DashboardRouting.destination(for: notification, conversations: [conversation]),
        .conversation(conversation),
        "dashboard routing sohbet hedefine gidiyor"
    )
}

func smokePresentationAndDistance() {
    let presentation = BookingStatusPresentation.make(for: "CONFIRMED", paymentStatus: "PAID")
    expectEqual(presentation.paymentLabel, "Tamamlandi", "booking presentation override calisiyor")

    let distance = DistanceMath.distanceInKilometers(
        from: 40.9927,
        originLongitude: 29.0277,
        to: 41.0430,
        destinationLongitude: 29.0094
    )
    expect(distance != nil, "distance math sonuc uretiyor")
}

func smokeMutationAndCheckoutPlans() {
    expectEqual(NotificationMutationPlan.markReadCandidates(notificationID: "notif-1").count, 3, "notification mutation plan hazir")
    expectEqual(BookingMutationPlan.cancelCandidates(bookingID: "booking-1").count, 4, "booking mutation plan hazir")
    expectEqual(BookingMutationPlan.rescheduleCandidates(bookingID: "booking-1").count, 4, "booking reschedule plan hazir")
    expectEqual(
        CheckoutCompletionDetector.completion(for: URL(string: "https://example.com/return?payment_status=succeeded")!),
        .success,
        "checkout completion detector calisiyor"
    )
}

func smokeChatHelpers() {
    expectEqual(
        ChatSocketPayloadParser.event(from: #"{"event":"typing","conversationId":"chat-1","typing":true}"#),
        .typing(chatID: "chat-1", isTyping: true),
        "chat payload parser calisiyor"
    )
    expectEqual(ChatSocketReconnectPlan.reconnectDelay(forAttempt: 10), 30, "chat reconnect cap calisiyor")
}

@main
struct LogicRegressionRunner {
    static func main() {
        do {
            try smokeCoreDecodingAndRouting()
            smokePresentationAndDistance()
            smokeMutationAndCheckoutPlans()
            smokeChatHelpers()
            print("All smoke regressions passed.")
        } catch {
            fputs("FAIL: \(error)\n", stderr)
            exit(1)
        }
    }
}
