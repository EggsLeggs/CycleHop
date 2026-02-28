import Foundation

enum CitiBikeConfig {
    static let providerID        = "com.citibikenyc.citi-bike"
    static let systemName        = "Citi Bike"
    static let city              = "New York"
    static let country           = "US"
    static let operatorName      = "Lyft / Citi Bike"
    static let brandColour       = "#003B70"
    static let timezone          = "America/New_York"
    static let localJSONName     = "citibike-stations"
    static let stationCacheTTL: TimeInterval = 60
    static let systemCacheTTL:  TimeInterval = 86_400
    static let liveAPIURL        = URL(string: "https://gbfs.citibikenyc.com/gbfs/en/station_information.json")!
    static let webBookingURL     = URL(string: "https://citibikenyc.com")!
    static let appDeepLinkScheme = "citibike://"

    static let capabilities = ProviderCapabilities(
        hasDocking: true,
        hasFreeFloating: false,
        hasEBikes: true,
        hasCargoBikes: false,
        hasAdaptiveBikes: false,
        hasRealtimeAvailability: true,
        supportsReservations: false,
        supportsInAppBooking: false,
        requiresAuthentication: false,
        dataSource: .bundledJSON
    )
}
