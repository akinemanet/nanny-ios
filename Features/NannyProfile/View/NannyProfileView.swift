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
                            profileAvatarView

                            VStack(alignment: .leading, spacing: 8) {
                                Text(detail?.displayName ?? provider.displayName)
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.white)
                                Text("\(resolvedLocationName) • \(resolvedDistanceText)")
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
                    if reviewCountValue > 0 && ratingValue > 0 {
                        profileStat(String(format: "%.1f", ratingValue), "Puan")
                        profileStat("\(reviewCountValue)", "Yorum")
                    }
                    profileStat(ageDisplayText, "Yaş")
                }

                if !trustBadges.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Güven Göstergeleri")
                            .font(.headline)
                            .foregroundStyle(DS.Colors.textPrimary)

                        trustBadgeFlow
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                HStack(spacing: 12) {
                    infoCard(title: "Saatlik Ücret", value: "₺\(detail?.hourlyRate ?? provider.hourlyRate) / saat")
                    infoCard(title: "Tamamlanan", value: completedSittingsText)
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
                    Text(experienceText)
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

                if !resolvedSkills.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(resolvedSkills, id: \.self) { skill in
                            SkillPill(title: skill)
                        }
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
            fallback: sanitizedDistanceText(detail?.distanceText ?? provider.distanceText)
        )
    }

    private var resolvedLocationName: String {
        sanitizedLocationName(detail?.locationName ?? provider.locationName)
    }

    private var ageDisplayText: String {
        let age = detail?.age ?? provider.age
        return age > 0 ? "\(age)" : "-"
    }

    private var completedSittingsText: String {
        let count = detail?.completedSittings ?? provider.completedSittings
        return count > 0 ? "\(count) oturum" : "-"
    }

    private var ratingValue: Double {
        detail?.rating ?? provider.rating
    }

    private var reviewCountValue: Int {
        detail?.reviews.count ?? provider.reviewCount
    }

    private var resolvedSkills: [String] {
        let skills = detail?.skills ?? provider.categories
        return skills.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var experienceText: String {
        let trimmed = detail?.experience.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }
        return "Bakıcı henüz deneyim bilgisini eklemedi."
    }

    private var trustBadges: [ProfileTrustBadge] {
        var badges: [ProfileTrustBadge] = []

        if isVerifiedProfile {
            badges.append(ProfileTrustBadge(
                title: "Onaylı Profil",
                detail: "Profil bilgileri tamamlandı",
                systemImage: "checkmark.shield.fill",
                tint: .green
            ))
        }

        if ratingValue >= 4.7, reviewCountValue >= 3 {
            badges.append(ProfileTrustBadge(
                title: "Yüksek Memnuniyet",
                detail: "\(reviewCountValue) yorumla güçlü puan",
                systemImage: "star.fill",
                tint: .orange
            ))
        }

        if completedSittingsCount >= 10 {
            badges.append(ProfileTrustBadge(
                title: "Tecrübeli",
                detail: "\(completedSittingsCount) tamamlanan iş",
                systemImage: "figure.2.and.child.holdinghands",
                tint: DS.Colors.primary
            ))
        }

        if !(detail?.availability ?? []).isEmpty {
            badges.append(ProfileTrustBadge(
                title: "Takvimi Güncel",
                detail: "Uygun günlerini paylaşmış",
                systemImage: "calendar.badge.checkmark",
                tint: .indigo
            ))
        }

        if resolvedSkills.count >= 2 {
            badges.append(ProfileTrustBadge(
                title: "Çok Yönlü Destek",
                detail: "\(resolvedSkills.count) hizmet alanı",
                systemImage: "sparkles",
                tint: DS.Colors.accent
            ))
        }

        return badges
    }

    private var trustBadgeFlow: some View {
        VStack(spacing: 10) {
            ForEach(Array(trustBadges.chunked(into: 2).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row) { badge in
                        trustBadgeCard(badge)
                    }
                    if row.count == 1 {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
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

    private func trustBadgeCard(_ badge: ProfileTrustBadge) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(badge.tint.opacity(0.14))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: badge.systemImage)
                        .font(.subheadline.bold())
                        .foregroundStyle(badge.tint)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(badge.detail)
                    .font(.caption)
                    .foregroundStyle(DS.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(DS.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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

    @ViewBuilder
    private var profileAvatarView: some View {
        if let photoURL = detail?.photoURL ?? provider.photoURL, let url = URL(string: photoURL) {
            RemoteImageView(url: url) {
                profileAvatarPlaceholder
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
        } else {
            profileAvatarPlaceholder
        }
    }

    private var profileAvatarPlaceholder: some View {
        Circle()
            .fill(profileAvatarGradient)
            .frame(width: 72, height: 72)
            .overlay {
                Text(profileInitials)
                    .font(.title.bold())
                    .foregroundStyle(.white)
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

    private func sanitizedLocationName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return provider.locationName }
        let lowered = trimmed.lowercased()
        if lowered.contains("san francisco") || lowered.contains("california") {
            return provider.locationName
        }
        return trimmed
    }

    private func sanitizedDistanceText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Mesafe bilgisi yakinda" }
        let lowered = trimmed.lowercased()
        if lowered.contains("mi away") || lowered.contains("miles away") {
            return "Mesafe bilgisi yakinda"
        }
        return trimmed
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

    private var completedSittingsCount: Int {
        detail?.completedSittings ?? provider.completedSittings
    }

    private var isVerifiedProfile: Bool {
        let status = (detail?.payoutStatus ?? provider.payoutStatus).uppercased()
        return status == "APPROVED" || status == "ACTIVE"
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

private struct ProfileTrustBadge: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
