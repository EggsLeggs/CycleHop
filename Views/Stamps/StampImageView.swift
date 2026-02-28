import SwiftUI

struct StampImageView: View {
    let stampPNGBaseName: String
    var size: CGFloat = 160

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
        .onAppear { loadImage() }
        .onChange(of: colorScheme) { _, _ in loadImage() }
    }

    private func loadImage() {
        let scheme = colorScheme == .dark ? "Dark" : "Light"
        stampImage = UIImage(named: "\(stampPNGBaseName)\(scheme)")
    }
}
