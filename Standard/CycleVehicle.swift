import Foundation

/// A free-floating vehicle: type, coordinate, battery, range, last updated.
public struct CycleVehicle: Identifiable, Codable, Sendable {
    public enum VehicleType: String, Codable, Sendable {
        case standard
        case eBike
        case cargo
        case adaptive
    }

    public let id: String
    public let systemId: String
    public let type: VehicleType
    public let coordinate: Coordinate
    public let batteryPercent: Int?
    public let rangeMetres: Int?
    public let lastUpdated: Date

    public init(
        id: String,
        systemId: String,
        type: VehicleType,
        coordinate: Coordinate,
        batteryPercent: Int?,
        rangeMetres: Int?,
        lastUpdated: Date
    ) {
        self.id = id
        self.systemId = systemId
        self.type = type
        self.coordinate = coordinate
        self.batteryPercent = batteryPercent
        self.rangeMetres = rangeMetres
        self.lastUpdated = lastUpdated
    }
}
