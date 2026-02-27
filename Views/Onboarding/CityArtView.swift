import SwiftUI
import WebKit

// MARK: - WebKit process warmer

/// Keeps a pre-loaded WKWebView alive so the WebKit content process is already running
/// by the time CitySelectScreen creates its cards. Call prewarm() from OnboardingFlow.
@MainActor
final class SVGWebViewWarmer {
    static let shared = SVGWebViewWarmer()
    private var warmers: [WKWebView] = []

    func prewarm(svgName: String) {
        guard !warmers.contains(where: { $0.tag == svgName.hashValue }),
              let url = Bundle.main.url(forResource: svgName, withExtension: "svg"),
              let svgString = try? String(contentsOf: url, encoding: .utf8) else { return }
        let wv = SVGCityView.makeConfiguredWebView()
        wv.tag = svgName.hashValue
        wv.loadHTMLString(SVGCityView.buildHTML(svgString: svgString, accentHex: nil), baseURL: Bundle.main.bundleURL)
        warmers.append(wv)
    }
}

// MARK: - SVGCityView

struct SVGCityView: UIViewRepresentable {
    let svgName: String
    let accentColor: Color?  // nil = white skyline (unselected)
    var onFailure: (() -> Void)? = nil

    // MARK: Static helpers (used by warmer and representable)

    static func makeConfiguredWebView() -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isUserInteractionEnabled = false
        return webView
    }

    static func buildHTML(svgString: String, accentHex: String?) -> String {
        var svg = svgString
        if let hex = accentHex {
            svg = svg.replacingOccurrences(
                of: #"fill="white" id="city-skyline""#,
                with: "fill=\"\(hex)\" id=\"city-skyline\""
            )
        }
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="color-scheme" content="light dark">
        <style>
        :root { color-scheme: light dark; }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: transparent; }
        svg { width: 100%; height: auto; display: block; }
        /* Adapt SVG colours to the system colour scheme.
           Canvas/CanvasText are CSS system colours that flip automatically
           when the device switches between light and dark mode — no reload needed. */
        path[fill="white"] { fill: Canvas; }
        rect[fill="white"] { fill: Canvas; }
        path[stroke="black"] { stroke: CanvasText; }
        circle[stroke="black"] { stroke: CanvasText; }
        path[fill="black"] { fill: CanvasText; }
        </style>
        </head>
        <body>\(svg)</body>
        </html>
        """
    }

    // MARK: Coordinator — tracks last-loaded state to skip redundant reloads

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastSVGName: String?
        var lastAccentHex: String?
        var onFailure: (() -> Void)?

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onFailure?()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onFailure?()
        }
    }

    func makeCoordinator() -> Coordinator {
        let c = Coordinator()
        c.onFailure = onFailure
        return c
    }

    // MARK: UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let webView = Self.makeConfiguredWebView()
        webView.navigationDelegate = context.coordinator
        let accentHex = accentColor?.toHex()
        guard let url = Bundle.main.url(forResource: svgName, withExtension: "svg"),
              let svgString = try? String(contentsOf: url, encoding: .utf8) else {
            onFailure?()
            return webView
        }
        // Start loading immediately so rendering is underway before the view is on screen
        webView.loadHTMLString(Self.buildHTML(svgString: svgString, accentHex: accentHex), baseURL: Bundle.main.bundleURL)
        context.coordinator.lastSVGName = svgName
        context.coordinator.lastAccentHex = accentHex
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let accentHex = accentColor?.toHex()
        // Skip reload if nothing has changed (e.g. parent view re-renders for unrelated reasons)
        guard svgName != context.coordinator.lastSVGName
                || accentHex != context.coordinator.lastAccentHex else { return }
        context.coordinator.lastSVGName = svgName
        context.coordinator.lastAccentHex = accentHex
        guard let url = Bundle.main.url(forResource: svgName, withExtension: "svg"),
              let svgString = try? String(contentsOf: url, encoding: .utf8) else { return }
        webView.loadHTMLString(Self.buildHTML(svgString: svgString, accentHex: accentHex), baseURL: Bundle.main.bundleURL)
    }
}
