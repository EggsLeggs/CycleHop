import SwiftUI

/// Main app entry point. Wires up the provider registry and stamp store, then presents onboarding or main content.
@main
struct CycleHopApp: App {
    @StateObject private var stampStore = StampStore()

    /// Registers built-in providers at app startup so the registry is never empty when any view body runs.
    private static func ensureProvidersRegistered(stampStore: StampStore) {
        let registry = ProviderRegistry.shared
        guard registry.providers.isEmpty else { return }
        registry.register(SantanderCyclesProvider())
        registry.register(CitiBikeProvider())
        registry.register(VelibProvider())
        stampStore.loadDefinitions(from: registry)
    }

    var body: some Scene {
        Self.ensureProvidersRegistered(stampStore: stampStore)
        return WindowGroup {
            OnboardingHost()
                .environmentObject(ProviderRegistry.shared)
                .environmentObject(stampStore)
        }
    }
}
