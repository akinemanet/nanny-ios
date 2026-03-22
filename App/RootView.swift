//
//  RootView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import UIKit
import UserNotifications

struct RootView: View {
    @EnvironmentObject private var session: SessionStore
    @Binding var didSeeOnboarding: Bool
    @AppStorage("didSetLocation") private var didSetLocation = false
    @AppStorage("didHandlePushPrompt") private var didHandlePushPrompt = false
    @AppStorage(StoredLocationKeys.name) private var selectedLocationName = StoredLocation.fallback.name
    @AppStorage(StoredLocationKeys.latitude) private var selectedLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var selectedLongitude = StoredLocation.fallback.longitude
    @State private var showSplash = true
    @State private var showManualLocationPicker = false

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if !didSeeOnboarding {
                OnboardingPagerView {
                    didSeeOnboarding = true
                }
            } else if !didHandlePushPrompt {
                PushPermissionIntroView(
                    onAllow: {
                        requestPushPermission()
                    },
                    onSkip: {
                        didHandlePushPrompt = true
                    }
                )
            } else if session.isBootstrapping {
                ProgressView("Yükleniyor...")
            } else if !session.isLoggedIn {
                AuthFlowView()
            } else if session.me?.user.role == "PROVIDER" {
                ProviderRootView(service: session.deps.providerService)
            } else if !didSetLocation {
                LocationIntroView(
                    onUseCurrentLocation: {
                        let location = StoredLocation.fallback
                        selectedLocationName = location.name
                        selectedLatitude = location.latitude
                        selectedLongitude = location.longitude
                        didSetLocation = true
                    },
                    onSetLocationManually: {
                        showManualLocationPicker = true
                    }
                )
            } else {
                MainTabView()
            }
        }
        .fullScreenCover(isPresented: $showManualLocationPicker) {
            NavigationStack {
                MapSearchView(
                    isSelectingLocation: true,
                    onLocationSelected: { location in
                        selectedLocationName = location.name
                        selectedLatitude = location.latitude
                        selectedLongitude = location.longitude
                        didSetLocation = true
                        showManualLocationPicker = false
                    }
                )
            }
        }
        .task {
            if showSplash {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                showSplash = false
                await session.bootstrap()
            }
        }
    }

    private func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            didHandlePushPrompt = true
            _ = error

            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

private struct ProviderRootView: View {
    let service: ProviderService

    @State private var isLoading = true
    @State private var account: ProviderAccount?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Provider paneli yükleniyor...")
                } else if let account, account.status.uppercased() == "APPROVED" {
                    ProviderDashboardView(account: account)
                } else {
                    ProviderOnboardingView(service: service)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            account = try await service.getPayoutAccount().account
            errorMessage = nil
        } catch {
            account = nil
            errorMessage = error.localizedDescription
        }
    }
}

private struct PushPermissionIntroView: View {
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DS.Colors.primary.opacity(0.14), DS.Colors.accent.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DS.Colors.accent)
            }

            VStack(spacing: 12) {
                Text("Bildirimleri Ac")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.textPrimary)

                Text("Rezervasyon onaylari, yeni mesajlar ve odeme hatirlatmalari icin sana zamaninda haber verelim.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.horizontal, 12)
            }

            VStack(alignment: .leading, spacing: 12) {
                permissionRow(
                    systemImage: "message.badge",
                    title: "Yeni mesajlar",
                    subtitle: "Bakici veya aile sana yazdiginda aninda gor."
                )
                permissionRow(
                    systemImage: "calendar.badge.clock",
                    title: "Rezervasyon guncellemeleri",
                    subtitle: "Onay, iptal ve saat degisikliklerini kacirma."
                )
                permissionRow(
                    systemImage: "creditcard.and.123",
                    title: "Odeme adimlari",
                    subtitle: "Bekleyen odeme ve checkout akisini zamaninda tamamla."
                )
            }
            .padding(20)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(DS.Colors.border, lineWidth: 1)
            }

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton("Bildirimleri Ac") {
                    onAllow()
                }

                Button("Simdilik Gec") {
                    onSkip()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colors.textSecondary)
            }
        }
        .padding(24)
        .background(DS.Colors.background.ignoresSafeArea())
    }

    private func permissionRow(systemImage: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(DS.Colors.primary.opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: systemImage)
                        .foregroundStyle(DS.Colors.primary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DS.Colors.textSecondary)
            }

            Spacer()
        }
    }
}
