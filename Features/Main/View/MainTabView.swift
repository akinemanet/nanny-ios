//
//  MainAppView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct MainAppView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Browse", systemImage: "house")
                }

            MapSearchView()
                .tabItem {
                    Label("Map Search", systemImage: "map")
                }

            BookingsView()
                .tabItem {
                    Label("Booking", systemImage: "calendar")
                }

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}
