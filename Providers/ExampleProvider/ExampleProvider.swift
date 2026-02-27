import Foundation

// =============================================================================
// EXAMPLE PROVIDER TEMPLATE — "Riverton Bikes"
// This fictional provider shows you how to integrate any bike share system.
// Follow the STEP comments to adapt it for a real operator.
// =============================================================================

// MARK: - STEP 1: Replace all "Riverton" references with your system's name
//         and fill in the config constants below.

private enum RivertonBikesConfig {
    // STEP 2: Change this to a reverse-domain ID unique to your system.
    static let providerID = "com.example.riverton-bikes"

    static let systemName = "Riverton Bikes"
    static let city       = "Riverton"          // STEP 2: Your city
    static let country    = "US"                // STEP 2: ISO 3166-1 alpha-2
    static let timezone   = "America/Chicago"   // STEP 2: IANA timezone

    // STEP 3: Set these to your operator's real values.
    static let brandColour = "#0057B8"
    static let webURL = URL(string: "https://example.com/riverton-bikes")!

    // STEP 4: Declare which features your system supports.
    static let capabilities = ProviderCapabilities(
        hasDocking: true,
        hasFreeFloating: false,
        hasEBikes: false,
        hasCargoBikes: false,
        hasAdaptiveBikes: false,
        hasRealtimeAvailability: false,  // false = bundled JSON snapshot
        supportsReservations: false,
        supportsInAppBooking: false,
        requiresAuthentication: false,
        dataSource: .bundledJSON         // STEP 4: change to .liveAPI or .hybrid
    )

    // STEP 5: Point to your JSON file in Resources/ (omit extension).
    static let localJSONName = "riverton-stations"

    // STEP 6 (optional): Set your live API URL if you have one.
    static let liveAPIURL = URL(string: "https://api.example.com/stations")!
}

// MARK: - STEP 7: Implement the provider class

public final class RivertonBikesProvider: BikeShareProvider, @unchecked Sendable {

    public let id           = RivertonBikesConfig.providerID
    public let capabilities = RivertonBikesConfig.capabilities

    public init() {}

    // -------------------------------------------------------------------------
    // fetchSystem() — return static metadata about your bike share system.
    // -------------------------------------------------------------------------
    public func fetchSystem() async throws -> CycleSystem {
        CycleSystem(
            id: RivertonBikesConfig.providerID,
            name: RivertonBikesConfig.systemName,
            city: RivertonBikesConfig.city,
            country: RivertonBikesConfig.country,
            operatorName: "Riverton City Transit",  // STEP 7: your operator name
            brandColour: RivertonBikesConfig.brandColour,
            logoURL: nil,
            infoURL: RivertonBikesConfig.webURL,
            serviceArea: nil,
            timezone: RivertonBikesConfig.timezone,
            capabilities: RivertonBikesConfig.capabilities
        )
    }

    // -------------------------------------------------------------------------
    // fetchStations() — load from bundled JSON.
    // STEP 7: If your API returns a different schema, write a mapper similar
    // to SantanderDataMapper and call it here instead of using JSONDecoder directly.
    // -------------------------------------------------------------------------
    public func fetchStations() async throws -> [CycleStation] {
        guard let url = Bundle.main.url(
            forResource: RivertonBikesConfig.localJSONName,
            withExtension: "json"
        ) else {
            // For a live-API provider, replace the above with a URLSession fetch:
            //   let (data, _) = try await URLSession.shared.data(from: RivertonBikesConfig.liveAPIURL)
            throw ProviderError.dataNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            // STEP 7: If your JSON matches CycleStation's Codable format directly:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([CycleStation].self, from: data)
        } catch {
            throw ProviderError.decodingFailed(underlying: error)
        }
    }

    // -------------------------------------------------------------------------
    // bookingIntent() — show how to return both patterns.
    // STEP 7: Pick the pattern that matches your app / website.
    // -------------------------------------------------------------------------
    public func bookingIntent(for station: CycleStation) async throws -> BookingIntent? {
        // Pattern A — deep link with web fallback (preferred):
        // if let deepURL = URL(string: "rivertonbikes://station/\(station.id)") {
        //     return BookingIntent(stationId: station.id,
        //                         method: .appDeepLink(url: deepURL, webFallback: RivertonBikesConfig.webURL),
        //                         displayName: "Open in Riverton Bikes")
        // }

        // Pattern B — web only:
        return BookingIntent(
            stationId: station.id,
            method: .webOnly(url: RivertonBikesConfig.webURL),
            displayName: "View on Riverton Bikes website"
        )
    }
}
