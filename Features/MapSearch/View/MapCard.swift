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
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 180, height: 110)

            Text("Nearby Nanny")
                .font(.headline)

            Text("$\(nanny.price) / hr")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 4)
    }
}
