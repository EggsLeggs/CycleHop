import Foundation
import CoreLocation

/// A bike share station or dock with location and availability from a provider.
struct BikePoint: Codable, Identifiable, Equatable {
    let id: String
    let commonName: String
    let lat: Double
    let lon: Double
    let additionalProperties: [AdditionalProperty]

    var nbBikes: Int? { additionalProperties.first(where: { $0.key == "NbBikes" }).flatMap { Int($0.value) } }
    var nbStandardBikes: Int? { additionalProperties.first(where: { $0.key == "NbStandardBikes" }).flatMap { Int($0.value) } }
    var nbEBikes: Int? { additionalProperties.first(where: { $0.key == "NbEBikes" }).flatMap { Int($0.value) } }
    var nbDocks: Int? { additionalProperties.first(where: { $0.key == "NbDocks" }).flatMap { Int($0.value) } }
    var nbEmptyDocks: Int? { additionalProperties.first(where: { $0.key == "NbEmptyDocks" }).flatMap { Int($0.value) } }

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }
}

/// Key-value pair for TfL-style station metadata (e.g. NbBikes, NbDocks).
struct AdditionalProperty: Codable, Equatable {
    let key: String
    let value: String
    let modified: String?
}

extension CycleStation {
    func toBikePoint() -> BikePoint {
        BikePoint(
            id: id,
            commonName: name,
            lat: coordinate.latitude,
            lon: coordinate.longitude,
            additionalProperties: [
                AdditionalProperty(key: "NbBikes", value: "\(availability.totalBikes)", modified: nil),
                AdditionalProperty(key: "NbStandardBikes", value: "\(availability.standardBikes)", modified: nil),
                AdditionalProperty(key: "NbEBikes", value: "\(availability.eBikes)", modified: nil),
                AdditionalProperty(key: "NbDocks", value: "\(availability.totalDocks ?? 0)", modified: nil),
                AdditionalProperty(key: "NbEmptyDocks", value: "\(availability.emptyDocks ?? 0)", modified: nil)
            ]
        )
    }
}
