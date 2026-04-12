import XCTest
@testable import APIEnvironment

final class AppLogicTests: XCTestCase {
    private func makeNotification(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        createdAt: String = "2026-03-21T10:00:00Z",
        read: Bool = false
    ) -> AppNotification {
        AppNotification(id: id, title: title, body: body, createdAt: createdAt, read: read)
    }

    func testConversationDecodingFallbacks() throws {
        let decoder = JSONDecoder()
        let payloads = [
            #"{"id":"chat-1","participant_user_id":"provider-1","participantName":"Ayse","lastMessage":"Merhaba","lastMessageAt":"2026-03-21T10:00:00Z","unreadCount":1}"#,
            #"{"id":"chat-2","participant_id":"provider-2","participantName":"Merve","lastMessage":"Selam","lastMessageAt":"2026-03-21T10:00:00Z","unreadCount":0}"#,
            #"{"id":"chat-3","user_id":"provider-3","participantName":"Zeynep","lastMessage":"Gorusuruz","lastMessageAt":"2026-03-21T10:00:00Z","unreadCount":2}"#
        ]

        let decoded = try payloads.map { try decoder.decode(ConversationItem.self, from: Data($0.utf8)) }
        XCTAssertEqual(decoded[0].participantID, "provider-1")
        XCTAssertEqual(decoded[1].participantID, "provider-2")
        XCTAssertEqual(decoded[2].participantID, "provider-3")
    }

    func testAppNotificationUserInfoDecoding() {
        let notification = AppNotification(userInfo: [
            "aps": [
                "alert": [
                    "title": "Bakici Onay Verdi",
                    "body": "Ayse, Demir Ailesi icin 21.03 10:00 babysitter (sana cok yakin) talebini onayladi."
                ]
            ],
            "type": "booking_confirmed",
            "booking_id": "booking-42"
        ])

        XCTAssertEqual(notification?.title, "Bakici Onay Verdi")
        XCTAssertEqual(notification?.bookingID, "booking-42")
        XCTAssertEqual(notification?.type, "booking_confirmed")
    }

