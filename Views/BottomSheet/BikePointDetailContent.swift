import SwiftUI
import MapKit
import CoreLocation

/// Full station detail: stats, capacity bar, routes, address, booking.
struct BikePointDetailContent: View {
    let bikePoint: BikePoint
    let userLocation: CLLocationCoordinate2D?
    let bikePointService: BikePointService

    @State private var walkingDistance: String?
    @State private var walkingTime: String?
    @State private var cyclingDistance: String?
    @State private var cyclingTime: String?
    @State private var address: String?
    @State private var isLoadingRoutes = true

    private var nameParts: (primary: String, secondary: String?) {
        bikePoint.commonName.splitBikePointName()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Stats grid (standard, e-bikes, empty)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatBox(title: "Standard", value: "\(bikePoint.nbStandardBikes ?? 0)", icon: "bicycle", color: .red)
                    StatBox(title: "E-Bikes", value: "\(bikePoint.nbEBikes ?? 0)", icon: "bolt.fill", color: .blue)
                    StatBox(title: "Empty", value: "\(bikePoint.nbEmptyDocks ?? 0)", icon: "square.dashed", color: .gray)
                }

                // Capacity bar (red/blue/grey)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Capacity")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        let total = max(bikePoint.nbDocks ?? 1, 1)
                        let standardWidth = geo.size.width * CGFloat(bikePoint.nbStandardBikes ?? 0) / CGFloat(total)
                        let eBikeWidth = geo.size.width * CGFloat(bikePoint.nbEBikes ?? 0) / CGFloat(total)

                        HStack(spacing: 0) {
                            Rectangle().fill(.red).frame(width: standardWidth)
                            Rectangle().fill(.blue).frame(width: eBikeWidth)
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                        .clipShape(Capsule())
                        .accessibilityHidden(true)
                    }
                    .frame(height: 8)

                    Text(String(format: NSLocalizedString("docks_occupied_format", bundle: .localized, comment: ""), bikePoint.nbBikes ?? 0, bikePoint.nbDocks ?? 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Route info
                if isLoadingRoutes {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Calculating routes...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if let walkingDistance, let walkingTime {
                        RouteRow(icon: "figure.walk", title: "Walking", distance: walkingDistance, time: walkingTime)
                    }
                    if let cyclingDistance, let cyclingTime {
                        RouteRow(icon: "bicycle", title: "Cycling", distance: cyclingDistance, time: cyclingTime)
                    }
                }

                // Address
                if let address {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.secondary)
                        Text(address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .task {
            await loadRouteData()
        }
    }

    private func loadRouteData() async {
        guard let userLocation else {
            isLoadingRoutes = false
            return
        }

        async let walkRoute = bikePointService.walkingRoute(from: userLocation, to: bikePoint.coordinate)
        async let cycleRoute = bikePointService.cyclingRoute(from: userLocation, to: bikePoint.coordinate)
        async let addr = bikePointService.reverseGeocode(coordinate: bikePoint.coordinate)

        if let route = await walkRoute {
            walkingDistance = formatDistance(route.distance)
            walkingTime = formatWalkingTime(route.expectedTravelTime)
        }
        if let route = await cycleRoute {
            cyclingDistance = formatDistance(route.distance)
            cyclingTime = formatWalkingTime(route.expectedTravelTime)
        }
        address = await addr
        isLoadingRoutes = false
    }
}

/// Small stat block: icon, value, title (e.g. Standard bikes count).
struct StatBox: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

/// Single row for walking or cycling route (icon, title, distance, time).
struct RouteRow: View {
    let icon: String
    let title: LocalizedStringKey
    let distance: String
    let time: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(distance)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(time)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
    }
}
