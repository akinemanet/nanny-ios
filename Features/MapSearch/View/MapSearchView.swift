//
//  MapSearchView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import MapKit

struct MapSearchView: View {
    var isSelectingLocation = false
    var onLocationSelected: ((StoredLocation) -> Void)? = nil

    @State private var searchText = ""
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: StoredLocation.fallback.latitude,
                longitude: StoredLocation.fallback.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.05,
                longitudeDelta: 0.05
            )
        )
    )

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition)
                .ignoresSafeArea()
                .onMapCameraChange { context in
                    visibleRegion = context.region
                }

            if isSelectingLocation {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Istedigin konumu yaz...", text: $searchText)
                        Spacer()
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

                    Spacer()

                    Button(action: saveCurrentMapLocation) {
                        Text("Konumu Ayarla")
                            .font(.headline)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(DS.Colors.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.orange)

                    Spacer()

                    HStack {
                        Spacer()

                        Button(action: saveCurrentMapLocation) {
                            Image(systemName: "location")
                                .font(.title2)
                                .frame(width: 58, height: 58)
                                .background(DS.Colors.primary)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(isSelectingLocation ? "Konumun" : "Harita")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let location = StoredLocation.fromDefaults()
            searchText = location.name
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }

    private func saveCurrentMapLocation() {
        let coordinate = currentCoordinate
        let trimmedName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty
            ? StoredLocation.coordinateLabel(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            : trimmedName

        let location = StoredLocation(
            name: resolvedName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        StoredLocation.save(location)
        onLocationSelected?(location)
    }

    private var currentCoordinate: CLLocationCoordinate2D {
        visibleRegion?.center ?? StoredLocation.fromDefaults().clCoordinate
    }
}

struct NannyLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let price: Int
}

private extension StoredLocation {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
