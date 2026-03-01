import SwiftUI

/// Empty state for search panel: BikeMap illustration + flavour text when there is no search history.
struct SearchEmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var bikeMapImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            if let img = bikeMapImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                Text(NSLocalizedString("search_empty_headline", bundle: .localized, comment: "Search empty state headline"))
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("search_empty_body", bundle: .localized, comment: "Search empty state body"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .onAppear { loadBikeMapImage() }
        .onChange(of: colorScheme) { _, _ in loadBikeMapImage() }
    }

    private func loadBikeMapImage() {
        let pngName = colorScheme == .dark ? "BikeMapDark" : "BikeMapLight"
        bikeMapImage = UIImage(named: pngName)

        guard let url = Bundle.main.url(forResource: "BikeMap", withExtension: "svg"),
              var svg = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        svg = svg.replacingOccurrences(
            of: "width=\"222\" height=\"107\"",
            with: #"width="100%" height="100%""#)

        // No background rect — keep image background transparent so it blends with the sheet.

        if colorScheme == .dark {
            svg = svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        SVGLoader.load(data: data, url: nil, size: CGSize(width: 444, height: 214)) { image in
            if let image {
                bikeMapImage = image
            }
        }
    }
}
