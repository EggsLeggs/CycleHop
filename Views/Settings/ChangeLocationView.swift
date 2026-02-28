import SwiftUI

struct ChangeLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedProviderID") private var selectedProviderID = ""
    @EnvironmentObject private var registry: ProviderRegistry
    @State private var selectedProvider: (any OnboardingCityProvider)?

    private var cityProviders: [any OnboardingCityProvider] {
        registry.providers.compactMap { $0 as? any OnboardingCityProvider }
    }

    var body: some View {
        CitySelectScreen(providers: cityProviders, selectedProvider: $selectedProvider) {
            if let p = selectedProvider {
                selectedProviderID = p.id
            }
            dismiss()
        }
    }
}
