//
//  NotificationView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct NotificationView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Rezervasyon onaylandı")
                Text("Yeni bakıcı uygun")
                Text("Yarın için hatırlatma")
            }
            .navigationTitle("Bildirimler")
        }
    }
}
