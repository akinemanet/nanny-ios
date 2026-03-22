//
//  BrowseView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage(StoredLocationKeys.name) private var selectedLocationName = StoredLocation.fallback.name
    @AppStorage(StoredLocationKeys.latitude) private var selectedLatitude = StoredLocation.fallback.latitude
    @AppStorage(StoredLocationKeys.longitude) private var selectedLongitude = StoredLocation.fallback.longitude
    @State private var providers: [BrowseProvider] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCategory = "Bebek"
    @State private var searchText = ""
    @State private var showFilter = false
    @State private var showMap = false
    @State private var showSearch = false
    @State private var showDiscover = false
    @State private var showCategories = false
    @State private var filters = BrowseFilters.default
    @State private var discoverCriteria = DiscoverCriteria.default

    private var filteredProviders: [BrowseProvider] {
        var result = providers.filter(matchesSearch)
        result = result.filter(matchesExperience)
        result = result.filter(matchesGender)
        result = result.filter(matchesRating)
        result = result.filter(matchesPrice)
        result = result.filter(matchesNearby)
        result = result.filter(matchesDiscoverLocation)
        result = result.filter(matchesDiscoverCategory)
        result = result.filter(matchesDiscoverGender)
        result = result.filter(matchesDiscoverDate)
        result = result.filter(matchesDiscoverTime)
        return result.sorted(by: sortComparator)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    heroCard
                    controlsRow

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let errorMessage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(errorMessage)
                                .foregroundStyle(.red)

                            Button("Tekrar Dene") {
                                Task {
                                    await loadProviders()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else if providers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bakıcı bulunamadı.")
                                .foregroundStyle(.secondary)

                            Button("Yenile") {
                                Task {
                                    await loadProviders()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(filteredProviders) { provider in
                            NavigationLink {
                                NannyProfileView(provider: provider)
                            } label: {
                                NannyCard(provider: providerWithCalculatedDistance(provider))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(DS.Colors.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilter) {
                BrowseFilterSheet(filters: $filters)
            }
            .navigationDestination(isPresented: $showMap) {
                MapSearchView(isSelectingLocation: true)
            }
            .navigationDestination(isPresented: $showSearch) {
                BrowseSearchView(providers: providers)
            }
            .navigationDestination(isPresented: $showDiscover) {
                DiscoverBrowseView(
                    providers: providers,
                    resultCount: filteredProviders.count,
                    criteria: $discoverCriteria
                )
            }
            .navigationDestination(isPresented: $showCategories) {
                CategoriesBrowseView(selectedCategory: $selectedCategory)
            }
            .task {
                guard providers.isEmpty else { return }
                await loadProviders()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Konumun")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                    Label(selectedLocationName, systemImage: "mappin.circle.fill")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                Spacer()
                Button {
                    showMap = true
                } label: {
                    Image(systemName: "map")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
                }
            }
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 205)

            VStack(spacing: 14) {
                Text("Bakıcı bul")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Çocuğun için güvenilir bir bakıcı keşfet")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                Button {
                    showDiscover = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Bakıcıları keşfet")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(DS.Colors.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 30)
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 0) {
            Button {
                showMap = true
            } label: {
                controlButtonLabel(title: "Harita", systemImage: "map")
            }

            Divider()

            Button {
                showFilter = true
            } label: {
                controlButtonLabel(title: "Filtre", systemImage: "line.3.horizontal.decrease")
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func loadProviders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            providers = try await session.deps.providerService.listProviders().providers
            errorMessage = nil
        } catch {
            errorMessage = "Bakıcılar yüklenemedi."
        }
    }

    private func controlButtonLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
            Text(title)
                .font(.headline.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(DS.Colors.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    private func matchesSearch(_ provider: BrowseProvider) -> Bool {
        guard !searchText.isEmpty else { return true }
        let haystack = [
            provider.displayName,
            provider.locationName,
            provider.categories.joined(separator: " ")
        ].joined(separator: " ")
        return haystack.localizedCaseInsensitiveContains(searchText)
    }

    private func matchesExperience(_ provider: BrowseProvider) -> Bool {
        guard let experience = filters.experienceSelection else { return true }
        return provider.categories.contains { $0.localizedCaseInsensitiveContains(experience) }
    }

    private func matchesGender(_ provider: BrowseProvider) -> Bool {
        guard filters.genderSelection != "Tümü" else { return true }
        return provider.gender == filters.genderSelection
    }

    private func matchesRating(_ provider: BrowseProvider) -> Bool {
        provider.rating >= Double(filters.ratingSelection)
    }

    private func matchesPrice(_ provider: BrowseProvider) -> Bool {
        Double(provider.hourlyRate) <= filters.maxPrice
    }

    private func matchesNearby(_ provider: BrowseProvider) -> Bool {
        guard filters.showNearby else { return true }
        return computedDistance(for: provider) <= 3.5
    }

    private func matchesDiscoverLocation(_ provider: BrowseProvider) -> Bool {
        guard discoverCriteria.hasSelectedLocation, !discoverCriteria.location.isEmpty else { return true }
        return provider.locationName == discoverCriteria.location
    }

    private func matchesDiscoverCategory(_ provider: BrowseProvider) -> Bool {
        guard discoverCriteria.hasSelectedCategory, !discoverCriteria.category.isEmpty else { return true }
        return provider.categories.contains { $0.localizedCaseInsensitiveContains(discoverCriteria.category) }
    }

    private func matchesDiscoverGender(_ provider: BrowseProvider) -> Bool {
        guard discoverCriteria.hasSelectedGender, discoverCriteria.gender != "Farketmez" else { return true }
        return provider.gender == discoverCriteria.gender
    }

    private func matchesDiscoverDate(_ provider: BrowseProvider) -> Bool {
        guard discoverCriteria.hasSelectedDate else { return true }
        let selectedDate = discoverDateString
        guard !selectedDate.isEmpty else { return true }
        return provider.availableDates.contains(selectedDate)
    }

    private func matchesDiscoverTime(_ provider: BrowseProvider) -> Bool {
        guard discoverCriteria.hasSelectedTime else { return true }
        let selectedHour = Calendar.current.component(.hour, from: discoverCriteria.time)
        return selectedHour >= provider.availableStartHour && selectedHour < provider.availableEndHour
    }

    private var sortComparator: (BrowseProvider, BrowseProvider) -> Bool {
        switch filters.sortSelection {
        case "En Yüksek Puan":
            return { lhs, rhs in lhs.rating > rhs.rating }
        case "En Düşük Puan":
            return { lhs, rhs in lhs.rating < rhs.rating }
        case "En Çok Değerlendirilen", "En Çok Yorumlanan":
            return { lhs, rhs in lhs.reviewCount > rhs.reviewCount }
        case "En Düşük Fiyat":
            return { lhs, rhs in lhs.hourlyRate < rhs.hourlyRate }
        case "En Yüksek Fiyat":
            return { lhs, rhs in lhs.hourlyRate > rhs.hourlyRate }
        case "Popülerlik":
            return { lhs, rhs in lhs.completedSittings > rhs.completedSittings }
        default:
            return { lhs, rhs in computedDistance(for: lhs) < computedDistance(for: rhs) }
        }
    }

    private func computedDistance(for provider: BrowseProvider) -> Double {
        guard let latitude = provider.latitude, let longitude = provider.longitude else {
            return fallbackDistanceValue(for: provider.distanceText)
        }
        return StoredLocation.distanceInKilometers(
            from: selectedLatitude,
            originLongitude: selectedLongitude,
            to: latitude,
            destinationLongitude: longitude
        ) ?? fallbackDistanceValue(for: provider.distanceText)
    }

    private func providerWithCalculatedDistance(_ provider: BrowseProvider) -> BrowseProvider {
        let calculatedDistance = computedDistance(for: provider)
        let formattedDistance: String
        if calculatedDistance.isFinite {
            formattedDistance = String(format: "%.1f km uzaklikta", calculatedDistance)
        } else {
            formattedDistance = provider.distanceText
        }

        return BrowseProvider(
            id: provider.id,
            displayName: provider.displayName,
            rating: provider.rating,
            hourlyRate: provider.hourlyRate,
            payoutStatus: provider.payoutStatus,
            age: provider.age,
            gender: provider.gender,
            locationName: provider.locationName,
            distanceText: formattedDistance,
            latitude: provider.latitude,
            longitude: provider.longitude,
            categories: provider.categories,
            reviewCount: provider.reviewCount,
            completedSittings: provider.completedSittings,
            availableDates: provider.availableDates,
            availableStartHour: provider.availableStartHour,
            availableEndHour: provider.availableEndHour
        )
    }

    private func fallbackDistanceValue(for text: String) -> Double {
        let normalized = text
            .replacingOccurrences(of: " km uzaklıkta", with: "")
            .replacingOccurrences(of: " km uzaklikta", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? .greatestFiniteMagnitude
    }

    private var discoverDateString: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: discoverCriteria.date)
    }
}
