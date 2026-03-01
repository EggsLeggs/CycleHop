import SwiftUI

struct ChangeLocationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedProviderID") private var selectedProviderID = ""
    @AppStorage("locationChangeTrigger") private var locationChangeTrigger = 0
    @EnvironmentObject private var registry: ProviderRegistry
    @State private var selectedProvider: (any OnboardingCityProvider)?

    private var cityProviders: [any OnboardingCityProvider] {
        registry.providers
            .compactMap { $0 as? any OnboardingCityProvider }
            .sorted { $0.cityDisplayName.localizedCaseInsensitiveCompare($1.cityDisplayName) == .orderedAscending }
    }

    var body: some View {
        CitySelectScreen(providers: cityProviders, selectedProvider: $selectedProvider) {
            if let p = selectedProvider {
                selectedProviderID = p.id
            }
            locationChangeTrigger += 1
            dismiss()
        }
    }
}
