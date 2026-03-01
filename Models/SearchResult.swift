import Foundation
import CoreLocation

/// A single search result (name and coordinate) from place search.
struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}
