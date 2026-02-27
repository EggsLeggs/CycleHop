import SwiftUI

struct CityCard: View {
    let provider: any OnboardingCityProvider
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var svgFailed = false

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
                    SVGCityView(
                        svgName: svgName,
                        accentColor: isSelected ? provider.brandColor : nil,
                        onFailure: { svgFailed = true }
                    )
                    .background(Color(.systemBackground))
                    .aspectRatio(412.0 / 237.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                } else {
                    // Fallback gradient placeholder
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
    }
}
