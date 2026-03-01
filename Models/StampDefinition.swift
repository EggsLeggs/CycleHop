import Foundation

/// Kind of souvenir stamp (city or attraction).
public enum StampType: String, Codable, Equatable, Sendable { case city, attraction }

/// Circular region (center + radius) where a stamp can be claimed.
public struct StampArea: Codable, Equatable, Sendable {
    public let centerLatitude: Double
    public let centerLongitude: Double
    public let radiusMeters: Double
}

/// Defines a collectible stamp: id, name, type, image base names, and claim area.
public struct StampDefinition: Identifiable, Codable, Equatable, Sendable {
    public let id: String  // e.g. "london-city"
    public let displayName: String
    public let type: StampType
    public let stampPNGBaseName: String  // e.g. "LondonStamp" becomes LondonStampLight/Dark
    public let cityArtPNGBaseName: String?  // e.g. "LondonLocation" becomes LondonLocationLight/Dark
    public let area: StampArea
}
