import Foundation
import SwiftUI

/// BikeShareProvider implementation for Citi Bike (New York City).
/// Loads station data from a bundled GBFS snapshot by default.
public final class CitiBikeProvider: BikeShareProvider, @unchecked Sendable {

    public let id = CitiBikeConfig.providerID
    public let capabilities = CitiBikeConfig.capabilities

    // Simple in-memory cache
    private var cachedStations: [CycleStation] = []
    private var cacheTimestamp: Date?

    public init() {}

    // MARK: - BikeShareProvider

    public func fetchSystem() async throws -> CycleSystem {
        CycleSystem(
            id: CitiBikeConfig.providerID,
            name: CitiBikeConfig.systemName,
            city: CitiBikeConfig.city,
            country: CitiBikeConfig.country,
            operatorName: CitiBikeConfig.operatorName,
            brandColour: CitiBikeConfig.brandColour,
            logoURL: nil,
            infoURL: CitiBikeConfig.webBookingURL,
            serviceArea: nil,
            timezone: CitiBikeConfig.timezone,
            capabilities: CitiBikeConfig.capabilities
        )
    }

    public func fetchStations() async throws -> [CycleStation] {
        if let ts = cacheTimestamp, Date().timeIntervalSince(ts) < CitiBikeConfig.stationCacheTTL {
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
            "Citi Bike is a docked system with no free-floating vehicles."
        )
    }

    public func bookingIntent(for station: CycleStation) async throws -> BookingIntent? {
        let rawID = station.id.replacingOccurrences(of: "\(id).", with: "")
        let deepLinkURL = URL(string: "\(CitiBikeConfig.appDeepLinkScheme)station/\(rawID)")

        let method: BookingIntent.Method = {
            if let url = deepLinkURL {
                return .appDeepLink(url: url, webFallback: CitiBikeConfig.webBookingURL)
            }
            return .webOnly(url: CitiBikeConfig.webBookingURL)
        }()

        return BookingIntent(
            stationId: station.id,
            method: method,
            displayName: NSLocalizedString("Open in Citi Bike", bundle: .localized, comment: "")
        )
    }

    // MARK: - Private helpers

    private func loadBundledJSON() throws -> Data {
        guard let url = Bundle.main.url(
            forResource: CitiBikeConfig.localJSONName,
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
            return try CitiBikeDataMapper.decodeAndMap(data: data, systemId: id)
        } catch {
            throw ProviderError.decodingFailed(underlying: error)
        }
    }
}

// MARK: - OnboardingCityProvider

extension CitiBikeProvider: OnboardingCityProvider {
    public var cityDisplayName: String { CitiBikeConfig.city }
    public var systemDisplayName: String { CitiBikeConfig.systemName }
    public var defaultCenter: Coordinate { Coordinate(latitude: 40.7580, longitude: -73.9855) }
    public var brandColor: Color { Color(hex: CitiBikeConfig.brandColour) ?? .blue }
    public var brandForegroundColor: Color { .white }
    public var cityArtSVGName: String? { "NewYork" }
    public var cityArtPNGBaseName: String? { "NewYorkLocation" }
    public var stampSVGName: String? { "NewYorkStamp" }
    public var stampDefinitions: [StampDefinition] { [
        StampDefinition(id: "new-york-city", displayName: "New York", type: .city,
            stampPNGBaseName: "NewYorkStamp", cityArtPNGBaseName: "NewYorkLocation",
            area: StampArea(centerLatitude: 40.7580, centerLongitude: -73.9855, radiusMeters: 30_000))
    ] }
}
