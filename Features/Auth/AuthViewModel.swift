//
//  AuthViewModel.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum Step {
        case enterPhone
        case enterCode
    }

    @Published var role: UserRole = .parent
    @Published var phone: String = ""
    @Published var code: String = ""
    @Published var step: Step = .enterPhone

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var devCode: String?

    private var session: SessionStore?

    init(session: SessionStore?) {
        self.session = session
    }

    static func placeholder() -> AuthViewModel {
        AuthViewModel(session: nil)
    }

    func attachIfNeeded(session: SessionStore) {
        if self.session == nil {
            self.session = session
        }
    }

    func requestOTP() async {
        guard let session = session else { return }
        errorMessage = nil
        devCode = nil

        isLoading = true
        defer { isLoading = false }

        do {
            let res = try await session.deps.auth.requestOTP(phone: phone)
            devCode = res.devCode
            step = .enterCode
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verifyOTP() async -> Bool {
        guard let session = session else { return false }
        errorMessage = nil

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await session.deps.auth.verifyOTP(phone: phone, code: code, role: role)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func backToPhone() {
        errorMessage = nil
        code = ""
        step = .enterPhone
    }
}
