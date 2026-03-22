//
//  ChatBubble.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct ChatBubble: View {
    let text: String
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer() }

            Text(text)
                .padding()
                .background(isMine ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(isMine ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if !isMine { Spacer() }
        }
    }
}
