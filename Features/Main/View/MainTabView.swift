//
//  MainTabView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct MainTabView: View {
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

            ChatListView()
                .tabItem {
                    Label("Bağlan", systemImage: "message")
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
    }
}
