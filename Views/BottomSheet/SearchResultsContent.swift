import SwiftUI
import MapKit
import CoreLocation

/// List of stations near the search destination, scored by direction and availability.
struct SearchResultsContent: View {
    let destinationCoordinate: CLLocationCoordinate2D
    let bikePoints: [BikePoint]
    let userLocation: CLLocationCoordinate2D?
    @Binding var selectedBikePoint: BikePoint?
    @Binding var sheetMode: SheetMode
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedDetent: PresentationDetent
    let midDetent: PresentationDetent

    private struct ScoredStation: Identifiable {
        let bikePoint: BikePoint
        let score: Double
        let distance: Double
        let badges: [(text: String, color: Color)]
        var id: String { bikePoint.id }
    }

    private var scoredStations: [ScoredStation] {
        guard let userLocation else {
            return bikePoints.prefix(10).map { ScoredStation(bikePoint: $0, score: 0, distance: 0, badges: []) }
        }

        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let destLoc = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)

        var stations = bikePoints.compactMap { bp -> ScoredStation? in
            let stationLoc = CLLocation(latitude: bp.lat, longitude: bp.lon)
            let distToDest = destLoc.distance(from: stationLoc)
            let distToUser = userLoc.distance(from: stationLoc)

            guard distToDest < 1000 else { return nil } // Only within 1km of destination
            guard distToDest > 1 else { return nil } // Avoid division issues

            let totalBikes = bp.nbBikes ?? 0
            let docks = max(bp.nbDocks ?? 1, 1)
            let availabilityFactor = Double(totalBikes) / Double(docks)

            // Score by proximity to destination and availability
            let score = (1.0 / distToDest) * availabilityFactor

            return ScoredStation(bikePoint: bp, score: score, distance: distToUser, badges: [])
        }

        stations.sort { $0.score > $1.score }

        // Nearest = nearest to the marker (destination), not to user
        let nearest = stations.min(by: { a, b in
            let locA = CLLocation(latitude: a.bikePoint.lat, longitude: a.bikePoint.lon)
            let locB = CLLocation(latitude: b.bikePoint.lat, longitude: b.bikePoint.lon)
            return locA.distance(from: destLoc) < locB.distance(from: destLoc)
        })
        let mostBikes = stations.max(by: { ($0.bikePoint.nbBikes ?? 0) < ($1.bikePoint.nbBikes ?? 0) })
        let mostEBikes = stations.max(by: { ($0.bikePoint.nbEBikes ?? 0) < ($1.bikePoint.nbEBikes ?? 0) })

        return stations.prefix(20).map { station in
            var badges: [(text: String, color: Color)] = []

            // Count how many "bests" this station wins
            var wins = 0
            if station.bikePoint.id == nearest?.bikePoint.id { wins += 1 }
            if station.bikePoint.id == mostBikes?.bikePoint.id { wins += 1 }
            if station.bikePoint.id == mostEBikes?.bikePoint.id { wins += 1 }

            if wins >= 2 {
                badges.append(("Best Overall", .green))
            } else {
                if station.bikePoint.id == nearest?.bikePoint.id {
                    badges.append(("Nearest", .blue))
                }
                if station.bikePoint.id == mostBikes?.bikePoint.id {
                    badges.append(("Most Bikes", .blue))
                }
                if station.bikePoint.id == mostEBikes?.bikePoint.id && (mostEBikes?.bikePoint.nbEBikes ?? 0) > 0 {
                    badges.append(("Most E-Bikes", .blue))
                }
            }

            return ScoredStation(bikePoint: station.bikePoint, score: station.score, distance: station.distance, badges: badges)
        }
    }

    private var recommended: [ScoredStation] {
        Array(scoredStations.filter { !$0.badges.isEmpty }.prefix(3))
    }

    private var nearby: [ScoredStation] {
        scoredStations.filter { station in
            !recommended.contains(where: { $0.bikePoint.id == station.bikePoint.id })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !recommended.isEmpty {
                    Text("Recommended")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(recommended) { station in
                        Button {
                            selectStation(station.bikePoint)
                        } label: {
                            BikePointCard(
                                bikePoint: station.bikePoint,
                                userLocation: userLocation,
                                badge: station.badges.first
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }

                if !nearby.isEmpty {
                    Text("Nearby")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, recommended.isEmpty ? 0 : 8)

                    ForEach(nearby) { station in
                        Button {
                            selectStation(station.bikePoint)
                        } label: {
                            BikePointCard(
                                bikePoint: station.bikePoint,
                                userLocation: userLocation
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                Divider()
                    .padding(.horizontal)
                    .padding(.top, 16)

                Button("Return to onboarding") {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    UserDefaults.standard.removeObject(forKey: "selectedProviderID")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 8)
        }
    }

    private func selectStation(_ bikePoint: BikePoint) {
        selectedBikePoint = bikePoint
        sheetMode = .bikePointDetail
        selectedDetent = midDetent
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: bikePoint.coordinate.latitude - 0.001,
                longitude: bikePoint.coordinate.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
}
