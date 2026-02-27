import SwiftUI

struct AboutScreen: View {
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var splashImage: UIImage?

    private var useLong: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    if let img = splashImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    } else {
                        Color(.systemBackground)
                            .aspectRatio(useLong ? 183.0 / 117.0 : 224.0 / 217.0, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Find bikes, find places to go.")
                        .font(.title2.bold())

                    Text(
                        "CycleHop helps you discover nearby bike-share docking stations so you can get moving quickly — whether you're commuting, exploring, or just running errands."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)

                    Text("Open Protocol")
                        .font(.headline)
                        .padding(.top, 8)

                    Text(
                        "CycleHop is built on open standards. Anyone can contribute a new city or provider."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)

                    Link(
                        "View on GitHub →",
                        destination: URL(string: "https://github.com/cyclehop/cyclehop")!
                    )
                    .font(.body.bold())
                    .tint(.blue)

                    Text("Together, we're making cycling data more accessible — globally.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .navigationTitle("The Mission")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                OnboardingContinueButton("Continue") {
                    onContinue()
                }
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
        .onAppear { loadSplash() }
        .onChange(of: colorScheme) { loadSplash() }
        .onChange(of: horizontalSizeClass) { loadSplash() }
    }

    private func loadSplash() {
        // Set PNG immediately — works everywhere, including Swift Playgrounds where
        // WKWebView may never fire its completion handler
        let pngName = useLong
            ? (colorScheme == .dark ? "ParisSplashLongDark" : "ParisSplashLongLight")
            : (colorScheme == .dark ? "ParisSplashDark" : "ParisSplashLight")
        splashImage = UIImage(named: pngName)

        // Attempt to upgrade to a crisp SVG render (Xcode / full WebKit only)
        let svgName = useLong ? "ParisSplashLong" : "ParisSplash"
        let (svgW, svgH) = useLong ? ("183", "117") : ("224", "217")
        guard let url = Bundle.main.url(forResource: svgName, withExtension: "svg"),
              var svg = try? String(contentsOf: url, encoding: .utf8) else { return }

        // Scale SVG to fill the WebView frame exactly
        svg = svg.replacingOccurrences(of: "width=\"\(svgW)\" height=\"\(svgH)\"",
                                       with: #"width="100%" height="100%""#)

        // Inject a solid background rect as the first child so the snapshot is opaque
        let bgHex = colorScheme == .dark ? "#000000" : "#FFFFFF"
        if let insertAt = svg.range(of: ">")?.upperBound {
            svg.insert(contentsOf: "<rect width=\"100%\" height=\"100%\" fill=\"\(bgHex)\"/>",
                       at: insertAt)
        }

        // Invert line colours for dark mode
        if colorScheme == .dark {
            svg = svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        // 3× the SVG's natural size for sharp rendering at any display scale
        let renderSize = useLong ? CGSize(width: 549, height: 351) : CGSize(width: 672, height: 651)
        SVGLoader.load(data: data, url: nil, size: renderSize) { image in
            if let image {
                splashImage = image  // upgrade to sharp SVG render
            }
            // if nil or never called, the PNG set above remains
        }
    }
}
