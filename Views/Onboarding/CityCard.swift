import SwiftUI

struct CityCard: View {
    let provider: any OnboardingCityProvider
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var svgFailed = false
    @State private var fallbackImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.cityDisplayName)
                            .font(.headline)
                            .foregroundStyle(isSelected ? provider.brandForegroundColor : .primary)

                        Text(provider.systemDisplayName)
                            .font(.subheadline)
                            .foregroundStyle(isSelected ? provider.brandForegroundColor.opacity(0.7) : .secondary)
                    }

                    Spacer()
                }
                .padding(12)

                if let svgName = provider.cityArtSVGName, !svgFailed {
                    ZStack {
                        // PNG set immediately — visible in Swift Playgrounds where
                        // WKWebView renders blank without firing a failure callback
                        if let img = fallbackImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color(.systemBackground)
                        }
                        // SVGCityView sits on top; renders crisply in Xcode, transparent in Playgrounds
                        SVGCityView(
                            svgName: svgName,
                            accentColor: isSelected ? provider.brandColor : nil,
                            onFailure: { svgFailed = true }
                        )
                    }
                    .aspectRatio(412.0 / 237.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .allowsHitTesting(false)
                } else if let img = fallbackImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(412.0 / 237.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .allowsHitTesting(false)
                } else {
                    // Last-resort gradient placeholder
                    ZStack {
                        LinearGradient(
                            colors: [provider.brandColor, provider.brandColor.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: "bicycle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .aspectRatio(412.0 / 237.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(isSelected ? provider.brandColor : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.label), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(0.06),
                radius: 4
            )
        }
        .buttonStyle(.plain)
        .onAppear { loadFallbackImage() }
        .onChange(of: colorScheme) { loadFallbackImage() }
        .onChange(of: isSelected) { loadFallbackImage() }
    }

    private func loadFallbackImage() {
        // Set PNG immediately — works everywhere, including Swift Playgrounds where
        // WKWebView may render blank without firing its failure callback
        guard let base = provider.cityArtPNGBaseName else { return }
        let scheme = colorScheme == .dark ? "Dark" : "Light"
        let highlight = isSelected ? "Highlighted" : ""
        fallbackImage = UIImage(named: "\(base)\(scheme)\(highlight)")
    }
}
