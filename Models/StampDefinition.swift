import Foundation

public enum StampType: String, Codable, Equatable, Sendable { case city, attraction }

public struct StampArea: Codable, Equatable, Sendable {
    public let centerLatitude: Double
    public let centerLongitude: Double
    public let radiusMeters: Double
}

public struct StampDefinition: Identifiable, Codable, Equatable, Sendable {
    public let id: String              // e.g. "london-city"
    public let displayName: String
    public let type: StampType
    public let stampPNGBaseName: String // e.g. "LondonStamp" → LondonStampLight/Dark
    public let cityArtPNGBaseName: String? // e.g. "LondonLocation" → LondonLocationLight/Dark
    public let area: StampArea
}
