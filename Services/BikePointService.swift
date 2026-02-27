import Foundation
import CoreLocation
import MapKit

@MainActor
class BikePointService: ObservableObject {
    @Published var bikePoints: [BikePoint] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var lastUpdated: Date? = nil

    init() {
        Task { await fetchBikePoints() }
    }

    func fetchBikePoints() async {
        isLoading = true
        defer { isLoading = false }

        guard let url = Bundle.main.url(forResource: "stations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([BikePoint].self, from: data)
        else {
            error = "Could not load station data."
            return
        }

        bikePoints = decoded
        error = nil
        lastUpdated = Date()
    }

    func distance(from location: CLLocationCoordinate2D, to bikePoint: BikePoint) -> CLLocationDistance {
        let from = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let to = CLLocation(latitude: bikePoint.lat, longitude: bikePoint.lon)
        return from.distance(from: to)
    }

    func walkingRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        let directions = MKDirections(request: request)
        return try? await directions.calculate().routes.first
    }

    func cyclingRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        return try? await directions.calculate().routes.first
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else { return nil }
        let components = [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality].compactMap { $0 }
        return components.joined(separator: " ")
    }
}
