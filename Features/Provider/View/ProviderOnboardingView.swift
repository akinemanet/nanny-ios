//
//  ProviderOnboardingView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ProviderOnboardingView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var vm: ProviderOnboardingViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showPDFPicker = false

    private let educationOptions = [
        "Lise",
        "Ön Lisans",
        "Lisans",
        "Yüksek Lisans",
        "Doktora"
    ]

    private let categoryOptions = [
        "Bebek Bakımı",
        "Yürümeye Başlayan",
        "Okul Öncesi",
        "Anaokulu",
        "İlkokul Desteği",
        "Özel Ders"
    ]

    init(service: ProviderService) {
        _vm = StateObject(wrappedValue: ProviderOnboardingViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                topBar

                statusCard
                mediaCard
                contactCard
                educationCard
                aboutCard
                categoriesCard
                documentsCard
                accountCard
                feedbackCard
                actionButtons
            }
            .padding(16)
        }
        .background(DS.Colors.background.ignoresSafeArea())
        .task { await vm.load() }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadImage(from: newItem) }
        }
        .fileImporter(
            isPresented: $showPDFPicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                vm.criminalRecordFileName = urls.first?.lastPathComponent ?? ""
            case .failure(let error):
                vm.errorMessage = error.localizedDescription
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Bakıcı Kayıt Süreci")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Button("Çıkış") {
                session.logout()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white, in: Capsule())
        }
    }

    private var statusCard: some View {
        AppCard {
            Text("Durum")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            if let acc = vm.account {
                StatusPill(status: acc.status)
                if let key = acc.subMerchantKey, !key.isEmpty {
                    CopyRow(title: "Alt Üye İşyeri Anahtarı", value: key)
                }
                if let err = acc.lastError, !err.isEmpty {
                    CopyRow(title: "Son Hata", value: err)
                }
            } else {
                Text("Henüz kayıt yok. Formu doldurup kaydedebilirsin.")
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
    }

    private var mediaCard: some View {
        AppCard {
            Text("Profil")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 84, height: 84)

                    if let profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text(vm.profilePhotoName.isEmpty ? "Fotoğraf Yükle" : "Fotoğrafı Değiştir")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.Colors.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(DS.Colors.primary.opacity(0.12), in: Capsule())
                    }

                    Text(vm.profilePhotoName.isEmpty ? "Profil fotoğrafı seçilmedi." : vm.profilePhotoName)
                        .font(.footnote)
                        .foregroundStyle(DS.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var contactCard: some View {
        AppCard {
            Text("İletişim")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            TextField("Adres", text: $vm.address)
            Divider()
            TextField("Ad", text: $vm.contactName)
            Divider()
            TextField("Soyad", text: $vm.contactSurname)
            Divider()
            TextField("E-posta", text: $vm.email)
            Divider()
            TextField("Telefon", text: $vm.gsmNumber)
        }
    }

    private var educationCard: some View {
        AppCard {
            Text("Eğitim Durumu")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            Menu {
                ForEach(educationOptions, id: \.self) { option in
                    Button(option) { vm.educationLevel = option }
                }
            } label: {
                HStack {
                    Text(vm.educationLevel.isEmpty ? "Eğitim seç" : vm.educationLevel)
                        .foregroundStyle(vm.educationLevel.isEmpty ? DS.Colors.textSecondary : DS.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .padding(16)
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutCard: some View {
        AppCard {
            Text("Hakkında")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            AppTextArea(
                placeholder: "Deneyimini, çalışma yaklaşımını ve ailelere neler sunduğunu anlat.",
                text: $vm.about,
                minHeight: 140
            )
        }
    }

    private var categoriesCard: some View {
        AppCard {
            Text("Kategoriler")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                ForEach(categoryOptions, id: \.self) { category in
                    let isSelected = vm.selectedCategories.contains(category)
                    Text(category)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : DS.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? DS.Colors.primary : .white)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                        }
                        .onTapGesture {
                            toggleCategory(category)
                        }
                }
            }
        }
    }

    private var documentsCard: some View {
        AppCard {
            Text("Belgeler")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            Button {
                showPDFPicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sabıka Kaydı PDF")
                            .foregroundStyle(DS.Colors.textPrimary)
                        Text(vm.criminalRecordFileName.isEmpty ? "PDF seçilmedi." : vm.criminalRecordFileName)
                            .font(.footnote)
                            .foregroundStyle(DS.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Text("Yükle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colors.primary)
                }
                .padding(16)
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var accountCard: some View {
        AppCard {
            Text("Hesap")
                .font(.headline)
                .foregroundStyle(DS.Colors.textPrimary)

            TextField("Mağaza/İşletme Adı", text: $vm.storeName)
            Divider()
            TextField("IBAN", text: $vm.iban)
            Divider()
            TextField("TCKN", text: $vm.identityNumber)
        }
    }

    @ViewBuilder
    private var feedbackCard: some View {
        if let msg = vm.message {
            AppCard {
                Text(msg)
                    .foregroundStyle(.green)
            }
        }

        if let err = vm.errorMessage {
            AppCard {
                Text(err)
                    .foregroundStyle(.red)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton("Kaydet / Güncelle", isLoading: vm.isLoading) {
                Task { await vm.save() }
            }

            Button("Yenile") {
                Task { await vm.load() }
            }
            .font(.headline)
            .foregroundStyle(DS.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white, in: RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous))
        }
    }

    private func toggleCategory(_ category: String) {
        if vm.selectedCategories.contains(category) {
            vm.selectedCategories.removeAll { $0 == category }
        } else {
            vm.selectedCategories.append(category)
        }
    }

    private func loadImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = uiImage
                vm.profilePhotoName = "profil-fotografi.jpg"
            }
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
}
