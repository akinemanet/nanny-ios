//
//  TimeSlotView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct TimeSlotView: View {
    let time: String

    @State private var selected = false

    var body: some View {
        Text(time)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(selected ? .blue : .gray.opacity(0.2))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                selected.toggle()
            }
    }
}
