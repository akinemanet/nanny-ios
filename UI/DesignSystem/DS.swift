//
//  ProviderUIComponents.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI
import UIKit

struct StatusPill: View {
    let status: String

    private var style: (title: String, systemImage: String, color: Color, detail: String) {
        switch status.uppercased() {
        case "APPROVED":
            return ("Onaylandı", "checkmark.seal.fill", .green,
                    "Ödeme alma ve payout hesabı aktif.")
        case "FAILED":
            return ("Hata", "xmark.octagon.fill", .red,
                    "Onboarding başarısız. Hata detayını kontrol et.")
        case "PENDING":
            return ("Beklemede", "clock.fill", .orange,
                    "Bilgiler kaydedildi. Iyzico tarafı onayı bekleniyor veya anahtarlar eksik.")
        default:
            return (status, "info.circle.fill", .blue,
                    "Durum bilgisi mevcut.")
        }
    }

    var body: some View {
        let s = style
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: s.systemImage)
                Text(s.title).font(.headline)
            }
            .foregroundStyle(s.color)

            Text(s.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct CopyRow: View {
    let title: String
    let value: String

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 10) {
                Text(value)
                    .font(.subheadline)
                    .textSelection(.enabled)
                    .lineLimit(3)

                Spacer()

                Button {
                    UIPasteboard.general.string = value
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Kopyala")
            }
        }
    }
}
