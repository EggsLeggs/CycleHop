import Foundation
import MapKit
import Combine

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var searchQuery: String = "" {
        didSet {
            completer.queryFragment = searchQuery
        }
    }

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    /// Bias search suggestions toward the selected city, shifting slightly
    /// toward the user when they are within 50 km of the city centre.
    func updateRegion(cityCenter: CLLocationCoordinate2D,
                      userLocation: CLLocationCoordinate2D?) {
        var center = cityCenter
        if let user = userLocation {
            let cityLoc = CLLocation(latitude: cityCenter.latitude, longitude: cityCenter.longitude)
            let userLoc = CLLocation(latitude: user.latitude, longitude: user.longitude)
            if userLoc.distance(from: cityLoc) < 50_000 {
                center = CLLocationCoordinate2D(
                    latitude: (cityCenter.latitude + user.latitude) / 2,
                    longitude: (cityCenter.longitude + user.longitude) / 2
                )
            }
        }
        completer.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
    }

    func search(for completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        return try? await search.start().mapItems.first?.placemark.coordinate
    }
}
