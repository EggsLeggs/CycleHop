import SwiftUI

struct OnboardingHost: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedProviderID") private var selectedProviderID = ""
    @EnvironmentObject private var registry: ProviderRegistry

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView(selectedProviderID: selectedProviderID.isEmpty ? nil : selectedProviderID)
            } else if isCompact {
                OnboardingFlow { providerID in
                    selectedProviderID = providerID
                    hasCompletedOnboarding = true
                }
            } else {
                Color.clear
                    .sheet(isPresented: .constant(true)) {
                        OnboardingFlow { providerID in
                            selectedProviderID = providerID
                            hasCompletedOnboarding = true
                        }
                        .frame(minWidth: 500, minHeight: 700)
                        .interactiveDismissDisabled()
                    }
            }
        }
        .task {
            registry.register(SantanderCyclesProvider())
            registry.register(CitiBikeProvider())
        }
        .onAppear {
            #if DEBUG
            Task { await TestSuite.run() }
            #endif
        }
    }
}
