//
//  ProviderCalendarView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

private enum ProviderAvailabilityStorageKeys {
    static let selections = "providerAvailabilitySelections"
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
    @State private var selectedSlots: Set<String> = []
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Uygun Saatler")
                        .font(.headline)

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
                                    .foregroundStyle(selectedSlots.contains(slot) ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Özet")
                        .font(.headline)
                    Text("\(selectedSlots.count) zaman aralığı seçildi")
                        .foregroundStyle(.secondary)
                    if let nextDate = ProviderAvailabilityLogic.nextAvailableDate(in: decodedSelections) {
                        Text("Siradaki musait gun: \(formattedDay(nextDate))")
                            .foregroundStyle(.secondary)
                    }
                    if isSyncingSelections {
                        Text("Musaitlik backend ile eszamanlaniyor...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if let syncNotice {
                        Text(syncNotice)
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.primary)
                    } else if let syncError {
                        Text(syncError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    } else {
                        Text("Secimlerin cihazda kaydediliyor. Backend musaitlik API'si geldiyse otomatik eszamanlanacak.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            }
            .padding()
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationTitle("Müsaitlik")
        .onAppear {
            loadSlotsForSelectedDate()
        }
        .onChange(of: selectedDate) { _, _ in
            loadSlotsForSelectedDate()
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

    private func loadSlotsForSelectedDate() {
        selectedSlots = Set(decodedSelections[selectedDateKey] ?? [])
    }

    private func persistSelection() {
        var updated = decodedSelections
        updated[selectedDateKey] = ProviderAvailabilityLogic.sortedSlots(Array(selectedSlots))
        storedSelections = ProviderAvailabilityLogic.encodeSelections(updated)
        Task {
            await syncSelections(updated)
        }
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
                syncNotice = "Musaitlik backend'den eszamanlandi."
                syncError = nil
            }
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    syncNotice = "Musaitlik bu cihazda kaydediliyor. Backend musaitlik endpoint'i hazir degil."
                } else {
                    syncError = error.localizedDescription
                    syncNotice = nil
                }
            default:
                syncError = error.localizedDescription
                syncNotice = nil
            }
        } catch {
            syncError = error.localizedDescription
            syncNotice = nil
        }
    }

    private func syncSelections(_ selections: [String: [String]]) async {
        guard didLoadRemoteSelections, let availabilityService else { return }
        isSyncingSelections = true
        defer { isSyncingSelections = false }

        do {
            try await availabilityService.saveSelections(selections)
            syncNotice = "Musaitlik backend ile eszamanlandi."
            syncError = nil
        } catch let error as APIError {
            switch error {
            case .http(let code, _):
                if code == 404 || code == 405 {
                    syncNotice = "Musaitlik cihazda guncellendi. Backend musaitlik endpoint'i hazir degil."
                } else {
                    syncError = error.localizedDescription
                    syncNotice = nil
                }
            default:
                syncError = error.localizedDescription
                syncNotice = nil
            }
        } catch {
            syncError = error.localizedDescription
            syncNotice = nil
        }
    }
}
