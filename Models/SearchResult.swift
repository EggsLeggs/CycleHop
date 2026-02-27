import Foundation
import CoreLocation

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}
