import Foundation

/// Maps TfL BikePoint JSON (same schema as `BikePoint` / `AdditionalProperty`) to
/// the CycleHop standard `CycleStation` model.
enum SantanderDataMapper {

    // MARK: Raw TfL types (mirror of BikePoint for decoding)

    struct TfLStation: Decodable {
        let id: String
        let commonName: String
        let lat: Double
        let lon: Double
        let additionalProperties: [TfLProperty]
    }

    struct TfLProperty: Decodable {
        let key: String
        let value: String
        let modified: String?
    }

    // MARK: Mapping

    static func map(_ raw: TfLStation, systemId: String) -> CycleStation {
        let props = raw.additionalProperties

        func intValue(for key: String) -> Int {
            props.first(where: { $0.key == key }).flatMap { Int($0.value) } ?? 0
        }

        let installed = props.first(where: { $0.key == "Installed" })?.value.lowercased()
        let isOperational = installed == nil || installed == "true"

        let totalBikes = intValue(for: "NbBikes")
        let standardBikes = intValue(for: "NbStandardBikes")
        let eBikes = intValue(for: "NbEBikes")
        let totalDocks = intValue(for: "NbDocks")
        let emptyDocks = intValue(for: "NbEmptyDocks")

        let availability = VehicleAvailability(
            totalBikes: totalBikes,
            standardBikes: standardBikes,
            eBikes: eBikes,
            cargoBikes: 0,
            adaptiveBikes: 0,
            emptyDocks: emptyDocks,
            totalDocks: totalDocks
        )

        // Parse last-updated from the most recent modified timestamp across all properties
        let lastUpdated: Date = props
            .compactMap { $0.modified }
            .compactMap { ISO8601DateFormatter().date(from: $0) }
            .max() ?? Date()

        return CycleStation(
            id: "\(systemId).\(raw.id)",
            systemId: systemId,
            name: raw.commonName,
            coordinate: Coordinate(latitude: raw.lat, longitude: raw.lon),
            address: nil,
            availability: availability,
            totalDocks: totalDocks > 0 ? totalDocks : nil,
            isOperational: isOperational,
            lastUpdated: lastUpdated
        )
    }

    /// Decodes raw JSON `Data` in TfL format and maps to standard stations.
    static func decodeAndMap(data: Data, systemId: String) throws -> [CycleStation] {
        let raw = try JSONDecoder().decode([TfLStation].self, from: data)
        return raw.map { map($0, systemId: systemId) }
    }
}
