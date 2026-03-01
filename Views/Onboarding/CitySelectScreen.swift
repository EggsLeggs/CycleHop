import SwiftUI

/// City picker: list of CityCards, "Don't see your city?" fallback, Continue.
struct CitySelectScreen: View {
    let providers: [any OnboardingCityProvider]
    @Binding var selectedProvider: (any OnboardingCityProvider)?
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var notFoundImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(
                    "This is a demo for the Apple Student Challenge. As the app is required to work offline, the data is an offline snapshot and location services are mocked. Online implementations are available on GitHub."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

                VStack(spacing: 16) {
                    ForEach(providers, id: \.id) { provider in
                        CityCard(
                            provider: provider,
                            isSelected: selectedProvider?.id == provider.id,
                            onSelect: {
                                if selectedProvider?.id == provider.id {
                                    selectedProvider = nil
                                } else {
                                    selectedProvider = provider
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    if let img = notFoundImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 84)
                            .opacity(0.5)
                            .accessibilityHidden(true)
                    }

                    Text("Don't see your city?")
                        .font(.footnote.bold())
                        .foregroundStyle(.secondary)

                    Text(
                        "CycleHop is open-source - anyone can request a new city or help add one, no coding skills needed."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                    Link(
                        "EggsLeggs/CycleHop on GitHub →",
                        destination: URL(string: "https://github.com/EggsLeggs/CycleHop")!
                    )
                    .font(.footnote.bold())
                    .tint(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .navigationTitle("Choose Your City")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                OnboardingContinueButton(
                    "Continue",
                    isEnabled: selectedProvider != nil
                ) {
                    onContinue()
                }
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
        .onAppear { loadNotFoundImage() }
        .onChange(of: colorScheme) { loadNotFoundImage() }
    }

    private func loadNotFoundImage() {
        // Set PNG immediately: works everywhere, including Swift Playgrounds where
        // WKWebView may never fire its completion handler
        let pngName = colorScheme == .dark ? "NotFoundDark" : "NotFoundLight"
        notFoundImage = UIImage(named: pngName)

        // Attempt to upgrade to a crisp SVG render (Xcode / full WebKit only)
        guard let url = Bundle.main.url(forResource: "NotFound", withExtension: "svg"),
            var svg = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        svg = svg.replacingOccurrences(
            of: "width=\"134\" height=\"96\"",
            with: "width=\"100%\" height=\"100%\"")

        // Invert line colours for dark mode
        if colorScheme == .dark {
            svg =
                svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        // 3× the SVG's natural size for sharp rendering at any display scale
        SVGLoader.load(data: data, url: nil, size: CGSize(width: 402, height: 288)) { image in
            if let image {
                notFoundImage = image  // upgrade to sharp SVG render
            }
            // if nil or never called, the PNG set above remains
        }
    }

}
