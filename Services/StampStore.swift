import Foundation

/// Persists and exposes claimed stamps and dismissed promos; provides nearby unclaimed definitions.
@MainActor
final class StampStore: ObservableObject {
    @Published private(set) var claimedStamps: [ClaimedStamp] = []
    @Published private(set) var dismissedPromoIDs: Set<String> = []
    @Published private(set) var allDefinitions: [StampDefinition] = []

    private let claimedKey = "claimedStamps"
    private let dismissedKey = "dismissedPromoIDs"

    init() {
        loadFromDefaults()
    }

    func loadDefinitions(from registry: ProviderRegistry) {
        let providers = registry.providers.compactMap { $0 as? any OnboardingCityProvider }
        allDefinitions = providers.flatMap { $0.stampDefinitions }
    }

    func nearbyUnclaimed(at coord: Coordinate) -> [StampDefinition] {
        allDefinitions.filter { definition in
            guard !isAlreadyClaimed(definition) else { return false }
            let center = Coordinate(
                latitude: definition.area.centerLatitude,
                longitude: definition.area.centerLongitude
            )
            let distance = haversineMetres(from: coord, to: center)
            return distance <= definition.area.radiusMeters
        }
    }

    func claimStamp(id: String) {
        guard !claimedStamps.contains(where: { $0.id == id }) else { return }
        let stamp = ClaimedStamp(id: id, dateClaimed: Date())
        claimedStamps.append(stamp)
        saveClaimedStamps()
    }

    func claimAll(_ definitions: [StampDefinition]) {
        for definition in definitions {
            claimStamp(id: definition.id)
        }
    }

    func resetAllStamps() {
        claimedStamps = []
        dismissedPromoIDs = []
        UserDefaults.standard.removeObject(forKey: claimedKey)
        UserDefaults.standard.removeObject(forKey: dismissedKey)
    }

    func dismissPromo(id: String) {
        dismissedPromoIDs.insert(id)
        saveDismissedPromos()
    }

    func isAlreadyClaimed(_ definition: StampDefinition) -> Bool {
        claimedStamps.contains { $0.id == definition.id }
    }

    // MARK: Private

    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: claimedKey),
           let decoded = try? JSONDecoder().decode([ClaimedStamp].self, from: data) {
            claimedStamps = decoded
        }
        if let data = UserDefaults.standard.data(forKey: dismissedKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            dismissedPromoIDs = Set(decoded)
        }
    }

    private func saveClaimedStamps() {
        if let data = try? JSONEncoder().encode(claimedStamps) {
            UserDefaults.standard.set(data, forKey: claimedKey)
        }
    }

    private func saveDismissedPromos() {
        if let data = try? JSONEncoder().encode(Array(dismissedPromoIDs)) {
            UserDefaults.standard.set(data, forKey: dismissedKey)
        }
    }
}
