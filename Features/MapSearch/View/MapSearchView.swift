//
//  MapSearchView.swift
//  APIEnvironment
//
//  Created by Click Ajans on 12.03.2026.
//

import SwiftUI
import MapKit

struct MapSearchView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: sampleNannies) { nanny in
                    MapAnnotation(coordinate: nanny.coordinate) {
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)

                            Text("$\(nanny.price)")
                                .font(.caption)
                                .padding(6)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                VStack {
                    Spacer()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(sampleNannies) { nanny in
                                NavigationLink {
                                    NannyProfileView()
                                } label: {
                                    MapCard(nanny: nanny)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Map")
        }
    }
}

struct NannyLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let price: Int
}

private let sampleNannies = [
    NannyLocation(
        coordinate: CLLocationCoordinate2D(latitude: 41.01, longitude: 28.97),
        price: 15
    ),
    NannyLocation(
        coordinate: CLLocationCoordinate2D(latitude: 41.02, longitude: 28.99),
        price: 18
    )
]
