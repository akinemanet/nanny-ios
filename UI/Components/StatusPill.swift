//
//  StatusPill.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

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
        let style = style
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: style.systemImage)
                Text(style.title).font(.headline)
            }
            .foregroundStyle(style.color)

            Text(style.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
