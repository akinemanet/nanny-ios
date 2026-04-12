import SwiftUI
import FirebaseMessaging
import UIKit
import UserNotifications

struct PushDebugView: View {
    @State private var fcmToken = "Yükleniyor..."
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage("pushHasAPNSToken") private var hasAPNSToken = false
    @AppStorage("pushLastAPNSErrorMessage") private var lastAPNSErrorMessage = ""
    @AppStorage("pushLastAPNsAttemptAt") private var lastAPNsAttemptAt = ""
    @AppStorage("pushLastAPNsCallbackAt") private var lastAPNsCallbackAt = ""
    @AppStorage("pushLastAPNsStatus") private var lastAPNsStatus = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bildirim Kontrolü")
                .font(.title2.bold())

            Text(hasAPNSToken ? "APNs durumu: Hazır" : "APNs durumu: Eksik")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(hasAPNSToken ? .green : .orange)

            Text(permissionSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Bundle ID: \(Bundle.main.bundleIdentifier ?? "-")")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)

            if !lastAPNsStatus.isEmpty {
                Text("Son APNs durumu: \(lastAPNsStatus)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }

            if !lastAPNsAttemptAt.isEmpty {
                Text("Son deneme: \(formattedDebugDate(lastAPNsAttemptAt))")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }

            if !lastAPNsCallbackAt.isEmpty {
                Text("Son callback: \(formattedDebugDate(lastAPNsCallbackAt))")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }

            if !hasAPNSToken, !lastAPNSErrorMessage.isEmpty {
                Text("APNs hata detayı:")
                    .font(.headline)
                Text(lastAPNSErrorMessage)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
            }

            Text("FCM Jetonu:")
                .font(.headline)

            Text(fcmToken)
                .font(.footnote.monospaced())
                .textSelection(.enabled)

            VStack(alignment: .leading, spacing: 10) {
                Button("Bildirim İznini Yeniden İste") {
                    requestPermission()
                }
                .buttonStyle(.borderedProminent)

                Button("Ayarları Aç") {
                    openSystemSettings()
                }
                .buttonStyle(.bordered)

                Button("Durumu Yenile") {
                    Task {
                        await refreshStatus()
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .padding()
        .task {
            await refreshStatus()
        }
    }

    private var permissionSummary: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Bildirim izni açık görünüyor."
        case .denied:
            return "Bildirim izni kapalı. Ayarlar'dan izin verirsen jeton oluşabilir."
        case .notDetermined:
            return "Bildirim izni henüz sorulmamış görünüyor."
        @unknown default:
            return "Bildirim izni durumu kontrol ediliyor."
        }
    }

    @MainActor
    private func refreshStatus() async {
        let settings = await notificationSettings()
        authorizationStatus = settings.authorizationStatus

        if authorizationStatus == .authorized
            || authorizationStatus == .provisional
            || authorizationStatus == .ephemeral {
            AppDelegate.recordAPNsAttempt(context: "debug_refresh")
            UIApplication.shared.registerForRemoteNotifications()
        }

        guard hasAPNSToken else {
            fcmToken = "Bu cihaz henüz bildirim almaya hazır görünmüyor. Bildirim izni, gerçek cihaz kaydı ve Apple bildirim ayarları tamamlandığında burada jeton görünecek."
            return
        }

        do {
            let token = try await Messaging.messaging().token()
            fcmToken = token
        } catch {
            fcmToken = "FCM token alınamadı: \(error.localizedDescription)"
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    AppDelegate.recordAPNsAttempt(context: "debug_permission_button")
                    UIApplication.shared.registerForRemoteNotifications()
                }
                Task { await refreshStatus() }
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func formattedDebugDate(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) {
            return date.formatted(
                .dateTime
                    .locale(Locale(identifier: "tr_TR"))
                    .hour()
                    .minute()
                    .second()
            )
        }
        return value
    }
}
