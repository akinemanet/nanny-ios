//
//  NannyProfileView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct NannyProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore
    @AppStorage(StoredLocationKeys.latitude) private var selectedLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var selectedLongitude = StoredLocation.fallback.longitude
    let provider: BrowseProvider
    @State private var detail: ProviderDetail?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isFavorite = false
    @State private var showCalendar = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                    }

                    Spacer()

                    Text("Profil")
                        .font(.title2.bold())
                        .foregroundStyle(DS.Colors.textPrimary)

                    Spacer()

                    Color.clear
                        .frame(width: 44, height: 44)
                }

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.primary.opacity(0.95), DS.Colors.accent.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 260)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(profileAvatarGradient)
                                .frame(width: 72, height: 72)
                                .overlay {
                                    Text(profileInitials)
                                        .font(.title.bold())
                                        .foregroundStyle(.white)
                                }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(detail?.displayName ?? provider.displayName)
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.white)
                                Text("\(detail?.locationName ?? provider.locationName) • \(resolvedDistanceText)")
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(20)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                HStack {
                    profileStat(String(format: "%.1f", detail?.rating ?? provider.rating), "Puan")
                    profileStat("\(detail?.reviews.count ?? 0)", "Yorum")
                    profileStat("\(detail?.age ?? 24)", "Yaş")
                }

                HStack(spacing: 12) {
                    infoCard(title: "Saatlik Ücret", value: "₺\(detail?.hourlyRate ?? provider.hourlyRate) / saat")
                    infoCard(title: "Tamamlanan", value: "\(detail?.completedSittings ?? 37) oturum")
                }

                if let educationLevel = detail?.educationLevel, !educationLevel.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eğitim Durumu")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text(educationLevel)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Deneyim")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("Yenidoğan ve \(detail?.age ?? 12) yaşına kadar çocuklarla deneyim")
                        .foregroundStyle(DS.Colors.textSecondary)

                    HStack {
                        Image(systemName: "figure.and.child.holdinghands")
                        Image(systemName: "fork.knife")
                        Image(systemName: "cross.case")
                        Image(systemName: "book")
                        Image(systemName: "pills")
                    }
                    .font(.title3)
                    .foregroundStyle(DS.Colors.accent)
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Açıklama")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(detail?.about ?? "6 aylıktan 12 yaşa kadar çocuklarla 7 yıllık bakım deneyimim var. Çocuklarla vakit geçirmeyi, onları tanımayı ve güven ilişkisi kurmayı seviyorum.")
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Takvim")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Spacer()
                        Button("Tümünü Gör") {
                            showCalendar = true
                        }
                        .foregroundStyle(.orange)
                    }

                    HStack {
                        ForEach(detail?.availability.prefix(3) ?? []) { item in
                            scheduleChip(formattedDate(item.date), availabilityStatusText(item.status))
                        }
                    }
                }

                HStack(spacing: 8) {
                    ForEach(detail?.skills ?? ["İlk Yardım", "Yemek", "Ödev Desteği"], id: \.self) { skill in
                        SkillPill(title: skill)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Yorumlar")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Spacer()
                        Button {
                            Task { await toggleFavorite() }
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorite ? .pink : .secondary)
                        }
                    }
                    ForEach(detail?.reviews ?? []) { review in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(review.authorName)
                                .font(.subheadline.bold())
                                .foregroundStyle(DS.Colors.textPrimary)
                            Text(review.comment)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }

                NavigationLink {
                    BookingCalendarView(provider: provider)
                } label: {
                    Text("Şimdi Rezervasyon Yap")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 92)
        }
        .navigationDestination(isPresented: $showCalendar) {
            BookingCalendarView(provider: provider)
        }
        .task {
            await loadDetail()
            await loadFavorites()
        }
    }

    private func profileStat(_ value: String, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(DS.Colors.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.orange)
            Text(value)
                .font(.headline)
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var resolvedDistanceText: String {
        StoredLocation.distanceText(
            from: selectedLatitude,
            originLongitude: selectedLongitude,
            to: detail?.latitude ?? provider.latitude,
            destinationLongitude: detail?.longitude ?? provider.longitude,
            fallback: detail?.distanceText ?? provider.distanceText
        )
    }

    private func scheduleChip(_ day: String, _ state: String) -> some View {
        VStack(spacing: 4) {
            Text(day)
                .font(.caption.bold())
                .foregroundStyle(DS.Colors.primary)
            Text(state)
                .font(.caption2)
                .foregroundStyle(DS.Colors.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(state == "Rezerve" ? Color.gray.opacity(0.15) : DS.Colors.primary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadDetail() async {
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await session.deps.providerService.getProviderDetail(id: provider.id).provider
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadFavorites() async {
        do {
            let favorites = try await session.deps.providerService.listFavorites().favorites
            isFavorite = favorites.contains { $0.providerId == provider.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleFavorite() async {
        do {
            if isFavorite {
                try await session.deps.providerService.removeFavorite(providerID: provider.id)
                isFavorite = false
            } else {
                try await session.deps.providerService.addFavorite(providerID: provider.id)
                isFavorite = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func formattedDate(_ value: String) -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        if let date = input.date(from: value) {
            return out.string(from: date)
        }
        return value
    }

    private func availabilityStatusText(_ value: String) -> String {
        switch value.uppercased() {
        case "AVAILABLE":
            return "Müsait"
        case "BOOKED":
            return "Rezerve"
        default:
            return value
        }
    }

    private var profileInitials: String {
        let name = detail?.displayName ?? provider.displayName
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    private var profileAvatarGradient: LinearGradient {
        let gradients: [[Color]] = [
            [Color(red: 0.20, green: 0.54, blue: 0.90), Color(red: 0.49, green: 0.74, blue: 0.98)],
            [Color(red: 0.98, green: 0.56, blue: 0.18), Color(red: 0.96, green: 0.74, blue: 0.34)],
            [Color(red: 0.33, green: 0.68, blue: 0.50), Color(red: 0.58, green: 0.83, blue: 0.66)],
            [Color(red: 0.56, green: 0.42, blue: 0.88), Color(red: 0.77, green: 0.63, blue: 0.95)]
        ]
        let name = detail?.displayName ?? provider.displayName
        let index = abs(name.hashValue) % gradients.count
        return LinearGradient(colors: gradients[index], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
