//
//  TimeSlotView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct TimeSlotView: View {
    let time: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(time)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(isSelected ? .blue : .gray.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture(perform: onTap)
    }
}
