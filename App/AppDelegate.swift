import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        _ = error
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let defaults = UserDefaults.standard
        let pushAlerts = defaults.bool(forKey: "accountPreferencePushAlerts")
        let bookingConfirmedEnabled = defaults.object(forKey: "accountPreferenceBookingConfirmedNotifications") as? Bool ?? true
        let bookingRejectedEnabled = defaults.object(forKey: "accountPreferenceBookingRejectedNotifications") as? Bool ?? true
        let bookingCompletedEnabled = defaults.object(forKey: "accountPreferenceBookingCompletedNotifications") as? Bool ?? true
        let enabled = defaults.bool(forKey: "accountPreferenceQuietHoursEnabled")
        let start = defaults.string(forKey: "accountPreferenceQuietHoursStart") ?? "22:00"
        let end = defaults.string(forKey: "accountPreferenceQuietHoursEnd") ?? "07:00"
        let presentation = ForegroundNotificationPresentation.make(
            userInfo: notification.request.content.userInfo,
            pushAlertsEnabled: pushAlerts,
            bookingConfirmedEnabled: bookingConfirmedEnabled,
            bookingRejectedEnabled: bookingRejectedEnabled,
            bookingCompletedEnabled: bookingCompletedEnabled,
            quietHoursEnabled: enabled,
            quietHoursStart: start,
            quietHoursEnd: end
        )
        completionHandler(presentationOptions(from: presentation.options))
    }

    private func presentationOptions(from options: [String]) -> UNNotificationPresentationOptions {
        var presentation: UNNotificationPresentationOptions = []

        if options.contains("banner") {
            presentation.insert(.banner)
        }
        if options.contains("sound") {
            presentation.insert(.sound)
        }
        if options.contains("badge") {
            presentation.insert(.badge)
        }

        return presentation
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let notification = AppNotification(userInfo: response.notification.request.content.userInfo) {
            NotificationCenter.default.post(
                name: .appDidOpenRemoteNotification,
                object: notification
            )
        }
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        _ = fcmToken
    }
}
