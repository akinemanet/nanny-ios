//
//  CategoryRow.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct CategoryRow: View {
    let categories = [
        "Babysitter",
        "Tutor",
        "Pet Care",
        "House"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories, id: \.self) { cat in
                    Text(cat)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
