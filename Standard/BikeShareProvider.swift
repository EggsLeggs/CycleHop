import Foundation

/// Core protocol for any bike share operator. Conform to this protocol to integrate
/// a new system into CycleHop. See `Providers/ExampleProvider/` for a template.
public protocol BikeShareProvider: AnyObject, Sendable {
    /// Reverse-domain provider identifier, e.g. "com.tfl.santander-cycles"
    var id: String { get }

    /// Describes what this provider supports.
    var capabilities: ProviderCapabilities { get }

    // MARK: - Required

    /// Returns metadata about the bike share system (name, city, branding, etc.)
    func fetchSystem() async throws -> CycleSystem

    /// Returns all stations known to this provider.
    func fetchStations() async throws -> [CycleStation]

    /// Returns stations within `radiusMetres` of `coordinate`, sorted nearest-first.
    func nearbyStations(to coordinate: Coordinate, radiusMetres: Int) async throws -> [CycleStation]

    /// Returns all stations whose coordinates fall within the given bounding box.
    func stations(in bounds: BoundingBox) async throws -> [CycleStation]

    // MARK: - Optional (default implementations provided)

    /// Returns free-floating vehicles. Throws `.unsupportedOperation` for docked-only systems.
    func fetchVehicles() async throws -> [CycleVehicle]

    /// Returns active service alerts.
    func fetchAlerts() async throws -> [CycleAlert]

    /// Returns available pricing plans.
    func fetchPricingPlans() async throws -> [PricingPlan]

    /// Returns a booking intent for the given station, or nil if not applicable.
    func bookingIntent(for station: CycleStation) async throws -> BookingIntent?
}

// MARK: - Default implementations

public extension BikeShareProvider {
    func fetchVehicles() async throws -> [CycleVehicle] {
        throw ProviderError.unsupportedOperation("fetchVehicles is not supported by \(id)")
    }

    func fetchAlerts() async throws -> [CycleAlert] {
        return []
    }

    func fetchPricingPlans() async throws -> [PricingPlan] {
        return []
    }

    func bookingIntent(for station: CycleStation) async throws -> BookingIntent? {
        return nil
    }

    /// Default nearby implementation: fetch all stations then filter client-side.
    func nearbyStations(to coordinate: Coordinate, radiusMetres: Int) async throws -> [CycleStation] {
        let all = try await fetchStations()
        return all
            .map { station in (station, haversineMetres(from: coordinate, to: station.coordinate)) }
            .filter { _, dist in dist <= Double(radiusMetres) }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    /// Default bounds implementation: fetch all stations then filter client-side.
    func stations(in bounds: BoundingBox) async throws -> [CycleStation] {
        let all = try await fetchStations()
        return all.filter { bounds.contains($0.coordinate) }
    }
}

// MARK: - Shared Haversine (no CoreLocation dependency in Standard layer)

func haversineMetres(from a: Coordinate, to b: Coordinate) -> Double {
    let earthRadiusM = 6_371_000.0
    let dLat = (b.latitude - a.latitude) * .pi / 180
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let lat1 = a.latitude * .pi / 180
    let lat2 = b.latitude * .pi / 180
    let sinDLat = sin(dLat / 2)
    let sinDLon = sin(dLon / 2)
    let h = sinDLat * sinDLat + sinDLon * sinDLon * cos(lat1) * cos(lat2)
    return 2 * earthRadiusM * asin(min(1, sqrt(h)))
}
