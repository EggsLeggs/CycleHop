import Foundation

/// Central registry for all active bike share providers.
/// Register providers at app startup; the registry aggregates their data.
@MainActor
public final class ProviderRegistry: ObservableObject {
    public static let shared = ProviderRegistry()

    @Published public private(set) var providers: [any BikeShareProvider] = []

    private init() {}

    // MARK: - Registration

    /// Adds a provider. If a provider with the same `id` is already registered, it is replaced.
    public func register(_ provider: any BikeShareProvider) {
        if let existingIndex = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[existingIndex] = provider
        } else {
            providers.append(provider)
        }
    }

    /// Removes the provider with the given ID, if registered.
    public func unregister(id: String) {
        providers.removeAll { $0.id == id }
    }

    /// Returns the provider with the given ID, or nil if not registered.
    public func provider(id: String) -> (any BikeShareProvider)? {
        providers.first { $0.id == id }
    }

    // MARK: - Aggregation

    /// Fetches stations from all registered providers concurrently and merges results.
    public func fetchAllStations() async -> [CycleStation] {
        await withTaskGroup(of: [CycleStation].self) { group in
            for provider in providers {
                group.addTask {
                    (try? await provider.fetchStations()) ?? []
                }
            }
            var result: [CycleStation] = []
            for await stations in group {
                result.append(contentsOf: stations)
            }
            return result
        }
    }

    /// Returns all nearby stations across all providers, sorted nearest-first.
    public func nearbyStations(to coordinate: Coordinate, radiusMetres: Int) async -> [CycleStation] {
        await withTaskGroup(of: [CycleStation].self) { group in
            for provider in providers {
                group.addTask {
                    (try? await provider.nearbyStations(to: coordinate, radiusMetres: radiusMetres)) ?? []
                }
            }
            var result: [CycleStation] = []
            for await stations in group {
                result.append(contentsOf: stations)
            }
            return result.sorted {
                haversineMetres(from: coordinate, to: $0.coordinate) <
                haversineMetres(from: coordinate, to: $1.coordinate)
            }
        }
    }
}
