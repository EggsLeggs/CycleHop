import SwiftUI

/// Navigation flow: welcome, about, city select, map style, then completion.
struct OnboardingFlow: View {
    let onComplete: (String) -> Void

    @State private var path = NavigationPath()
    @State private var selectedProvider: (any OnboardingCityProvider)?
    @EnvironmentObject private var registry: ProviderRegistry

    private var cityProviders: [any OnboardingCityProvider] {
        registry.providers
            .compactMap { $0 as? any OnboardingCityProvider }
            .sorted { $0.cityDisplayName.localizedCaseInsensitiveCompare($1.cityDisplayName) == .orderedAscending }
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeScreen {
                path.append("about")
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "about":
                    AboutScreen {
                        path.append("citySelect")
                    }
                case "citySelect":
                    CitySelectScreen(
                        providers: cityProviders,
                        selectedProvider: $selectedProvider
                    ) {
                        if selectedProvider != nil {
                            path.append("mapStyle")
                        }
                    }
                case "mapStyle":
                    MapStyleScreen(
                        providerID: selectedProvider?.id ?? "",
                        onComplete: onComplete
                    )
                default:
                    EmptyView()
                }
            }
        }
        .onAppear {
            // Prewarm WebKit so city card SVGs load quickly
            for provider in cityProviders {
                if let svgName = provider.cityArtSVGName {
                    SVGWebViewWarmer.shared.prewarm(svgName: svgName)
                }
            }
        }
    }
}
