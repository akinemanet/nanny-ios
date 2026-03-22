//
//  ChatConversationView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct ChatConversationView: View {
    @State private var message = ""
    @State private var messages: [ConversationBubble] = [
        .init(id: "1", text: "Merhaba, yarın 09:00'dan sonra müsaitim.", isIncoming: true),
        .init(id: "2", text: "Harika, 3 saatlik rezervasyonu netleştirebilir miyiz?", isIncoming: false),
        .init(id: "3", text: "Evet, benim için uygundur.", isIncoming: true)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(messages) { item in
                        ChatBubble(text: item.text, isMine: !item.isIncoming)
                    }
                }
                .padding(24)
            }

            HStack(spacing: 12) {
                AppTextField(placeholder: "Mesaj yaz", text: $message)
                PrimaryButton("Gönder") {
                    send()
                }
                    .frame(width: 110)
            }
            .padding(16)
            .background(DS.Colors.surface)
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Konuşma")
    }

    private func send() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(.init(id: UUID().uuidString, text: trimmed, isIncoming: false))
        message = ""
    }
}

private struct ConversationBubble: Identifiable {
    let id: String
    let text: String
    let isIncoming: Bool
}
