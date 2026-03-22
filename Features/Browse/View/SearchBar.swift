//
//  SearchBar.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct SearchBar: View {
    @State private var text = ""

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField("Search nanny", text: $text)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
