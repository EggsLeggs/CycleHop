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
        completer.resultTypes = .address
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.509, longitude: -0.118),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
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
