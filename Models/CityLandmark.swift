import CoreLocation

/// A named landmark used as the default mock user location for a city.
public struct CityLandmark: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let coordinate: CLLocationCoordinate2D
    public let providerID: String
}
