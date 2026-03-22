//
//  AppDependencies.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation

struct AppDependencies {
    let api: APIClient
    let auth: AuthService
    let tokenStore: TokenStore
    let bookingService: BookingService
    let chatService: ChatService
    let notificationService: NotificationService
    let paymentService: PaymentService
    let providerService: ProviderService

    static func live() -> AppDependencies {
        let tokenStore = KeychainTokenStore()
        let api = APIClient(tokenStore: tokenStore)
        let auth = AuthService(api: api, tokenStore: tokenStore)
        let bookingService = BookingService(api: api)
        let chatService = ChatService(api: api)
        let notificationService = NotificationService(api: api)
        let paymentService = PaymentService(api: api)
        let providerService = ProviderService(api: api)

        return AppDependencies(
            api: api,
            auth: auth,
            tokenStore: tokenStore,
            bookingService: bookingService,
            chatService: chatService,
            notificationService: notificationService,
            paymentService: paymentService,
            providerService: providerService
        )
    }
}
