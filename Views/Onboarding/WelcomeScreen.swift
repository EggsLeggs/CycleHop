import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var splashImage: UIImage?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.gray.opacity(0.15))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CycleHop")
                        .font(.title.bold())

                    Text("The open bike-share network.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)

                Spacer()

                if let img = splashImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingContinueButton("Get Started") {
                onContinue()
            }
            .padding(.bottom, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { loadSplash() }
        .onChange(of: colorScheme) { loadSplash() }
    }

    private func loadSplash() {
        // Set PNG immediately — works everywhere, including Swift Playgrounds where
        // WKWebView may never fire its completion handler
        let pngName = colorScheme == .dark ? "MainSplashDark" : "MainSplashLight"
        splashImage = UIImage(named: pngName)

        // Attempt to upgrade to a crisp SVG render (Xcode / full WebKit only)
        guard let url = Bundle.main.url(forResource: "MainSplash", withExtension: "svg"),
              var svg = try? String(contentsOf: url, encoding: .utf8) else { return }

        svg = svg.replacingOccurrences(of: "width=\"403\" height=\"570\"",
                                       with: "width=\"100%\" height=\"100%\"")

        // Invert line colours for dark mode — no background rect so the view's
        // grey background shows through the transparent SVG canvas
        if colorScheme == .dark {
            svg = svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        // Use the SVG's natural size — WKWebView captures at UIScreen.main.scale
        // so the resulting UIImage is already Retina-resolution
        SVGLoader.load(data: data, url: nil, size: CGSize(width: 403, height: 570)) { image in
            if let image {
                splashImage = image  // upgrade to sharp SVG render
            }
            // if nil or never called, the PNG set above remains
        }
    }
}
