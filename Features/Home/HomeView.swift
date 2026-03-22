//
//  HomeView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Parent Home")
                    .font(.title.bold())

                Button("Çıkış") {
                    session.logout()
                }
            }
            .padding()
        }
    }
}
