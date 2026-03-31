//
//  SessionStore.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import Foundation
import Combine
import UIKit
@preconcurrency import UserNotifications

@MainActor
final class SessionStore: ObservableObject {
    @Published var isBootstrapping = true
    @Published var isLoggedIn = false
    @Published var me: MeResponse?
    @Published var unreadMessageCount = 0
    @Published var unreadNotificationCount = 0

    let deps: AppDependencies
    private var inboxRefreshTask: Task<Void, Never>?
    private var knownUnreadMessageNotificationIDs: Set<String> = []
    private var hasPrimedUnreadMessageState = false

    init(deps: AppDependencies) {
        self.deps = deps
        self.isLoggedIn = deps.tokenStore.getToken() != nil
    }

    func bootstrap() async {
        guard deps.tokenStore.getToken() != nil else {
            isLoggedIn = false
            me = nil
            isBootstrapping = false
            return
        }

        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            me = try await deps.auth.me()
            isLoggedIn = true
            startInboxRefreshLoop()
            await refreshInboxState()
        } catch {
            try? deps.tokenStore.clearToken()
            me = nil
            isLoggedIn = false
            stopInboxRefreshLoop()
            resetUnreadState()
        }
    }

    func logout() {
        stopInboxRefreshLoop()
        try? deps.tokenStore.clearToken()
        me = nil
        isLoggedIn = false
        resetUnreadState()
    }

    func refreshInboxState() async {
        guard isLoggedIn, deps.tokenStore.getToken() != nil else {
            resetUnreadState()
            return
        }

        async let notificationsTask = deps.notificationService.listNotifications()
        async let conversationsTask = deps.chatService.listConversations()

        var fetchedNotifications: [AppNotification] = []
        var fetchedConversations: [ConversationItem] = []

        do {
            let notificationsResponse = try await notificationsTask
            fetchedNotifications = notificationsResponse.notifications
        } catch {
            fetchedNotifications = []
        }

        do {
            let conversationsResponse = try await conversationsTask
            fetchedConversations = conversationsResponse.conversations
        } catch {
            fetchedConversations = []
        }

        let unreadMessageNotifications = fetchedNotifications.filter { !$0.read && $0.isMessageNotification }
        let unreadMessageNotificationIDs = Set(unreadMessageNotifications.map(\.id))
        let conversationUnreadCount = fetchedConversations.reduce(0) { $0 + $1.unreadCount }

        unreadMessageCount = max(conversationUnreadCount, unreadMessageNotificationIDs.count)
        unreadNotificationCount = fetchedNotifications.filter { !$0.read }.count
        updateApplicationBadgeCount()

        if hasPrimedUnreadMessageState {
            let newUnreadIDs = unreadMessageNotificationIDs.subtracting(knownUnreadMessageNotificationIDs)
            let notificationsByID = Dictionary(uniqueKeysWithValues: unreadMessageNotifications.map { ($0.id, $0) })
            for id in newUnreadIDs {
                guard let notification = notificationsByID[id] else { continue }
                scheduleLocalMessageNotification(notification)
            }
        } else {
            hasPrimedUnreadMessageState = true
        }

        knownUnreadMessageNotificationIDs = unreadMessageNotificationIDs
    }

    private func startInboxRefreshLoop() {
        stopInboxRefreshLoop()
        guard isLoggedIn else { return }

        inboxRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshInboxState()
                try? await Task.sleep(nanoseconds: 20_000_000_000)
            }
        }
    }

    private func stopInboxRefreshLoop() {
        inboxRefreshTask?.cancel()
        inboxRefreshTask = nil
    }

    private func resetUnreadState() {
        unreadMessageCount = 0
        unreadNotificationCount = 0
        knownUnreadMessageNotificationIDs = []
        hasPrimedUnreadMessageState = false
        updateApplicationBadgeCount()
    }

    private func updateApplicationBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(unreadNotificationCount)
    }

    private func scheduleLocalMessageNotification(_ notification: AppNotification) {
        UNUserNotificationCenter.current().getNotificationSettings { [unreadNotificationCount] settings in
            let isAuthorized =
                settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
            guard isAuthorized else { return }

            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            content.badge = NSNumber(value: unreadNotificationCount)
            content.userInfo = [
                "notification_id": notification.id,
                "title": notification.title,
                "body": notification.body,
                "type": notification.type ?? "chat_message",
                "created_at": notification.createdAt
            ]

            let request = UNNotificationRequest(
                identifier: "chat-message-\(notification.id)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
}
