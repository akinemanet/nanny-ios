//
//  ProviderCalendarView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct ProviderCalendarView: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            DatePicker(
                "Availability",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)

            Spacer()
        }
        .padding()
        .navigationTitle("Availability")
    }
}
