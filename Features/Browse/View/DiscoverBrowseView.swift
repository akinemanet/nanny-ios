import SwiftUI

struct DiscoverBrowseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var selectedLocation = "San Francisco, California"
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var selectedCategory = "Bebek"
    @State private var selectedGender = "Farketmez"
    @State private var activePicker: PickerField?

    private let locations = [
        "San Francisco, California",
        "Los Angeles, California",
        "Chicago, Illinois",
        "New York, New York"
    ]
    private let categories = ["Bebek", "Yürümeye Başlayan", "Okul Öncesi", "Anaokulu", "İlkokul"]
    private let genders = ["Farketmez", "Kadın", "Erkek"]

    private enum PickerField: String, Identifiable {
        case location
        case date
        case time
        case category
        case gender

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            browseTopBar(title: "Keşfet")

            HStack(spacing: 22) {
                discoverTab("Arama", index: 0)
                discoverTab("Son Aramalar", index: 1)
            }
            .padding(.bottom, 8)

            if selectedTab == 0 {
                buttonField(icon: "mappin.circle.fill", text: selectedLocation) {
                    activePicker = .location
                }
                buttonField(icon: "calendar", text: formattedDate(selectedDate)) {
                    activePicker = .date
                }
                buttonField(icon: "clock.fill", text: formattedTime(selectedTime)) {
                    activePicker = .time
                }
                buttonField(icon: "basket.fill", text: selectedCategory) {
                    activePicker = .category
                }
                buttonField(icon: "person.2.fill", text: selectedGender) {
                    activePicker = .gender
                }
            } else {
                recentSearches
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Bakıcı Bul")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DS.Colors.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(20)
        .background(DS.Colors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .sheet(item: $activePicker) { picker in
            NavigationStack {
                pickerSheet(for: picker)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func buttonField(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(DS.Colors.textSecondary)
                Text(text)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(DS.Colors.surface.opacity(0.95), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pickerSheet(for picker: PickerField) -> some View {
        switch picker {
        case .location:
            selectionListSheet(
                title: "Konum",
                options: locations,
                selected: selectedLocation
            ) { selectedLocation = $0 }
        case .category:
            selectionListSheet(
                title: "Kategori",
                options: categories,
                selected: selectedCategory
            ) { selectedCategory = $0 }
        case .gender:
            selectionListSheet(
                title: "Cinsiyet",
                options: genders,
                selected: selectedGender
            ) { selectedGender = $0 }
        case .date:
            VStack(alignment: .leading, spacing: 20) {
                Text("Tarih")
                    .font(.title3.bold())
                    .foregroundStyle(DS.Colors.textPrimary)
                DatePicker(
                    "Tarih",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { activePicker = nil }
                }
            }
        case .time:
            VStack(alignment: .leading, spacing: 20) {
                Text("Saat")
                    .font(.title3.bold())
                    .foregroundStyle(DS.Colors.textPrimary)
                DatePicker(
                    "Saat",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { activePicker = nil }
                }
            }
        }
    }

    private func selectionListSheet(title: String, options: [String], selected: String, onSelect: @escaping (String) -> Void) -> some View {
        List(options, id: \.self) { option in
            Button {
                onSelect(option)
                activePicker = nil
            } label: {
                HStack {
                    Text(option)
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    if option == selected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(DS.Colors.primary)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func discoverTab(_ title: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            Text(title)
                .font(.headline.weight(selectedTab == index ? .semibold : .medium))
                .foregroundStyle(selectedTab == index ? DS.Colors.textPrimary : DS.Colors.textSecondary)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(selectedTab == index ? DS.Colors.primary : .clear)
                        .frame(height: 2)
                        .offset(y: 12)
                }
        }
        .buttonStyle(.plain)
    }

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(["Barbara Michelle", "Amber Julia", "Kristina Clark"], id: \.self) { item in
                Button {
                    selectedTab = 0
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(DS.Colors.textSecondary)
                        Text(item)
                            .foregroundStyle(DS.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(DS.Colors.surface.opacity(0.95), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func browseTopBar(title: String) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
            }

            Spacer()

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.textPrimary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
