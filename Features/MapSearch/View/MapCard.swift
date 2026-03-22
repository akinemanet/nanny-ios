//
//  MapCard.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct MapCard: View {
    let nanny: NannyLocation

    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 120)

            Text("Sofya")
                .font(.headline)

            Text("\(nanny.price) $/saat")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 3)
    }
}
