//
//  NannyCard.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct NannyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 180)

            Text("Sophia")
                .font(.title3.bold())

            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)

                Text("4.8")

                Spacer()

                Text("$15 / hr")
                    .font(.headline)
            }

            Text("5 years experience")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 4)
    }
}
