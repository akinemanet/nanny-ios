//
//  AppButton.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct AppButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () async -> Void

    var body: some View {
        PrimaryButton(title, isLoading: isLoading) {
            Task { await action() }
        }
    }
}
