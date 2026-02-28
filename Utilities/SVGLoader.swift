import Foundation
import WebKit

class SVGLoader {
    typealias wkType = (data: Data, complition: ((UIImage?) -> Void)?, url: String?)
    static var wkContainer = [wkType]()
    static var wView: WKView?
    static func load(data: Data, url: String?, size: CGSize = CGSize(width: 600, height: 600), complition: @escaping ((UIImage?) -> Void)) {
        let wkData: wkType = (data, complition, url)
        wkContainer.append(wkData)
        if wView == nil {
            wView = WKView(frame: CGRect(origin: .zero, size: size))
        }
    }

    static func clean() {
        if wkContainer.isEmpty {
            wView = nil
        }
    }

    class WKView: NSObject, WKNavigationDelegate {
        var webKitView: WKWebView?
        init(frame: CGRect) {
            super.init()
            webKitView = WKWebView(frame: frame)
            webKitView?.navigationDelegate = self
            webKitView?.contentScaleFactor = UIScreen.main.scale
            webKitView?.isOpaque = false
            webKitView?.backgroundColor = .clear
            webKitView?.scrollView.backgroundColor = .clear
            loadData()
        }

        func loadData() {
            let datas = SVGLoader.wkContainer
            if datas.isEmpty { return }
            guard let data = datas.first?.data else { return }
            let urlS = datas.first?.url ?? ""
            let url = URL(string: urlS) ?? (NSURL(string: "")! as URL)
            webKitView?.load(data, mimeType: "image/svg", characterEncodingName: "", baseURL: url)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.takeSnapshot(with: nil) { [weak self] image, error in
                wkContainer.first?.complition?(image)
                wkContainer.removeFirst()
                self?.loadData()
                clean()
            }
        }
    }
}
