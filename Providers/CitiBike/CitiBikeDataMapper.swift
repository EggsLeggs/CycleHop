import Foundation

/// Maps the merged Citi Bike GBFS snapshot JSON to the CycleHop standard `CycleStation` model.
enum CitiBikeDataMapper {

    // MARK: Raw snapshot type

    struct RawStation: Decodable {
        let station_id: String
        let name: String
        let lat: Double
        let lon: Double
        let capacity: Int
        let num_bikes_available: Int
        let num_ebikes_available: Int
        let num_docks_available: Int
        let is_installed: Int
        let is_renting: Int
        let last_reported: Int
    }

    struct RawSnapshot: Decodable {
        let stations: [RawStation]
    }

    // MARK: Mapping

    static func map(_ raw: RawStation, systemId: String) -> CycleStation {
        let totalBikes    = raw.num_bikes_available
        let eBikes        = raw.num_ebikes_available
        let standardBikes = totalBikes - eBikes
        let totalDocks    = raw.capacity
        let emptyDocks    = raw.num_docks_available
        let isOperational = raw.is_installed == 1 && raw.is_renting == 1

        let availability = VehicleAvailability(
            totalBikes: totalBikes,
            standardBikes: max(standardBikes, 0),
            eBikes: eBikes,
            cargoBikes: 0,
            adaptiveBikes: 0,
            emptyDocks: emptyDocks,
            totalDocks: totalDocks
        )

        let lastUpdated = Date(timeIntervalSince1970: TimeInterval(raw.last_reported))

        return CycleStation(
            id: "\(systemId).\(raw.station_id)",
            systemId: systemId,
            name: raw.name,
            coordinate: Coordinate(latitude: raw.lat, longitude: raw.lon),
            address: nil,
            availability: availability,
            totalDocks: totalDocks > 0 ? totalDocks : nil,
            isOperational: isOperational,
            lastUpdated: lastUpdated
        )
    }

    /// Decodes the merged snapshot JSON and maps to standard stations.
    static func decodeAndMap(data: Data, systemId: String) throws -> [CycleStation] {
        let snapshot = try JSONDecoder().decode(RawSnapshot.self, from: data)
        return snapshot.stations.map { map($0, systemId: systemId) }
    }
}
