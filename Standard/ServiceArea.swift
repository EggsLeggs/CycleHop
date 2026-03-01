import Foundation

/// Latitude/longitude pair used across the Standard layer.
public struct Coordinate: Codable, Sendable, Equatable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Axis-aligned rectangle in lat/lon for filtering stations.
public struct BoundingBox: Codable, Sendable {
    public let minLat: Double
    public let maxLat: Double
    public let minLon: Double
    public let maxLon: Double

    public init(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        self.minLat = minLat
        self.maxLat = maxLat
        self.minLon = minLon
        self.maxLon = maxLon
    }

    public func contains(_ coord: Coordinate) -> Bool {
        coord.latitude >= minLat &&
        coord.latitude <= maxLat &&
        coord.longitude >= minLon &&
        coord.longitude <= maxLon
    }
}

/// Service area as polygon and bounding box.
public struct ServiceArea: Codable, Sendable {
    public let polygonCoordinates: [Coordinate]
    public let boundingBox: BoundingBox

    public init(polygonCoordinates: [Coordinate], boundingBox: BoundingBox) {
        self.polygonCoordinates = polygonCoordinates
        self.boundingBox = boundingBox
    }
}
