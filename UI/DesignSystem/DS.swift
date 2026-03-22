//
//  DS.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//
import SwiftUI

enum DS {
    enum Colors {
        static let primary = Color(red: 0.12, green: 0.47, blue: 0.74)
        static let accent = Color(red: 0.98, green: 0.56, blue: 0.18)
        static let background = Color(red: 0.96, green: 0.96, blue: 0.97)
        static let surface = Color.white
        static let textPrimary = Color.black.opacity(0.88)
        static let textSecondary = Color.black.opacity(0.62)
        static let border = Color.black.opacity(0.06)
    }

    enum Radius {
        static let medium: CGFloat = 18
    }

    enum Size {
        static let fieldHeight: CGFloat = 56
        static let buttonHeight: CGFloat = 54
    }
}
