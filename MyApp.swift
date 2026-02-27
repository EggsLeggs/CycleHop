import SwiftUI

@main
struct CycleHopApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingHost()
                .environmentObject(ProviderRegistry.shared)
        }
    }
}
