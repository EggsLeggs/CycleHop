import Foundation

/// Counts of bikes and docks at a station (standard, e-bike, cargo, etc.).
public struct VehicleAvailability: Codable, Sendable, Equatable {
    public let totalBikes: Int
    public let standardBikes: Int
    public let eBikes: Int
    public let cargoBikes: Int
    public let adaptiveBikes: Int
    public let emptyDocks: Int?
    public let totalDocks: Int?

    public init(
        totalBikes: Int,
        standardBikes: Int,
        eBikes: Int,
        cargoBikes: Int,
        adaptiveBikes: Int,
        emptyDocks: Int?,
        totalDocks: Int?
    ) {
        self.totalBikes = totalBikes
        self.standardBikes = standardBikes
        self.eBikes = eBikes
        self.cargoBikes = cargoBikes
        self.adaptiveBikes = adaptiveBikes
        self.emptyDocks = emptyDocks
        self.totalDocks = totalDocks
    }

    public static let empty = VehicleAvailability(
        totalBikes: 0,
        standardBikes: 0,
        eBikes: 0,
        cargoBikes: 0,
        adaptiveBikes: 0,
        emptyDocks: nil,
        totalDocks: nil
    )
}

/// A single dock station: id, name, coordinate, address, availability, operational status.
public struct CycleStation: Identifiable, Codable, Sendable {
    public let id: String
    public let systemId: String
    public let name: String
    public let coordinate: Coordinate
    public let address: String?
    public let availability: VehicleAvailability
    public let totalDocks: Int?
    public let isOperational: Bool
    public let lastUpdated: Date

    public init(
        id: String,
        systemId: String,
        name: String,
        coordinate: Coordinate,
        address: String?,
        availability: VehicleAvailability,
        totalDocks: Int?,
        isOperational: Bool,
        lastUpdated: Date
    ) {
        self.id = id
        self.systemId = systemId
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.availability = availability
        self.totalDocks = totalDocks
        self.isOperational = isOperational
        self.lastUpdated = lastUpdated
    }
}
