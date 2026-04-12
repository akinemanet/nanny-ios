//
//  LocationIntroView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI

struct StoredLocation: Equatable {
    let name: String
    let latitude: Double
    let longitude: Double

    static let fallback = StoredLocation(
        name: "Kadıköy, İstanbul",
        latitude: 41.015137,
        longitude: 28.979530
    )

    static func fromDefaults(_ defaults: UserDefaults = .standard) -> StoredLocation {
        let name = localizedDisplayName(defaults.string(forKey: StoredLocationKeys.name) ?? fallback.name)
        let latitude = defaults.object(forKey: StoredLocationKeys.latitude) as? Double ?? fallback.latitude
        let longitude = defaults.object(forKey: StoredLocationKeys.longitude) as? Double ?? fallback.longitude

        return StoredLocation(name: name, latitude: latitude, longitude: longitude)
    }

    static func save(_ location: StoredLocation, defaults: UserDefaults = .standard) {
        defaults.set(localizedDisplayName(location.name), forKey: StoredLocationKeys.name)
        defaults.set(location.latitude, forKey: StoredLocationKeys.latitude)
        defaults.set(location.longitude, forKey: StoredLocationKeys.longitude)
    }

    static func localizedDisplayName(_ value: String) -> String {
        value
            .replacingOccurrences(of: "Kadikoy", with: "Kadıköy")
            .replacingOccurrences(of: "Istanbul", with: "İstanbul")
            .replacingOccurrences(of: "Besiktas", with: "Beşiktaş")
            .replacingOccurrences(of: "Izmir", with: "İzmir")
            .replacingOccurrences(of: "Cankaya", with: "Çankaya")
    }

    static func coordinateLabel(latitude: Double, longitude: Double) -> String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }

    static func distanceInKilometers(
        from originLatitude: Double,
        originLongitude: Double,
        to destinationLatitude: Double?,
        destinationLongitude: Double?
    ) -> Double? {
        DistanceMath.distanceInKilometers(
            from: originLatitude,
            originLongitude: originLongitude,
            to: destinationLatitude,
            destinationLongitude: destinationLongitude
        )
    }

    static func distanceText(
        from originLatitude: Double,
        originLongitude: Double,
        to destinationLatitude: Double?,
        destinationLongitude: Double?,
        fallback: String
    ) -> String {
        DistanceMath.distanceText(
            from: originLatitude,
            originLongitude: originLongitude,
            to: destinationLatitude,
            destinationLongitude: destinationLongitude,
            fallback: fallback
        )
    }
}

enum StoredLocationKeys {
    static let name = "selectedLocationName"
    static let latitude = "selectedLocationLatitude"
    static let longitude = "selectedLocationLongitude"
}

struct LocationIntroView: View {
    let onUseCurrentLocation: () -> Void
    let onSetLocationManually: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Merhaba, tanıştığımıza memnun olduk!")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Yakınındaki bakıcıları bulmaya başlamak için konumunu ayarla")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(action: onUseCurrentLocation) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Mevcut konumu kullan")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Size.buttonHeight)
                .background(DS.Colors.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            }

            Text("Yakındaki aile ve bakıcı eşleşmeleri için konum izni gerekecek.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("veya konumunu manuel ayarla", action: onSetLocationManually)
                .foregroundStyle(DS.Colors.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(DS.Colors.background)
    }
}
