import Foundation
import CoreLocation

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

struct AdditionalProperty: Codable, Equatable {
    let key: String
    let value: String
    let modified: String?
}
