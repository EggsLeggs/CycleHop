import SwiftUI

/// Loads and displays a stamp image by base name (Light/Dark variant from color scheme).
struct StampImageView: View {
    let stampPNGBaseName: String
    var size: CGFloat = 160
    var isDecorative: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var stampImage: UIImage?

    var body: some View {
        Group {
            if let img = stampImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Color.clear
                    .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(isDecorative)
        .onAppear { loadImage() }
        .onChange(of: colorScheme) { _, _ in loadImage() }
    }

    private func loadImage() {
        let scheme = colorScheme == .dark ? "Dark" : "Light"
        stampImage = UIImage(named: "\(stampPNGBaseName)\(scheme)")
    }
}
