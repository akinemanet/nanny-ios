//
//  BookingListView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BookingListView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50)

                        VStack(alignment: .leading) {
                            Text("Sophia")
                                .font(.headline)

                            Text("Tomorrow 09:00")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("Confirmed")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Bookings")
        }
    }
}