    func testBookingRecordDecodingFallbacks() throws {
        let decoder = JSONDecoder()
        let payload = #"""
        {
          "id": "booking-1",
          "parent_user_id": "parent-1",
          "provider_user_id": "provider-1",
          "service": "BABYSITTER",
          "start_at": "2026-03-21T10:00:00Z",
          "end_at": "2026-03-21T12:00:00Z",
          "booking_type": "ONE_TIME",
          "status": "CONFIRMED",
          "total_price": 1500,
          "payment_status": "PAID",
          "address": "Kadikoy",
          "provider": {
            "displayName": "Ayse",
            "hourly_rate": 750
          }
        }
        """#

        let decoded = try decoder.decode(BookingRecord.self, from: Data(payload.utf8))
        XCTAssertEqual(decoded.totalPrice, 1500)
        XCTAssertEqual(decoded.paymentStatus, "PAID")
        XCTAssertEqual(decoded.address, "Kadikoy")
        XCTAssertEqual(decoded.providerDisplayName, "Ayse")
        XCTAssertEqual(decoded.providerHourlyRate, 750)

        let familyPayload = #"""
        {
          "id": "booking-2",
          "parent_user_id": "parent-2",
          "provider_user_id": "provider-9",
          "service": "BABYSITTER",
          "start_at": "2026-03-21T13:00:00Z",
          "end_at": "2026-03-21T14:00:00Z",
          "booking_type": "HOURLY",
          "status": "REQUESTED",
          "family_display_name": "Demir Ailesi",
          "family_about": "Iki cocuk icin aksam destegi ariyoruz",
          "family_location_name": "Kadikoy, Istanbul",
          "family_location_latitude": 40.9927,
          "family_location_longitude": 29.0277
        }
        """#

        let familyDecoded = try decoder.decode(BookingRecord.self, from: Data(familyPayload.utf8))
        XCTAssertEqual(familyDecoded.familyDisplayName, "Demir Ailesi")
        XCTAssertEqual(familyDecoded.familyAbout, "Iki cocuk icin aksam destegi ariyoruz")
        XCTAssertEqual(familyDecoded.familyLocationName, "Kadikoy, Istanbul")
        XCTAssertEqual(familyDecoded.familyLocationLatitude, 40.9927)
        XCTAssertEqual(familyDecoded.familyLocationLongitude, 29.0277)
    }

    func testDashboardConversationMatchingAndNotificationRouting() {
        let conversations = [
            ConversationItem(
                id: "chat-1",
                participantID: "provider-1",
                participantName: "Ayse Yilmaz",
                lastMessage: "Merhaba",
                lastMessageAt: "2026-03-21T10:00:00Z",
                unreadCount: 0
            ),
            ConversationItem(
                id: "chat-2",
                participantID: nil,
                participantName: "Çağla Demir",
                lastMessage: "Yoldayim",
                lastMessageAt: "2026-03-21T10:05:00Z",
                unreadCount: 1
            )
        ]

        XCTAssertEqual(
            DashboardRouting.conversation(
                forProviderID: "provider-1",
                participantName: "Baska Isim",
                conversations: conversations
            )?.id,
            "chat-1"
        )

        XCTAssertEqual(
            DashboardRouting.conversation(
                forProviderID: "missing",
                participantName: "cagla demir",
                conversations: conversations
            )?.id,
            "chat-2"
        )

        XCTAssertEqual(
            DashboardRouting.destination(
                for: makeNotification(title: "Yeni mesaj", body: "Ayse Yilmaz sana yazdi"),
                conversations: conversations
            ),
            .conversation(conversations[0])
        )
        XCTAssertEqual(
            DashboardRouting.destination(
                for: makeNotification(title: "Rezervasyon onayi", body: "Takviminde yeni bir rezervasyon var"),
                conversations: conversations
            ),
            .bookings
        )
        XCTAssertEqual(
            DashboardRouting.destination(
                for: AppNotification(
                    id: "notif-booking",
                    title: "Hizmet Tamamlandi",
                    body: "Ayse rezervasyonu tamamladi",
                    createdAt: "2026-03-21T10:00:00Z",
                    read: false,
                    type: "booking_completed",
                    bookingID: "booking-42"
                ),
                conversations: conversations
            ),
            .bookingDetail("booking-42")
        )
        XCTAssertEqual(
            DashboardRouting.destination(
                for: makeNotification(title: "Hos geldin", body: "Profilini tamamla"),
                conversations: conversations
            ),
            .notifications
        )
    }

    func testDistanceMath() {
        let distance = DistanceMath.distanceInKilometers(
            from: 40.9927,
            originLongitude: 29.0277,
            to: 41.0430,
            destinationLongitude: 29.0094
        )

        XCTAssertNotNil(distance)
        if let distance {
            XCTAssertGreaterThan(distance, 5)
            XCTAssertLessThan(distance, 7.5)
        }

        XCTAssertEqual(
            DistanceMath.distanceText(
                from: 40.9927,
                originLongitude: 29.0277,
                to: nil,
                destinationLongitude: nil,
                fallback: "Bilinmiyor"
            ),
            "Bilinmiyor"
        )
    }

    func testCurrencyFormatting() {
        XCTAssertEqual(CurrencyFormatting.symbol(for: "TRY"), "₺")
        XCTAssertEqual(CurrencyFormatting.symbol(for: "USD"), "$")
        XCTAssertEqual(CurrencyFormatting.symbol(for: "EUR"), "€")
        XCTAssertEqual(CurrencyFormatting.formattedAmount(650, currencyCode: "USD"), "$650")
        XCTAssertEqual(CurrencyFormatting.formattedHourlyRate(700, currencyCode: "EUR"), "€700/saat")
    }

    func testQuietHoursLogic() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let lateNight = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 21,
            hour: 23,
            minute: 0
        ).date!

        let morning = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 21,
            hour: 10,
            minute: 0
        ).date!

        XCTAssertTrue(
            QuietHoursLogic.isActive(
                enabled: true,
                start: "22:00",
                end: "07:00",
                now: lateNight,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            QuietHoursLogic.isActive(
                enabled: true,
                start: "22:00",
                end: "07:00",
                now: morning,
                calendar: calendar
            )
        )
        XCTAssertEqual(
            QuietHoursLogic.notificationPresentationOptions(
                enabled: true,
                start: "22:00",
                end: "07:00",
                now: lateNight,
                calendar: calendar
            ),
            ["badge"]
        )
        XCTAssertEqual(
            QuietHoursLogic.notificationPresentationOptions(
                enabled: true,
                start: "22:00",
                end: "07:00",
                now: morning,
                calendar: calendar
            ),
            ["banner", "sound", "badge"]
        )

        XCTAssertEqual(
            ForegroundNotificationPresentation.make(
                userInfo: ["type": "booking_completed"],
                pushAlertsEnabled: true,
                bookingConfirmedEnabled: true,
                bookingRejectedEnabled: true,
                bookingCompletedEnabled: true,
                quietHoursEnabled: false,
                quietHoursStart: "22:00",
                quietHoursEnd: "07:00",
                now: morning,
                calendar: calendar
            ).options,
            ["badge"]
        )
        XCTAssertEqual(
            ForegroundNotificationPresentation.make(
                userInfo: ["type": "booking_confirmed"],
                pushAlertsEnabled: true,
                bookingConfirmedEnabled: true,
                bookingRejectedEnabled: true,
                bookingCompletedEnabled: true,
                quietHoursEnabled: false,
                quietHoursStart: "22:00",
                quietHoursEnd: "07:00",
                now: morning,
                calendar: calendar
            ).options,
            ["banner", "badge"]
        )
        XCTAssertEqual(
            ForegroundNotificationPresentation.make(
                userInfo: ["type": "booking_rejected"],
                pushAlertsEnabled: true,
                bookingConfirmedEnabled: true,
                bookingRejectedEnabled: true,
                bookingCompletedEnabled: true,
                quietHoursEnabled: false,
                quietHoursStart: "22:00",
                quietHoursEnd: "07:00",
                now: morning,
                calendar: calendar
            ).options,
            ["banner", "sound", "badge"]
        )
        XCTAssertEqual(
            ForegroundNotificationPresentation.make(
                userInfo: ["type": "booking_completed"],
                pushAlertsEnabled: true,
                bookingConfirmedEnabled: true,
                bookingRejectedEnabled: true,
                bookingCompletedEnabled: false,
                quietHoursEnabled: false,
                quietHoursStart: "22:00",
                quietHoursEnd: "07:00",
                now: morning,
                calendar: calendar
            ).options,
            []
        )
    }

    func testProviderAvailabilityLogic() {
        let selections = [
            "2026-03-25": ["13:00", "09:00"],
            "2026-03-22": ["10:00"]
        ]

        let raw = ProviderAvailabilityLogic.encodeSelections(selections)
        let decoded = ProviderAvailabilityLogic.decodeSelections(raw)

        XCTAssertEqual(decoded["2026-03-25"] ?? [], ["13:00", "09:00"])
        XCTAssertEqual(ProviderAvailabilityLogic.sortedSlots(["13:00", "09:00"]), ["09:00", "13:00"])
        XCTAssertEqual(ProviderAvailabilityLogic.totalSlotCount(in: decoded), 3)

        let now = ISO8601DateFormatter().date(from: "2026-03-21T10:00:00Z")!
        XCTAssertEqual(
            ProviderAvailabilityLogic.nextAvailableDate(in: decoded, from: now),
            "2026-03-22"
        )

        let templates = [
            2: ["13:00", "09:00"]
        ]
        let rawTemplates = ProviderAvailabilityLogic.encodeWeeklyTemplates(templates)
        XCTAssertEqual(ProviderAvailabilityLogic.decodeWeeklyTemplates(rawTemplates)[2] ?? [], ["13:00", "09:00"])
        XCTAssertEqual(ProviderAvailabilityLogic.totalTemplateCount(in: templates), 2)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let selectedDate = ISO8601DateFormatter().date(from: "2026-03-23T10:00:00Z")!
        let recurring = ProviderAvailabilityLogic.selectionsApplyingWeeklyRule(
            currentSelections: [:],
            currentTemplates: [:],
            selectedDate: selectedDate,
            selectedSlots: ["13:00", "09:00"],
            appliesWeeklyTemplate: true,
            horizonInWeeks: 3,
            calendar: calendar
        )

        XCTAssertEqual(recurring.templates[2] ?? [], ["09:00", "13:00"])
        XCTAssertEqual(recurring.selections["2026-03-23"] ?? [], ["09:00", "13:00"])
        XCTAssertEqual(recurring.selections["2026-03-30"] ?? [], ["09:00", "13:00"])
        XCTAssertEqual(recurring.selections["2026-04-06"] ?? [], ["09:00", "13:00"])

        let nextMonday = ProviderAvailabilityLogic.nextDate(
            for: 2,
            from: ISO8601DateFormatter().date(from: "2026-03-25T10:00:00Z")!,
            calendar: calendar
        )
        let dayFormatter = ISO8601DateFormatter()
        dayFormatter.formatOptions = [.withFullDate]
        XCTAssertEqual(dayFormatter.string(from: nextMonday ?? selectedDate), "2026-03-30")

        let copiedTemplates = ProviderAvailabilityLogic.copyTemplate(
            from: 2,
            to: [3, 4],
            using: [2: ["09:00", "13:00"]]
        )
        XCTAssertEqual(copiedTemplates[3] ?? [], ["09:00", "13:00"])
        XCTAssertEqual(copiedTemplates[4] ?? [], ["09:00", "13:00"])
    }

    func testProviderAvailabilitySyncPlanCandidates() {
        let fetchCandidates = ProviderAvailabilitySyncPlan.fetchCandidates()
        XCTAssertEqual(fetchCandidates.map(\.path), [
            "v1/providers/availability",
            "v1/provider/availability",
            "v1/me/availability"
        ])
        XCTAssertEqual(fetchCandidates.map(\.method), ["GET", "GET", "GET"])

        let saveCandidates = ProviderAvailabilitySyncPlan.saveCandidates()
        XCTAssertEqual(saveCandidates.map(\.path), [
            "v1/providers/availability",
            "v1/providers/availability",
            "v1/provider/availability",
            "v1/me/availability"
        ])
        XCTAssertEqual(saveCandidates.map(\.method), ["PUT", "PATCH", "POST", "PATCH"])
        XCTAssertTrue(saveCandidates.allSatisfy(\.sendsReadBody))
    }

    func testProviderDashboardBookingPlanCandidates() {
        let todayCandidates = ProviderDashboardBookingPlan.todaysBookingsCandidates()
        XCTAssertEqual(todayCandidates.map(\.path), [
            "v1/providers/bookings/today",
            "v1/providers/bookings?scope=today",
            "v1/bookings/provider?scope=today"
        ])
        XCTAssertEqual(todayCandidates.map(\.method), ["GET", "GET", "GET"])

        let pendingCandidates = ProviderDashboardBookingPlan.pendingRequestsCandidates()
        XCTAssertEqual(pendingCandidates.map(\.path), [
            "v1/providers/bookings/requests",
            "v1/providers/bookings?scope=pending_requests",
            "v1/bookings/provider?status=requested,pending"
        ])
        XCTAssertEqual(pendingCandidates.map(\.method), ["GET", "GET", "GET"])
    }

    func testProviderDashboardSummaryPlanCandidates() {
        let messageCandidates = ProviderDashboardSummaryPlan.unreadMessageCandidates()
        XCTAssertEqual(messageCandidates.map(\.path), [
            "v1/providers/messages/summary",
            "v1/chats/summary",
            "v1/chats/unread-count"
        ])
        XCTAssertEqual(messageCandidates.map(\.method), ["GET", "GET", "GET"])

        let notificationCandidates = ProviderDashboardSummaryPlan.unreadNotificationCandidates()
        XCTAssertEqual(notificationCandidates.map(\.path), [
            "v1/providers/notifications/summary",
            "v1/notifications/summary",
            "v1/notifications/unread-count"
        ])
        XCTAssertEqual(notificationCandidates.map(\.method), ["GET", "GET", "GET"])
    }

    func testProviderEarningsSummaryPlanCandidates() {
        let candidates = ProviderEarningsSummaryPlan.candidates()
        XCTAssertEqual(candidates.map(\.path), [
            "v1/providers/earnings/summary",
            "v1/providers/payouts/summary",
            "v1/providers/dashboard/summary"
        ])
        XCTAssertEqual(candidates.map(\.method), ["GET", "GET", "GET"])
    }

    func testProviderOnboardingSummaryPlanCandidates() {
        let candidates = ProviderOnboardingSummaryPlan.candidates()
        XCTAssertEqual(candidates.map(\.path), [
            "v1/providers/onboarding-summary",
            "v1/providers/profile-summary",
            "v1/providers/payout-account"
        ])
        XCTAssertEqual(candidates.map(\.method), ["GET", "GET", "GET"])
    }

    func testProviderOnboardingMutationPlanCandidates() {
        let candidates = ProviderOnboardingMutationPlan.saveProfileCandidates()
        XCTAssertEqual(candidates.map(\.path), [
            "v1/providers/onboarding-summary",
            "v1/providers/profile-summary",
            "v1/providers/profile"
        ])
        XCTAssertEqual(candidates.map(\.method), ["PUT", "PATCH", "POST"])
        XCTAssertTrue(candidates.allSatisfy(\.sendsReadBody))
    }

    func testProviderRequestContextPresentation() {
        XCTAssertEqual(
            ProviderRequestContextPresentation.make(
                familyDisplayName: "Demir Ailesi",
                familyAbout: "Aksam destegi ariyoruz",
                familyLocationName: "Kadikoy"
            ),
            ProviderRequestContextPresentation(
                priority: 0,
                badgeTitle: "Aile Notu Var",
                badgeSystemImage: "text.bubble.fill",
                distanceBucketTitle: nil
            )
        )

        XCTAssertEqual(
            ProviderRequestContextPresentation.make(
                familyDisplayName: "Demir Ailesi",
                familyAbout: nil,
                familyLocationName: "Kadikoy"
            ).priority,
            1
        )

        XCTAssertEqual(
            ProviderRequestContextPresentation.make(
                familyDisplayName: "Demir Ailesi",
                familyAbout: nil,
                familyLocationName: "Kadikoy",
                providerLatitude: 40.9927,
                providerLongitude: 29.0277,
                familyLatitude: 41.0000,
                familyLongitude: 29.0100
            ),
            ProviderRequestContextPresentation(
                priority: 1,
                badgeTitle: "1.7 km",
                badgeSystemImage: "location.fill",
                distanceBucketTitle: "0-3 km"
            )
        )

        XCTAssertEqual(
            ProviderRequestContextPresentation.make(
                familyDisplayName: "Demir Ailesi",
                familyAbout: nil,
                familyLocationName: nil
            ).priority,
            2
        )
    }

    func testProviderNearbyFamilyLogic() {
        XCTAssertEqual(ProviderNearbyFamilyLogic.distanceBucketTitle(for: 2.4), "0-3 km")
        XCTAssertEqual(ProviderNearbyFamilyLogic.distanceBucketTitle(for: 5.1), "3-8 km")
        XCTAssertEqual(ProviderNearbyFamilyLogic.distanceBucketTitle(for: 12.0), "Uzak")
        XCTAssertEqual(
            ProviderNearbyFamilyLogic.distanceBucketTitle(
                providerLatitude: 40.9927,
                providerLongitude: 29.0277,
                familyLatitude: 41.0000,
                familyLongitude: 29.0100
            ),
            "0-3 km"
        )
        XCTAssertNil(
            ProviderNearbyFamilyLogic.distanceBucketTitle(
                providerLatitude: 40.9927,
                providerLongitude: 29.0277,
                familyLatitude: nil,
                familyLongitude: nil
            )
        )

        XCTAssertTrue(
            ProviderNearbyFamilyLogic.isNearby(
                providerLatitude: 40.9927,
                providerLongitude: 29.0277,
                familyLatitude: 41.0000,
                familyLongitude: 29.0100,
                fallbackLocationName: nil,
                maximumDistanceInKilometers: 5
            )
        )

        XCTAssertFalse(
            ProviderNearbyFamilyLogic.isNearby(
                providerLatitude: 40.9927,
                providerLongitude: 29.0277,
                familyLatitude: 41.1200,
                familyLongitude: 29.1200,
                fallbackLocationName: nil,
                maximumDistanceInKilometers: 5
            )
        )

        XCTAssertTrue(
            ProviderNearbyFamilyLogic.isNearby(
                providerLatitude: 40.9927,
                providerLongitude: 29.0277,
                familyLatitude: nil,
                familyLongitude: nil,
                fallbackLocationName: "Kadikoy"
            )
        )
    }

    func testProviderEarningsSummary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 21,
            hour: 12,
            minute: 0
        ).date!

        let bookings = [
            BookingItem(
                id: "booking-1",
                service: "BABYSITTER",
                status: "COMPLETED",
                startTime: "2026-03-21T09:00:00Z",
                endTime: "2026-03-21T11:00:00Z",
                totalPrice: 1500,
                address: nil,
                paymentStatus: "PENDING",
                provider: BookingProvider(id: "provider-1", displayName: "Ayse", hourlyRate: 750)
            ),
            BookingItem(
                id: "booking-2",
                service: "BABYSITTER",
                status: "IN_PROGRESS",
                startTime: "2026-03-21T13:00:00Z",
                endTime: "2026-03-21T15:00:00Z",
                totalPrice: 1200,
                address: nil,
                paymentStatus: nil,
                provider: BookingProvider(id: "provider-1", displayName: "Ayse", hourlyRate: 600)
            ),
            BookingItem(
                id: "booking-3",
                service: "BABYSITTER",
                status: "COMPLETED",
                startTime: "2026-03-20T13:00:00Z",
                endTime: "2026-03-20T15:00:00Z",
                totalPrice: 900,
                address: nil,
                paymentStatus: "PAID",
                provider: BookingProvider(id: "provider-1", displayName: "Ayse", hourlyRate: 450)
            )
        ]

        let summary = ProviderEarningsSummary.make(bookings: bookings, now: now, calendar: calendar)
        XCTAssertEqual(summary.completedTodayCount, 1)
        XCTAssertEqual(summary.activeTodayCount, 1)
        XCTAssertEqual(summary.todayEarnings, 1500)
        XCTAssertEqual(summary.pendingPayout, 1500)
    }

    func testNotificationMutationFallbacks() {
        XCTAssertEqual(NotificationMutationPlan.markReadCandidates(notificationID: "notif-1").count, 3)
        let completionCandidates = NotificationMutationPlan.bookingCompletedCandidates(parentUserID: "parent-1")
        XCTAssertEqual(completionCandidates.count, 3)
        XCTAssertEqual(completionCandidates.first?.path, "v1/notifications")
        XCTAssertEqual(completionCandidates.last?.path, "v1/parents/parent-1/notifications")
        XCTAssertEqual(
            BookingStatusNotificationContent.make(
                providerName: "Ayse",
                service: "BABYSITTER",
                status: "CONFIRMED",
                startAt: "2026-03-21T10:00:00Z",
                familyDisplayName: "Demir Ailesi",
                proximityText: "sana cok yakin"
            ),
            BookingStatusNotificationContent(
                title: "Bakici Onay Verdi",
                body: "Ayse, Demir Ailesi icin 21.03 10:00 babysitter (sana cok yakin) talebini onayladi.",
                type: "booking_confirmed"
            )
        )
        XCTAssertEqual(
            BookingStatusNotificationContent.make(
                providerName: "Ayse",
                service: "BABYSITTER",
                status: "CANCELED"
            ).type,
            "booking_rejected"
        )
        XCTAssertEqual(
            BookingStatusNotificationContent.make(
                providerName: "Ayse",
                service: "BABYSITTER",
                status: "COMPLETED"
            ).title,
            "Hizmet Tamamlandi"
        )
        XCTAssertEqual(
            BookingStatusNotificationContent.make(
                providerName: "Ayse",
                service: "BABYSITTER",
                status: "COMPLETED",
                startAt: "2026-03-21T19:30:00Z",
                proximityText: "4.2 km uzakta"
            ).body,
            "Ayse, 21.03 19:30 babysitter (4.2 km uzakta) hizmetini tamamladigini bildirdi."
        )
        XCTAssertEqual(
            BookingStatusNotificationContent.make(
                providerName: "Ayse",
                service: "BABYSITTER",
                status: "CANCELED"
            ).title,
            "Bakici Reddetti"
        )
        XCTAssertEqual(
            FamilyNotificationPresentation.make(type: "booking_confirmed"),
            FamilyNotificationPresentation(
                tintKey: "green",
                icon: "checkmark.seal.fill",
                badgeText: "Hizli Donus",
                highlightText: "Bakicin talebine hizli yanit verdi."
            )
        )
        XCTAssertEqual(
            FamilyNotificationPresentation.proximityBadgeText(
                from: "Ayse, Demir Ailesi icin 21.03 10:00 babysitter (sana cok yakin) talebini onayladi."
            ),
            "sana cok yakin"
        )
        XCTAssertTrue(NotificationMutationPlan.shouldFallbackForUnavailableMutation(statusCode: 404))
        XCTAssertFalse(NotificationMutationPlan.shouldFallbackForUnavailableMutation(statusCode: 500))
    }

    func testPreferenceSyncPlanCandidates() {
        let fetchCandidates = PreferenceSyncPlan.fetchCandidates()
        XCTAssertEqual(fetchCandidates.map(\.path), [
            "v1/me/preferences",
            "v1/me/settings",
            "v1/users/preferences"
        ])
        XCTAssertEqual(fetchCandidates.map(\.method), ["GET", "GET", "GET"])

        let saveCandidates = PreferenceSyncPlan.saveCandidates()
        XCTAssertEqual(saveCandidates.map(\.path), [
            "v1/me/preferences",
            "v1/me/preferences",
            "v1/me/settings",
            "v1/users/preferences"
        ])
        XCTAssertEqual(saveCandidates.map(\.method), ["PUT", "PATCH", "PATCH", "POST"])
        XCTAssertTrue(saveCandidates.allSatisfy(\.sendsReadBody))
    }

    func testAccountSettingsSummaryPlanCandidates() {
        let candidates = AccountSettingsSummaryPlan.fetchCandidates()
        XCTAssertEqual(candidates.map(\.path), [
            "v1/me/settings-summary",
            "v1/me/profile-summary",
            "v1/me/preferences",
            "v1/me/settings",
            "v1/users/preferences"
        ])
        XCTAssertEqual(candidates.map(\.method), ["GET", "GET", "GET", "GET", "GET"])
    }

    func testAccountProfileSummaryPlanCandidates() {
        let candidates = AccountProfileSummaryPlan.fetchCandidates()
        XCTAssertEqual(candidates.map(\.path), [
            "v1/me/profile-summary",
            "v1/me/settings-summary",
            "v1/me",
            "v1/users/me"
        ])
        XCTAssertEqual(candidates.map(\.method), ["GET", "GET", "GET", "GET"])
    }

    func testAccountProfileMutationPlanCandidates() {
        let candidates = AccountProfileMutationPlan.saveCandidates()
        XCTAssertEqual(candidates.map(\.path), [
            "v1/me/profile-summary",
            "v1/me/profile",
            "v1/me",
            "v1/users/me"
        ])
        XCTAssertEqual(candidates.map(\.method), ["PATCH", "PATCH", "PUT", "POST"])
        XCTAssertTrue(candidates.allSatisfy(\.sendsReadBody))
    }

    func testBookingMutationFallbacks() {
        let candidates = BookingMutationPlan.cancelCandidates(bookingID: "booking-9")
        XCTAssertEqual(candidates.count, 4)
        XCTAssertEqual(candidates.last?.path, "v1/bookings/booking-9/status")
        XCTAssertTrue(BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: 405))
        XCTAssertFalse(BookingMutationPlan.shouldFallbackForUnavailableMutation(statusCode: 422))

        let rescheduleCandidates = BookingMutationPlan.rescheduleCandidates(bookingID: "booking-9")
        XCTAssertEqual(rescheduleCandidates.count, 4)
        XCTAssertEqual(rescheduleCandidates.first?.path, "v1/bookings/booking-9/reschedule")
        XCTAssertEqual(rescheduleCandidates.last?.path, "v1/bookings/booking-9")

        let providerDecisionCandidates = BookingMutationPlan.providerDecisionCandidates(bookingID: "booking-9")
        XCTAssertEqual(providerDecisionCandidates.count, 3)
        XCTAssertEqual(providerDecisionCandidates.first?.path, "v1/bookings/booking-9/status")
        XCTAssertEqual(providerDecisionCandidates.last?.path, "v1/bookings/booking-9")
    }

    func testCheckoutCompletionDetector() {
        XCTAssertEqual(
            CheckoutCompletionDetector.completion(for: URL(string: "https://example.com/return?payment_status=succeeded")!),
            .success
        )
        XCTAssertEqual(
            CheckoutCompletionDetector.completion(for: URL(string: "https://pay.example.com/checkout/cancel")!),
            .cancelled
        )
        XCTAssertNil(CheckoutCompletionDetector.completion(for: URL(string: "https://example.com/checkout/review")!))
    }

    func testChatSocketPayloadParserAndReconnectPlan() {
        XCTAssertEqual(
            ChatSocketPayloadParser.event(from: #"{"event":"typing","conversationId":"chat-1","typing":true}"#),
            .typing(chatID: "chat-1", isTyping: true)
        )
        XCTAssertEqual(
            ChatSocketPayloadParser.event(
                from: #"{"type":"new_message","chat_id":"chat-2","body":"Selam"}"#,
                now: Date(timeIntervalSince1970: 0)
            ),
            .message(
                chatID: "chat-2",
                text: "Selam",
                createdAt: ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: 0))
            )
        )
        XCTAssertNil(ChatSocketPayloadParser.event(from: #"{"type":"typing","chat_id":"chat-3"}"#))

        XCTAssertTrue(
            ChatSocketReconnectPlan.shouldReuseOpenConnection(
                currentToken: "token-1",
                incomingToken: "token-1",
                isConnected: true,
                hasSocket: true
            )
        )
        XCTAssertFalse(
            ChatSocketReconnectPlan.shouldReuseOpenConnection(
                currentToken: "token-1",
                incomingToken: "token-2",
                isConnected: true,
                hasSocket: true
            )
        )
        XCTAssertTrue(ChatSocketReconnectPlan.shouldScheduleReconnect(currentToken: "token-1"))
        XCTAssertFalse(ChatSocketReconnectPlan.shouldScheduleReconnect(currentToken: nil))
        XCTAssertEqual(ChatSocketReconnectPlan.reconnectDelay(forAttempt: 0), 2)
        XCTAssertEqual(ChatSocketReconnectPlan.reconnectDelay(forAttempt: 1), 2)
        XCTAssertEqual(ChatSocketReconnectPlan.reconnectDelay(forAttempt: 2), 4)
        XCTAssertEqual(ChatSocketReconnectPlan.reconnectDelay(forAttempt: 10), 30)
    }

    func testHomeDashboardSnapshotAndBookingPresentation() {
        let bookings = [
            BookingItem(
                id: "booking-2",
                service: "BABYSITTER",
                status: "COMPLETED",
                startTime: "2026-03-22T12:00:00Z",
                endTime: "2026-03-22T13:00:00Z",
                totalPrice: 700,
                address: nil,
                paymentStatus: nil,
                provider: BookingProvider(id: "provider-2", displayName: "Merve", hourlyRate: 700)
            ),
            BookingItem(
                id: "booking-1",
                service: "BABYSITTER",
                status: "CONFIRMED",
                startTime: "2026-03-21T09:00:00Z",
                endTime: "2026-03-21T10:00:00Z",
                totalPrice: 650,
                address: nil,
                paymentStatus: "PAID",
                provider: BookingProvider(id: "provider-1", displayName: "Ayse", hourlyRate: 650)
            )
        ]

        let snapshot = HomeDashboardSnapshot.make(
            bookings: bookings,
            favoritesResponse: FavoritesResponse(favorites: [
                FavoriteItem(providerId: "provider-2", displayName: "Merve", rating: 4.7),
                FavoriteItem(providerId: "provider-1", displayName: "Ayse", rating: 4.9)
            ]),
            notificationsResponse: NotificationsResponse(notifications: [
                makeNotification(title: "Okunmamis", body: "Yeni mesaj", read: false),
                makeNotification(title: "Okundu", body: "Eski guncelleme", read: true)
            ]),
            conversationsResponse: ConversationsResponse(conversations: [
                ConversationItem(
                    id: "chat-1",
                    participantID: "provider-1",
                    participantName: "Ayse",
                    lastMessage: "Merhaba",
                    lastMessageAt: "2026-03-21T10:00:00Z",
                    unreadCount: 0
                )
            ])
        )

        XCTAssertEqual(snapshot.bookings.map(\.id), ["booking-1", "booking-2"])
        XCTAssertEqual(snapshot.favorites.map(\.providerId), ["provider-1", "provider-2"])
        XCTAssertEqual(snapshot.activeBookings.count, 1)
        XCTAssertEqual(snapshot.completedBookings.count, 1)
        XCTAssertEqual(snapshot.unreadNotifications, 1)

        let confirmed = BookingStatusPresentation.make(for: "CONFIRMED")
        XCTAssertEqual(confirmed.localizedStatus, "Onaylandi")
        XCTAssertEqual(confirmed.paymentLabel, "Hazir")
        XCTAssertTrue(confirmed.canPay)
        XCTAssertFalse(confirmed.canRebook)

        let cancelled = BookingStatusPresentation.make(for: "CANCELED")
        XCTAssertEqual(cancelled.localizedStatus, "Iptal Edildi")
        XCTAssertEqual(cancelled.paymentSummaryText, "Odeme kapatildi")
        XCTAssertTrue(cancelled.canRebook)
        XCTAssertFalse(cancelled.canCancel)

        let presentation = BookingStatusPresentation.make(for: "CONFIRMED", paymentStatus: "PAID")
        XCTAssertEqual(presentation.paymentLabel, "Tamamlandi")
        XCTAssertEqual(presentation.paymentSummaryText, "Odeme tamamlandi")
        XCTAssertFalse(presentation.canRebook)

        let inProgress = BookingStatusPresentation.make(for: "IN_PROGRESS")
        XCTAssertEqual(inProgress.localizedStatus, "Devam Ediyor")
        XCTAssertEqual(inProgress.paymentLabel, "Aktif")
        XCTAssertFalse(inProgress.canCancel)
    }
}
