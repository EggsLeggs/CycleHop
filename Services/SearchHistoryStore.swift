import Foundation
import CoreLocation

/// A single search destination saved for quick re-use.
struct SearchHistoryItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let addedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: UUID = UUID(), title: String, subtitle: String, latitude: Double, longitude: Double, addedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.addedAt = addedAt
    }
}

/// Persists and exposes recent search destinations; dedupes by title+subtitle, cap at 10.
final class SearchHistoryStore: ObservableObject {
    @Published private(set) var recentSearches: [SearchHistoryItem] = []

    private let maxCount = 10
    private let key = "searchHistory"

    init() {
        load()
    }

    func add(title: String, subtitle: String, latitude: Double, longitude: Double) {
        let item = SearchHistoryItem(title: title, subtitle: subtitle, latitude: latitude, longitude: longitude)
        var list = recentSearches.filter { $0.title != title || $0.subtitle != subtitle }
        list.insert(item, at: 0)
        recentSearches = Array(list.prefix(maxCount))
        save()
    }

    func reset() {
        recentSearches = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return
        }
        recentSearches = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(recentSearches) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
