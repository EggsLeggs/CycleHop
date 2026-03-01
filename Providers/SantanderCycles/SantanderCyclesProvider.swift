import Foundation
import SwiftUI

/// BikeShareProvider implementation for Santander Cycles (London).
/// Loads station data from a bundled JSON snapshot by default;
/// set `useLocalJSON: false` to fetch live from the TfL API.
public final class SantanderCyclesProvider: BikeShareProvider, @unchecked Sendable {

    public let id = SantanderCyclesConfig.providerID
    public let capabilities = SantanderCyclesConfig.capabilities

    private let useLocalJSON: Bool

    // In-memory cache for stations
    private var cachedStations: [CycleStation] = []
    private var cacheTimestamp: Date?

    public init(useLocalJSON: Bool = true) {
        self.useLocalJSON = useLocalJSON
    }

    // MARK: BikeShareProvider

    public func fetchSystem() async throws -> CycleSystem {
        CycleSystem(
            id: SantanderCyclesConfig.providerID,
            name: SantanderCyclesConfig.systemName,
            city: SantanderCyclesConfig.city,
            country: SantanderCyclesConfig.country,
            operatorName: SantanderCyclesConfig.operatorName,
            brandColour: SantanderCyclesConfig.brandColour,
            logoURL: nil,
            infoURL: SantanderCyclesConfig.webBookingURL,
            serviceArea: nil,
            timezone: SantanderCyclesConfig.timezone,
            capabilities: SantanderCyclesConfig.capabilities
        )
    }

    public func fetchStations() async throws -> [CycleStation] {
        // Return cached result if still fresh
        if let ts = cacheTimestamp, Date().timeIntervalSince(ts) < SantanderCyclesConfig.stationCacheTTL {
            return cachedStations
        }

        let data: Data
        if useLocalJSON {
            data = try loadBundledJSON()
        } else {
            data = try await fetchLiveData()
        }

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
            "Santander Cycles is a docked system with no free-floating vehicles."
        )
    }

    public func bookingIntent(for station: CycleStation) async throws -> BookingIntent? {
        // Construct a deep link with the station ID as a path component
        let rawID = station.id.replacingOccurrences(of: "\(id).", with: "")
        let deepLinkURL = URL(string: "\(SantanderCyclesConfig.appDeepLinkScheme)station/\(rawID)")

        let method: BookingIntent.Method = {
            if let url = deepLinkURL {
                return .appDeepLink(url: url, webFallback: SantanderCyclesConfig.webBookingURL)
            }
            return .webOnly(url: SantanderCyclesConfig.webBookingURL)
        }()

        return BookingIntent(
            stationId: station.id,
            method: method,
            displayName: NSLocalizedString("Open in Santander Cycles", bundle: .localized, comment: "")
        )
    }

    // MARK: Private helpers

    private func loadBundledJSON() throws -> Data {
        guard let url = Bundle.main.url(
            forResource: SantanderCyclesConfig.localJSONName,
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

    private func fetchLiveData() async throws -> Data {
        let request = URLRequest(url: SantanderCyclesConfig.liveAPIURL, timeoutInterval: 15)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200: break
                case 401, 403: throw ProviderError.unauthorized
                case 429: throw ProviderError.rateLimited(retryAfter: nil)
                default: throw ProviderError.providerUnavailable("HTTP \(http.statusCode)")
                }
            }
            return data
        } catch let providerErr as ProviderError {
            throw providerErr
        } catch {
            throw ProviderError.networkUnavailable
        }
    }

    private func mapStations(from data: Data) throws -> [CycleStation] {
        do {
            return try SantanderDataMapper.decodeAndMap(data: data, systemId: id)
        } catch {
            throw ProviderError.decodingFailed(underlying: error)
        }
    }
}

// MARK: OnboardingCityProvider

extension SantanderCyclesProvider: OnboardingCityProvider {
    public var cityDisplayName: String { SantanderCyclesConfig.city }
    public var systemDisplayName: String { SantanderCyclesConfig.systemName }
    public var defaultCenter: Coordinate { Coordinate(latitude: 51.509, longitude: -0.118) }
    public var brandColor: Color { Color(hex: SantanderCyclesConfig.brandColour) ?? .red }
    public var brandForegroundColor: Color { .white }
    public var cityArtSVGName: String? { "London" }
    public var cityArtPNGBaseName: String? { "LondonLocation" }
    public var stampSVGName: String? { "LondonStamp" }
    public var stampDefinitions: [StampDefinition] { [
        StampDefinition(id: "london-city", displayName: "London", type: .city,
            stampPNGBaseName: "LondonStamp", cityArtPNGBaseName: "LondonLocation",
            area: StampArea(centerLatitude: 51.509, centerLongitude: -0.118, radiusMeters: 20_000)),
        StampDefinition(id: "tower-bridge", displayName: "Tower Bridge", type: .attraction,
            stampPNGBaseName: "TowerBridgeAttractionStamp", cityArtPNGBaseName: "LondonLocation",
            area: StampArea(centerLatitude: 51.5055, centerLongitude: -0.0754, radiusMeters: 500))
    ] }
}
