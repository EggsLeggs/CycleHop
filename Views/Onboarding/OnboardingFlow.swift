import SwiftUI

struct OnboardingFlow: View {
    let onComplete: (String) -> Void

    @State private var path = NavigationPath()
    @State private var selectedProvider: (any OnboardingCityProvider)?
    @EnvironmentObject private var registry: ProviderRegistry

    private var cityProviders: [any OnboardingCityProvider] {
        registry.providers.compactMap { $0 as? any OnboardingCityProvider }
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
                        if let provider = selectedProvider {
                            onComplete(provider.id)
                        }
                    }
                default:
                    EmptyView()
                }
            }
        }
        .onAppear {
            // Spawn the WebKit content process early so city card SVGs load instantly
            for provider in cityProviders {
                if let svgName = provider.cityArtSVGName {
                    SVGWebViewWarmer.shared.prewarm(svgName: svgName)
                }
            }
        }
    }
}
