import Foundation
import SwiftUI

/// BikeShareProvider implementation for Vélib' Métropole (Paris).
/// Loads station data from a bundled GBFS snapshot by default.
public final class VelibProvider: BikeShareProvider, @unchecked Sendable {

    public let id = VelibConfig.providerID
    public let capabilities = VelibConfig.capabilities

    // Simple in-memory cache
    private var cachedStations: [CycleStation] = []
    private var cacheTimestamp: Date?

    public init() {}

    // MARK: - BikeShareProvider

    public func fetchSystem() async throws -> CycleSystem {
        CycleSystem(
            id: VelibConfig.providerID,
            name: VelibConfig.systemName,
            city: VelibConfig.city,
            country: VelibConfig.country,
            operatorName: VelibConfig.operatorName,
            brandColour: VelibConfig.brandColour,
            logoURL: nil,
            infoURL: VelibConfig.webBookingURL,
            serviceArea: nil,
            timezone: VelibConfig.timezone,
            capabilities: VelibConfig.capabilities
        )
    }

    public func fetchStations() async throws -> [CycleStation] {
        if let ts = cacheTimestamp, Date().timeIntervalSince(ts) < VelibConfig.stationCacheTTL {
            return cachedStations
        }

        let data = try loadBundledJSON()
        let stations = try mapStations(from: data)
        cachedStations = stations
        cacheTimestamp = Date()
        return stations
    }

    public func nearbyStations(to coordinate: Coordinate, radiusMetres: Int) async throws -> [CycleStation] {
        let all = try await fetchStations()
        return all
            .map { station in (station, haversineMetres(from: coordinate, to: station.coordinate)) }
            .filter { _, dist in dist <= Double(radiusMetres) }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    public func stations(in bounds: BoundingBox) async throws -> [CycleStation] {
        let all = try await fetchStations()
        return all.filter { bounds.contains($0.coordinate) }
    }

    public func fetchVehicles() async throws -> [CycleVehicle] {
        throw ProviderError.unsupportedOperation(
            "Vélib' Métropole is a docked system with no free-floating vehicles."
        )
    }

    public func bookingIntent(for station: CycleStation) async throws -> BookingIntent? {
        BookingIntent(
            stationId: station.id,
            method: .webOnly(url: VelibConfig.webBookingURL),
            displayName: NSLocalizedString("Open Vélib' Métropole", bundle: .localized, comment: "")
        )
    }

    // MARK: - Private helpers

    private func loadBundledJSON() throws -> Data {
        guard let url = Bundle.main.url(
            forResource: VelibConfig.localJSONName,
            withExtension: "json"
        ) else {
            throw ProviderError.dataNotFound
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw ProviderError.decodingFailed(underlying: error)
        }
    }

    private func mapStations(from data: Data) throws -> [CycleStation] {
        do {
            return try VelibDataMapper.decodeAndMap(data: data, systemId: id)
        } catch {
            throw ProviderError.decodingFailed(underlying: error)
        }
    }
}

// MARK: - OnboardingCityProvider

extension VelibProvider: OnboardingCityProvider {
    public var cityDisplayName: String { VelibConfig.city }
    public var systemDisplayName: String { VelibConfig.systemName }
    public var defaultCenter: Coordinate { Coordinate(latitude: 48.8566, longitude: 2.3522) }
    public var brandColor: Color { Color(hex: VelibConfig.brandColour) ?? .green }
    public var brandForegroundColor: Color { .white }
    public var cityArtSVGName: String? { "Paris" }
    public var cityArtPNGBaseName: String? { "ParisLocation" }
    public var stampSVGName: String? { "ParisStamp" }
    public var stampDefinitions: [StampDefinition] { [
        StampDefinition(id: "paris-city", displayName: "Paris", type: .city,
            stampPNGBaseName: "ParisStamp", cityArtPNGBaseName: "ParisLocation",
            area: StampArea(centerLatitude: 48.8566, centerLongitude: 2.3522, radiusMeters: 20_000)),
        StampDefinition(id: "eiffel-tower", displayName: "Eiffel Tower", type: .attraction,
            stampPNGBaseName: "EifelAttractionStamp", cityArtPNGBaseName: "ParisLocation",
            area: StampArea(centerLatitude: 48.8584, centerLongitude: 2.2945, radiusMeters: 500)),
        StampDefinition(id: "arc-de-triomphe", displayName: "Arc de Triomphe", type: .attraction,
            stampPNGBaseName: "ArcdeTriompheAttractionStamp", cityArtPNGBaseName: "ParisLocation",
            area: StampArea(centerLatitude: 48.8738, centerLongitude: 2.2950, radiusMeters: 300))
    ] }
}
