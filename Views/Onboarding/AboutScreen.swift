import SwiftUI

struct AboutScreen: View {
    let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var splashImage: UIImage?
    @State private var bikeMapImage: UIImage?
    @State private var stampImage: UIImage?
    @State private var githubImage: UIImage?
    @State private var stampOpacity: Double = 1.0
    @State private var currentStampName = "LondonStamp"

    private let stampNames = ["LondonStamp", "NewYorkStamp", "ParisStamp"]

    /// Shared size for section preview images (map and stamps) so they match.
    private let sectionImageHeight: CGFloat = 72

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
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Find bikes, wherever you go.")
                        .font(.title2.bold())

                    Text(
                        "Find bikes and docks wherever you are. CycleHop connects to bike-share systems worldwide to get you moving - whether you're commuting, exploring, or running errands."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)

                    if let img = bikeMapImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: sectionImageHeight * 1.6)
                            .opacity(0.5)
                            .accessibilityHidden(true)
                    }

                    Text("Bikes Across Your City")
                        .font(.headline)

                    Text(
                        "See stations and availability on a map. Tap any dock to check bikes and free slots in real time, so you always know where to go."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)

                    if let img = stampImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: sectionImageHeight)
                            .opacity(0.5 * stampOpacity)
                            .padding(.top, 8)
                            .accessibilityHidden(true)
                            .onTapGesture {
                                let others = stampNames.filter { $0 != currentStampName }
                                guard let next = others.randomElement() else { return }
                                if reduceMotion {
                                    currentStampName = next
                                    loadStampImage()
                                } else {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        stampOpacity = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        currentStampName = next
                                        loadStampImage()
                                        withAnimation(.easeIn(duration: 0.2)) {
                                            stampOpacity = 1.0
                                        }
                                    }
                                }
                            }
                    }

                    Text("Collect City Stamps")
                        .font(.headline)

                    Text(
                        "Use bike share in a city and collect a stamp. Build your collection as you explore - each city you ride in leaves its mark."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)

                    if let img = githubImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: sectionImageHeight * 1.6)
                            .opacity(0.5)
                            .accessibilityHidden(true)
                    }

                    Text("Open Protocol")
                        .font(.headline)

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
        .onAppear {
            loadSplash()
            loadBikeMapImage()
            loadStampImage()
            loadGithubImage()
        }
        .onChange(of: colorScheme) {
            loadSplash()
            loadBikeMapImage()
            loadStampImage()
            loadGithubImage()
        }
        .onChange(of: horizontalSizeClass) { loadSplash() }
    }

    private func loadSplash() {
        // Set PNG immediately — works everywhere, including Swift Playgrounds where
        // WKWebView may never fire its completion handler
        let pngName =
            useLong
            ? (colorScheme == .dark ? "ParisSplashLongDark" : "ParisSplashLongLight")
            : (colorScheme == .dark ? "ParisSplashDark" : "ParisSplashLight")
        splashImage = UIImage(named: pngName)

        // Attempt to upgrade to a crisp SVG render (Xcode / full WebKit only)
        let svgName = useLong ? "ParisSplashLong" : "ParisSplash"
        let (svgW, svgH) = useLong ? ("183", "117") : ("224", "217")
        guard let url = Bundle.main.url(forResource: svgName, withExtension: "svg"),
            var svg = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        // Scale SVG to fill the WebView frame exactly
        svg = svg.replacingOccurrences(
            of: "width=\"\(svgW)\" height=\"\(svgH)\"",
            with: #"width="100%" height="100%""#)

        // Inject a solid background rect as the first child so the snapshot is opaque
        let bgHex = colorScheme == .dark ? "#000000" : "#FFFFFF"
        if let insertAt = svg.range(of: ">")?.upperBound {
            svg.insert(
                contentsOf: "<rect width=\"100%\" height=\"100%\" fill=\"\(bgHex)\"/>",
                at: insertAt)
        }

        // Invert line colours for dark mode
        if colorScheme == .dark {
            svg =
                svg
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

    private func loadBikeMapImage() {
        // Set PNG immediately — works everywhere, including Swift Playgrounds where
        // WKWebView may never fire its completion handler
        let pngName = colorScheme == .dark ? "BikeMapDark" : "BikeMapLight"
        bikeMapImage = UIImage(named: pngName)

        // Attempt to upgrade to a crisp SVG render (Xcode / full WebKit only)
        guard let url = Bundle.main.url(forResource: "BikeMap", withExtension: "svg"),
            var svg = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        svg = svg.replacingOccurrences(
            of: "width=\"222\" height=\"107\"",
            with: #"width="100%" height="100%""#)

        // Inject a solid background rect as the first child so the snapshot is opaque
        let bgHex = colorScheme == .dark ? "#000000" : "#FFFFFF"
        if let insertAt = svg.range(of: ">")?.upperBound {
            svg.insert(
                contentsOf: "<rect width=\"100%\" height=\"100%\" fill=\"\(bgHex)\"/>",
                at: insertAt)
        }

        // Invert line colours for dark mode
        if colorScheme == .dark {
            svg =
                svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        // 3× the SVG's natural size for sharp rendering at any display scale
        SVGLoader.load(data: data, url: nil, size: CGSize(width: 666, height: 321)) { image in
            if let image {
                bikeMapImage = image  // upgrade to sharp SVG render
            }
            // if nil or never called, the PNG set above remains
        }
    }

    private func loadStampImage() {
        // PNG-only: stamps are small and SVGLoader's shared WKWebView gets sized by
        // the larger splash render, producing wrong-dimension snapshots for small SVGs.
        let pngName = colorScheme == .dark ? "\(currentStampName)Dark" : "\(currentStampName)Light"
        stampImage = UIImage(named: pngName)
    }

    private func loadGithubImage() {
        // Set PNG immediately — works everywhere, including Swift Playgrounds where
        // WKWebView may never fire its completion handler
        let pngName = colorScheme == .dark ? "GithubIllustrationDark" : "GithubIllustrationLight"
        githubImage = UIImage(named: pngName)

        // Attempt to upgrade to a crisp SVG render (Xcode / full WebKit only)
        guard let url = Bundle.main.url(forResource: "GithubIllustration", withExtension: "svg"),
            var svg = try? String(contentsOf: url, encoding: .utf8)
        else { return }

        svg = svg.replacingOccurrences(
            of: "width=\"147\" height=\"83\"",
            with: "width=\"100%\" height=\"100%\"")

        let bgHex = colorScheme == .dark ? "#000000" : "#FFFFFF"
        if let insertAt = svg.range(of: ">")?.upperBound {
            svg.insert(
                contentsOf: "<rect width=\"100%\" height=\"100%\" fill=\"\(bgHex)\"/>",
                at: insertAt)
        }

        if colorScheme == .dark {
            svg =
                svg
                .replacingOccurrences(of: "stroke=\"black\"", with: "stroke=\"white\"")
                .replacingOccurrences(of: "fill=\"black\"", with: "fill=\"white\"")
        }

        guard let data = svg.data(using: .utf8) else { return }

        SVGLoader.load(data: data, url: nil, size: CGSize(width: 441, height: 249)) { image in
            if let image {
                githubImage = image  // upgrade to sharp SVG render
            }
            // if nil or never called, the PNG set above remains
        }
    }
}
