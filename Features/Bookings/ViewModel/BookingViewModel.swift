import Foundation
import Combine

@MainActor
final class BookingViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var success = false
    @Published var error: String?
    @Published var createdBooking: BookingRecord?

    private let service: BookingService

    init(service: BookingService) {
        self.service = service
    }

    func book(
        providerId: String,
        date: Date,
        time: String,
        familyDisplayName: String? = nil,
        familyAbout: String? = nil,
        familyLocationName: String? = nil,
        familyLocationLatitude: Double? = nil,
        familyLocationLongitude: Double? = nil
    ) async {
        isLoading = true
        success = false
        error = nil
        createdBooking = nil

        do {
            let calendar = Calendar.current
            let parts = time.split(separator: ":")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]),
                  let startDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: date
                  ) else {
                error = "Lütfen geçerli bir saat seç."
                isLoading = false
                return
            }

            let formatter = ISO8601DateFormatter()
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: startDate.addingTimeInterval(60 * 60))

            let response = try await service.createBooking(
                req: CreateBookingReq(
                    providerUserID: providerId,
                    service: "BABYSITTER",
                    startAt: start,
                    endAt: end,
                    bookingType: "HOURLY",
                    familyDisplayName: familyDisplayName,
                    familyAbout: familyAbout,
                    familyLocationName: familyLocationName,
                    familyLocationLatitude: familyLocationLatitude,
                    familyLocationLongitude: familyLocationLongitude
                )
            )

            createdBooking = response.booking
            success = true

        } catch {
            let message = error.localizedDescription
            if message.localizedCaseInsensitiveContains("provider not available") {
                self.error = "Seçtiğin tarih veya saatte bakıcı uygun görünmüyor."
            } else if message.localizedCaseInsensitiveContains("http 500") {
                self.error = "Rezervasyon şu anda oluşturulamıyor. Lütfen daha sonra tekrar dene."
            } else {
                self.error = "Rezervasyon oluşturulamadı."
            }
        }

        isLoading = false
    }
}
