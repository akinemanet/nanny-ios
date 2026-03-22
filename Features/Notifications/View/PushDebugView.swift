import SwiftUI
import FirebaseMessaging

struct PushDebugView: View {
    @State private var fcmToken = "Yükleniyor..."

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Push Hata Ayıklama")
                .font(.title2.bold())

            Text("FCM Jetonu:")
                .font(.headline)

            Text(fcmToken)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
        }
        .padding()
        .task {
            do {
                let token = try await Messaging.messaging().token()
                fcmToken = token
                print("Manual FCM token:", token)
            } catch {
                fcmToken = "Token alınamadı: \(error.localizedDescription)"
            }
        }
    }
}
