import SwiftUI

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
