import SwiftUI

/// Empty state using NotFound.svg + fallbacks with custom headline and body (e.g. offline or no results).
struct SearchNotFoundView: View {
    let headlineKey: String
    let bodyKey: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var notFoundImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            if let img = notFoundImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(0.65)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                Text(NSLocalizedString(headlineKey, bundle: .localized, comment: ""))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString(bodyKey, bundle: .localized, comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .onAppear { loadNotFoundImage() }
        .onChange(of: colorScheme) { _, _ in loadNotFoundImage() }
    }

    private func loadNotFoundImage() {
        let pngName = colorScheme == .dark ? "NotFoundDark" : "NotFoundLight"
        notFoundImage = UIImage(named: pngName)

        guard let url = Bundle.main.url(forResource: "NotFound", withExtension: "svg"),
              var svg = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        svg = svg.replacingOccurrences(
            of: "width=\"134\" height=\"96\"",
            with: "width=\"100%\" height=\"100%\"")

        if colorScheme == .dark {
            svg = svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        SVGLoader.load(data: data, url: nil, size: CGSize(width: 402, height: 288)) { image in
            if let image {
                notFoundImage = image
            }
        }
    }
}
