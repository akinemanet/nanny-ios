import SwiftUI
import WebKit

struct CheckoutView: UIViewRepresentable {
    let url: URL
    var onCompletion: ((CheckoutCompletion) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        if webView.url == nil || webView.url != url {
            webView.load(request)
        }
    }
}

final class Coordinator: NSObject, WKNavigationDelegate {
    private let onCompletion: ((CheckoutCompletion) -> Void)?
    private var didComplete = false

    init(onCompletion: ((CheckoutCompletion) -> Void)?) {
        self.onCompletion = onCompletion
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url {
            handle(url: url)
        }
        return .allow
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            handle(url: url)
        }
    }

    private func handle(url: URL) {
        guard !didComplete else { return }
        guard let result = CheckoutCompletionDetector.completion(for: url) else { return }
        didComplete = true
        DispatchQueue.main.async { [onCompletion] in
            onCompletion?(result)
        }
    }
}
