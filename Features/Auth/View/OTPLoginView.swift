//
//  OTPLoginView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct OTPLoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @AppStorage("kvkkAcceptedParentRegistration") private var parentKVKKAccepted = false
    @AppStorage("kvkkAcceptedProviderRegistration") private var providerKVKKAccepted = false
    @State private var showKVKKSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer().frame(height: 24)
            Text("Giriş")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DS.Colors.textPrimary)
            Text("Rol").foregroundStyle(DS.Colors.textSecondary)

            HStack(spacing: 10) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Button {
                        viewModel.role = role
                    } label: {
                        Text(role.titleTR)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.role == role ? .white : DS.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(viewModel.role == role ? DS.Colors.primary : .white)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(viewModel.role == role ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Telefon").foregroundStyle(DS.Colors.textSecondary)
            AppTextField(placeholder: "+90555...", text: $viewModel.phone, keyboardType: .phonePad)

            if let err = viewModel.errorMessage {
                Text(err).foregroundStyle(.red).font(.footnote)
            }

            KVKKConsentBlock(
                isAccepted: kvkkBinding,
                showSheet: $showKVKKSheet,
                accentColor: DS.Colors.primary
            )

            PrimaryButton("Kod Gönder", isLoading: viewModel.isLoading) {
                Task { await viewModel.requestOTP() }
            }
            .disabled(!isKVKKAccepted)
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(DS.Colors.background.ignoresSafeArea())
        .sheet(isPresented: $showKVKKSheet) {
            KVKKDisclosureSheet()
        }
    }

    private var kvkkBinding: Binding<Bool> {
        Binding(
            get: { viewModel.role == .provider ? providerKVKKAccepted : parentKVKKAccepted },
            set: { newValue in
                if viewModel.role == .provider {
                    providerKVKKAccepted = newValue
                } else {
                    parentKVKKAccepted = newValue
                }
            }
        )
    }

    private var isKVKKAccepted: Bool {
        viewModel.role == .provider ? providerKVKKAccepted : parentKVKKAccepted
    }
}

struct KVKKConsentBlock: View {
    @Binding var isAccepted: Bool
    @Binding var showSheet: Bool
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isAccepted) {
                Text("KVKK aydınlatma metnini okudum ve kişisel verilerimin belirtilen kapsamda işlenmesini onaylıyorum.")
                    .font(.footnote)
                    .foregroundStyle(DS.Colors.textPrimary)
            }
            .toggleStyle(.checkboxLike)

            Button("KVKK metnini görüntüle") {
                showSheet = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(accentColor)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        }
    }
}

struct KVKKDisclosureSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("KVKK Aydınlatma Metni")
                        .font(.title2.bold())
                        .foregroundStyle(DS.Colors.textPrimary)

                    Group {
                        kvkkParagraph("Bu uygulama üzerinden paylaştığınız ad, soyad, telefon, e-posta, konum, ödeme ve profil bilgileri; üyelik oluşturma, kimlik doğrulama, rezervasyon yönetimi, ödeme süreçleri ve güvenlik kontrollerinin yürütülmesi amacıyla işlenir.")
                        kvkkParagraph("Kişisel verileriniz, hizmetin sunulabilmesi için yetkili iş ortakları, ödeme kuruluşları ve teknik altyapı sağlayıcıları ile yalnızca gerekli olduğu ölçüde paylaşılabilir.")
                        kvkkParagraph("Tarafımıza ilettiğiniz veriler; mevzuattan doğan saklama yükümlülükleri, uyuşmazlıkların çözümü, kullanıcı güvenliği ve hizmet kalitesinin artırılması amaçlarıyla sınırlı olarak muhafaza edilir.")
                        kvkkParagraph("KVKK kapsamında kişisel verilerinize ilişkin erişim, düzeltme, silme, işlenmesini sınırlandırma ve itiraz etme haklarına sahipsiniz. Bu taleplerinizi destek kanallarımız üzerinden iletebilirsiniz.")
                        kvkkParagraph("Onay vermeniz halinde, kayıt süreci kapsamında sağladığınız bilgilerin yukarıda belirtilen amaçlarla işlenmesini kabul etmiş olursunuz.")
                    }
                }
                .padding(20)
            }
            .background(DS.Colors.background.ignoresSafeArea())
            .navigationTitle("KVKK")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func kvkkParagraph(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(DS.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CheckboxLikeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(configuration.isOn ? DS.Colors.primary : DS.Colors.textSecondary)

                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension ToggleStyle where Self == CheckboxLikeToggleStyle {
    static var checkboxLike: CheckboxLikeToggleStyle { CheckboxLikeToggleStyle() }
}
