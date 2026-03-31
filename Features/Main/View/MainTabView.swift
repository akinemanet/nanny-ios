//
//  MainTabView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }

            BrowseView()
                .tabItem {
                    Label("Keşfet", systemImage: "magnifyingglass")
                }

            BookingListView()
                .tabItem {
                    Label("Rezervasyonlar", systemImage: "calendar")
                }

            if let messageBadgeValue {
                ChatListView()
                    .tabItem {
                        Label("Bağlan", systemImage: "message")
                    }
                    .badge(messageBadgeValue)
            } else {
                ChatListView()
                    .tabItem {
                        Label("Bağlan", systemImage: "message")
                    }
            }

            AccountView()
                .tabItem {
                    Label("Hesap", systemImage: "person")
                }
        }
        .tint(DS.Colors.primary)
        .toolbarBackground(.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
        .task {
            await session.refreshInboxState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await session.refreshInboxState()
            }
        }
    }
    private var messageBadgeValue: Int? {
        session.unreadMessageCount > 0 ? session.unreadMessageCount : nil
    }
}
