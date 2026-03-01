import Foundation

/// Static configuration for Santander Cycles (London) provider.
enum SantanderCyclesConfig {
    static let providerID = "com.tfl.santander-cycles"
    static let systemName = "Santander Cycles"
    static let city = "London"
    static let country = "GB"
    static let operatorName = "Transport for London"
    static let brandColour = "#E5362C"
    static let timezone = "Europe/London"
    static let liveAPIURL = URL(string: "https://api.tfl.gov.uk/BikePoint")!
    static let localJSONName = "santander-stations"
    static let stationCacheTTL: TimeInterval = 60
    static let systemCacheTTL: TimeInterval = 86_400
    static let appDeepLinkScheme = "santandercycles://"
    static let webBookingURL = URL(string: "https://santandercycles.co.uk")!

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
        dataSource: .hybrid
    )
}
