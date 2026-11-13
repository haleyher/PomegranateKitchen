import SwiftUI
import WebKit

/// Shows the game (index.html, bundled with the app) full screen.
/// The page sends each haptic moment here by name, e.g.
///     window.webkit.messageHandlers.haptic.postMessage("pop")
/// and Haptics plays it with Core Haptics.
struct GameView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(context.coordinator, name: "haptic")

        let webView = WKWebView(frame: .zero, configuration: config)
        let counterColor = UIColor(red: 21 / 255, green: 18 / 255, blue: 19 / 255, alpha: 1)
        webView.isOpaque = false
        webView.backgroundColor = counterColor
        webView.scrollView.backgroundColor = counterColor
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        #if DEBUG
        // Debug the page from Safari on your Mac: Develop menu > your iPhone > index.html
        webView.isInspectable = true
        #endif

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "haptic")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        private let haptics = Haptics()

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if let name = message.body as? String {
                haptics.play(name)
            }
        }
    }
}
