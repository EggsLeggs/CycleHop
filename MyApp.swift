import SwiftUI

/// Main app entry point. Wires up the provider registry and stamp store, then presents onboarding or main content.
@main
struct CycleHopApp: App {
    @StateObject private var stampStore = StampStore()

    var body: some Scene {
        WindowGroup {
            OnboardingHost()
                .environmentObject(ProviderRegistry.shared)
                .environmentObject(stampStore)
        }
    }
}
