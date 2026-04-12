//
//  ProviderCalendarView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

private enum ProviderAvailabilityStorageKeys {
    static let selections = "providerAvailabilitySelections"
    static let weeklyTemplates = "providerAvailabilityWeeklyTemplates"
    static let focusedDate = "providerAvailabilityFocusedDate"
}

private final class ProviderAvailabilityService {
    private struct Empty: Encodable {}
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchSelections() async throws -> [String: [String]]? {
        var lastError: Error?

        for candidate in ProviderAvailabilitySyncPlan.fetchCandidates() {
            do {
                let response: ProviderAvailabilityEnvelope = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: Optional<Empty>.none,
                    needsAuth: true
                )
                return response.selections
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        if let lastError { throw lastError }
        return nil
    }

    func saveSelections(_ selections: [String: [String]]) async throws {
        var lastError: Error?
        let body = ProviderAvailabilityMutationRequest(selections: selections)

        for candidate in ProviderAvailabilitySyncPlan.saveCandidates() {
            do {
                let _: ProviderAvailabilityMutationResponse = try await api.request(
                    candidate.path,
                    method: candidate.method,
                    body: body,
                    needsAuth: true
                )
                return
            } catch let error as APIError {
                switch error {
                case .http(let code, _):
                    if code == 404 || code == 405 {
                        lastError = error
                        continue
                    }
                    throw error
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }

        throw lastError ?? APIError.invalidURL
    }
}

private struct ProviderAvailabilityEnvelope: Decodable {
    let selections: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case availability
        case selections
        case slots
    }

    init(from decoder: Decoder) throws {
        if let raw = try? ProviderAvailabilityPayload(from: decoder) {
            selections = raw.normalizedSelections
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let nested = try container.decodeIfPresent(ProviderAvailabilityPayload.self, forKey: .availability) {
            selections = nested.normalizedSelections
            return
        }
        if let nested = try container.decodeIfPresent(ProviderAvailabilityPayload.self, forKey: .selections) {
            selections = nested.normalizedSelections
            return
        }
        if let nested = try container.decodeIfPresent(ProviderAvailabilityPayload.self, forKey: .slots) {
            selections = nested.normalizedSelections
            return
        }

        selections = [:]
    }
}

private struct ProviderAvailabilityPayload: Decodable {
    let map: [String: [String]]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        map = (try? container.decode([String: [String]].self)) ?? [:]
    }

    var normalizedSelections: [String: [String]] {
        map.mapValues { ProviderAvailabilityLogic.sortedSlots($0) }
    }
}

private struct ProviderAvailabilityMutationRequest: Encodable {
    let availability: [String: [String]]
    let selections: [String: [String]]
    let slots: [String: [String]]

    init(selections: [String: [String]]) {
        let normalized = selections.mapValues { ProviderAvailabilityLogic.sortedSlots($0) }
        availability = normalized
        self.selections = normalized
        slots = normalized
    }
}

private struct ProviderAvailabilityMutationResponse: Decodable {
    let ok: Bool?
}

struct ProviderCalendarView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var selectedDate = Date()
    @AppStorage(ProviderAvailabilityStorageKeys.selections) private var storedSelections = "{}"
    @AppStorage(ProviderAvailabilityStorageKeys.weeklyTemplates) private var storedWeeklyTemplates = "{}"
    @AppStorage(ProviderAvailabilityStorageKeys.focusedDate) private var focusedDateValue = ""
    @State private var selectedSlots: Set<String> = []
    @State private var repeatWeeklySelection = false
    @State private var templateCopyTargets: Set<Int> = []
    @State private var availabilityService: ProviderAvailabilityService?
    @State private var syncError: String?
    @State private var syncNotice: String?
    @State private var isSyncingSelections = false
    @State private var didLoadRemoteSelections = false

    private let slots = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00", "16:00", "17:00"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DatePicker(
                    "Müsaitlik",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .environment(\.colorScheme, .light)
                .environment(\.locale, Locale(identifier: "tr_TR"))
                .tint(DS.Colors.primary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Uygun Saatler")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(slots, id: \.self) { slot in
                            Button {
                                if selectedSlots.contains(slot) {
                                    selectedSlots.remove(slot)
                                } else {
                                    selectedSlots.insert(slot)
                                }
                                persistSelection()
                            } label: {
                                Text(slot)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(selectedSlots.contains(slot) ? DS.Colors.primary : Color.white)
                                    .foregroundStyle(selectedSlots.contains(slot) ? Color.white : DS.Colors.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $repeatWeeklySelection) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Her hafta tekrarla")
                                .font(.headline)
                                .foregroundStyle(DS.Colors.textPrimary)
                            Text("\(selectedWeekdayTitle) gününe seçtiğin saatleri önümüzdeki 8 hafta boyunca uygula.")
                                .font(.footnote)
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                    .tint(DS.Colors.primary)

                    if let templateSummary {
                        Text(templateSummary)
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.primary)
                    } else {
                        Text("Tek seferlik seçim yaparsan yalnızca seçtiğin tarih güncellenir.")
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }

                    HStack(spacing: 10) {
                        Button {
                            copySelectedDayToThisWeek()
                        } label: {
                            Label("Bu haftaya kopyala", systemImage: "calendar.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(DS.Colors.primary)

                        Button(role: .destructive) {
                            clearWeeklyTemplate()
                        } label: {
                            Label("Şablonu temizle", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled((weeklyTemplates[ProviderAvailabilityLogic.weekday(for: selectedDate)] ?? []).isEmpty)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Şablonu diğer günlere uygula")
                            .font(.subheadline.bold())
                            .foregroundStyle(DS.Colors.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(weekdayOptions, id: \.weekday) { option in
                                Button {
                                    toggleTemplateTarget(option.weekday)
                                } label: {
                                    Text(option.title)
                                        .font(.footnote.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(templateCopyTargets.contains(option.weekday) ? DS.Colors.primary : Color.white)
                                        .foregroundStyle(templateCopyTargets.contains(option.weekday) ? Color.white : DS.Colors.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(option.weekday == selectedWeekday)
                                .opacity(option.weekday == selectedWeekday ? 0.45 : 1)
                            }
                        }

                        Button {
                            applyTemplateToSelectedWeekdays()
                        } label: {
                            Label("Seçili günlere uygula", systemImage: "arrow.triangle.branch")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DS.Colors.primary)
                        .disabled(templateCopyTargets.isEmpty || (weeklyTemplates[selectedWeekday] ?? []).isEmpty)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(DS.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Özet")
                        .font(.headline)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("\(selectedSlots.count) zaman aralığı seçildi")
                        .foregroundStyle(DS.Colors.textSecondary)
                    Text("Haftalık şablonlarda \(ProviderAvailabilityLogic.totalTemplateCount(in: weeklyTemplates)) saat kayıtlı")
                        .foregroundStyle(DS.Colors.textSecondary)
                    if let nextDate = ProviderAvailabilityLogic.nextAvailableDate(in: decodedSelections) {
                        Text("Sıradaki müsait gün: \(formattedDay(nextDate))")
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    if isSyncingSelections {
                        Text("Müsaitlik bilgilerin güncelleniyor...")
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.textSecondary)
                    } else if let syncNotice {
                        Text(syncNotice)
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.primary)
                    } else if let syncError {
                        Text(syncError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    } else {
                        Text("Seçimlerin güvenle saklanıyor. İnternet bağlantısı uygunsa diğer cihazlarında da güncel kalır.")
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(DS.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Müsaitlik")
        .toolbarBackground(DS.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            applyFocusedDateIfNeeded()
            loadSlotsForSelectedDate()
            loadRepeatPreferenceForSelectedDate()
        }
        .onChange(of: selectedDate) { _, _ in
            loadSlotsForSelectedDate()
            loadRepeatPreferenceForSelectedDate()
        }
        .task {
            availabilityService = ProviderAvailabilityService(api: session.deps.api)
            await loadRemoteSelectionsIfNeeded()
        }
    }

    private var selectedDateKey: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: selectedDate)
    }

    private var decodedSelections: [String: [String]] {
        ProviderAvailabilityLogic.decodeSelections(storedSelections)
    }

    private var weeklyTemplates: [Int: [String]] {
        ProviderAvailabilityLogic.decodeWeeklyTemplates(storedWeeklyTemplates)
    }

    private var selectedWeekdayTitle: String {
        ProviderAvailabilityLogic.weekdayTitle(
            for: ProviderAvailabilityLogic.weekday(for: selectedDate)
        )
    }

    private var selectedWeekday: Int {
        ProviderAvailabilityLogic.weekday(for: selectedDate)
    }

    private var weekdayOptions: [(weekday: Int, title: String)] {
        (1...7).map { weekday in
            (weekday, ProviderAvailabilityLogic.weekdayTitle(for: weekday))
        }
    }

    private var templateSummary: String? {
        let weekday = ProviderAvailabilityLogic.weekday(for: selectedDate)
        guard let slots = weeklyTemplates[weekday], !slots.isEmpty else { return nil }
        return "\(selectedWeekdayTitle) için haftalık şablon: \(slots.joined(separator: ", "))"
    }

    private func loadSlotsForSelectedDate() {
        selectedSlots = Set(decodedSelections[selectedDateKey] ?? [])
    }

    private func applyFocusedDateIfNeeded() {
        guard !focusedDateValue.isEmpty else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let focusedDate = formatter.date(from: focusedDateValue) {
            selectedDate = focusedDate
        }
        focusedDateValue = ""
    }

    private func loadRepeatPreferenceForSelectedDate() {
        repeatWeeklySelection = !(weeklyTemplates[selectedWeekday] ?? []).isEmpty
        templateCopyTargets = []
    }

    private func persistSelection() {
        let updated = ProviderAvailabilityLogic.selectionsApplyingWeeklyRule(
            currentSelections: decodedSelections,
            currentTemplates: weeklyTemplates,
            selectedDate: selectedDate,
            selectedSlots: Array(selectedSlots),
            appliesWeeklyTemplate: repeatWeeklySelection
        )
        storedSelections = ProviderAvailabilityLogic.encodeSelections(updated.selections)
        storedWeeklyTemplates = ProviderAvailabilityLogic.encodeWeeklyTemplates(updated.templates)
        Task {
            await syncSelections(updated.selections)
        }
    }

    private func copySelectedDayToThisWeek() {
        var updated = decodedSelections
        updated[selectedDateKey] = ProviderAvailabilityLogic.sortedSlots(Array(selectedSlots))
        storedSelections = ProviderAvailabilityLogic.encodeSelections(updated)
        syncNotice = "Seçili saatler bu haftadaki güne kopyalandı."
        syncError = nil

        Task {
            await syncSelections(updated)
        }
    }

    private func clearWeeklyTemplate() {
        var updatedTemplates = weeklyTemplates
        updatedTemplates[selectedWeekday] = []
        storedWeeklyTemplates = ProviderAvailabilityLogic.encodeWeeklyTemplates(updatedTemplates)
        repeatWeeklySelection = false
        templateCopyTargets = []
        syncNotice = "\(selectedWeekdayTitle) için haftalık şablon temizlendi."
        syncError = nil
    }

    private func toggleTemplateTarget(_ weekday: Int) {
        if templateCopyTargets.contains(weekday) {
            templateCopyTargets.remove(weekday)
        } else {
            templateCopyTargets.insert(weekday)
        }
    }

    private func applyTemplateToSelectedWeekdays() {
        let updatedTemplates = ProviderAvailabilityLogic.copyTemplate(
            from: selectedWeekday,
            to: Array(templateCopyTargets),
            using: weeklyTemplates
        )
        storedWeeklyTemplates = ProviderAvailabilityLogic.encodeWeeklyTemplates(updatedTemplates)
        syncNotice = "\(selectedWeekdayTitle) şablonu seçili günlere uygulandı."
        syncError = nil
        templateCopyTargets = []
    }

    private func formattedDay(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let date = formatter.date(from: value) else { return value }

        let output = DateFormatter()
        output.locale = Locale(identifier: "tr_TR")
        output.dateStyle = .medium
        return output.string(from: date)
    }

    private func loadRemoteSelectionsIfNeeded() async {
        guard !didLoadRemoteSelections, let availabilityService else { return }
        didLoadRemoteSelections = true

        do {
            if let remoteSelections = try await availabilityService.fetchSelections(), !remoteSelections.isEmpty {
                storedSelections = ProviderAvailabilityLogic.encodeSelections(remoteSelections)
                loadSlotsForSelectedDate()
                syncNotice = "Müsaitlik bilgilerin güncellendi."
                syncError = nil
            }
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 || code >= 500 {
                    syncNotice = "Müsaitlik bu cihazda saklanıyor. İnternet yeniden hazır olduğunda tekrar denenecek."
                    syncError = nil
                } else {
                    syncError = "Müsaitlik bilgileri şu anda alınamadı."
                    syncNotice = nil
                }
            default:
                syncError = "Müsaitlik bilgileri şu anda alınamadı."
                syncNotice = nil
            }
        } catch {
            syncError = "Müsaitlik bilgileri şu anda alınamadı."
            syncNotice = nil
        }
    }

    private func syncSelections(_ selections: [String: [String]]) async {
        guard didLoadRemoteSelections, let availabilityService else { return }
        isSyncingSelections = true
        defer { isSyncingSelections = false }

        do {
            try await availabilityService.saveSelections(selections)
            syncNotice = "Müsaitlik bilgilerin kaydedildi."
            syncError = nil
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 || code >= 500 {
                    syncNotice = "Müsaitlik bu cihazda kaydedildi. Bağlantı normale dönünce tekrar güncellenecek."
                    syncError = nil
                } else {
                    syncError = "Müsaitlik şu anda kaydedilemedi."
                    syncNotice = nil
                }
            default:
                syncError = "Müsaitlik şu anda kaydedilemedi."
                syncNotice = nil
            }
        } catch {
            syncError = "Müsaitlik şu anda kaydedilemedi."
            syncNotice = nil
        }
    }
}
