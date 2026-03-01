import SwiftUI
import UIKit

struct OnboardingHost: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedProviderID") private var selectedProviderID = ""
    @AppStorage("appLanguage") private var appLanguage = "system"
    @EnvironmentObject private var registry: ProviderRegistry
    @EnvironmentObject private var stampStore: StampStore

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var overrideLocale: Locale? {
        switch appLanguage {
        case "en": Locale(identifier: "en")
        case "fr": Locale(identifier: "fr")
        default: nil
        }
    }

    private var providerAccentColor: Color? {
        guard hasCompletedOnboarding, !selectedProviderID.isEmpty else { return nil }
        guard let color = (registry.provider(id: selectedProviderID) as? any OnboardingCityProvider)?.brandColor else { return nil }
        let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let background = Color(uiColor: UIColor.systemBackground.resolvedColor(with: traits))
        return color.withAdequateContrast(against: background)
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
        .environment(\.locale, overrideLocale ?? .current)
        .tint(providerAccentColor)
        .task {
            registry.register(SantanderCyclesProvider())
            registry.register(CitiBikeProvider())
            registry.register(VelibProvider())
            stampStore.loadDefinitions(from: registry)
        }
        .onAppear {
            #if DEBUG
            Task { await TestSuite.run() }
            #endif
        }
    }
}
