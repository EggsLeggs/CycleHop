import Foundation

enum VelibConfig {
    static let providerID        = "com.velib-metropole.velib"
    static let systemName        = "Vélib' Métropole"
    static let city              = "Paris"
    static let country           = "FR"
    static let operatorName      = "Smovengo / Vélib' Métropole"
    static let brandColour       = "#00A650"
    static let timezone          = "Europe/Paris"
    static let localJSONName     = "velib-stations"
    static let stationCacheTTL: TimeInterval = 60
    static let systemCacheTTL:  TimeInterval = 86_400
    static let liveAPIURL        = URL(string: "https://velib-metropole-opendata.smovengo.cloud/opendata/Velib_Metropole/station_information.json")!
    static let webBookingURL     = URL(string: "https://www.velib-metropole.fr")!

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
