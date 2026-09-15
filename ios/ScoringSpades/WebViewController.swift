import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
  private var webView: WKWebView!

  override func loadView() {
    let config = WKWebViewConfiguration()
    config.setURLSchemeHandler(BundledAssetSchemeHandler(), forURLScheme: BundledAssetSchemeHandler.scheme)
    config.websiteDataStore = .default()  // persistent localStorage

    webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.allowsBackForwardNavigationGestures = true  // swipe back from How to Play / Privacy
    webView.allowsLinkPreview = false
    webView.isOpaque = false
    webView.backgroundColor = UIColor(named: "LaunchBackground")
    webView.scrollView.backgroundColor = webView.backgroundColor
    webView.scrollView.contentInsetAdjustmentBehavior = .never
    #if DEBUG
    webView.isInspectable = true
    #endif
    view = webView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    webView.load(URLRequest(url: BundledAssetSchemeHandler.startURL))
  }

  // MARK: - Navigation

  /// Bundled pages load in place; anything else (GitHub, mailto:, Google
  /// policy links) opens in Safari or the relevant app.
  func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
               decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
    guard let url = action.request.url else { return decisionHandler(.cancel) }
    switch url.scheme {
    case BundledAssetSchemeHandler.scheme:
      if action.targetFrame == nil {  // target="_blank" to a bundled page
        webView.load(action.request)
        return decisionHandler(.cancel)
      }
      decisionHandler(.allow)
    case "about", "data", "blob":
      decisionHandler(.allow)
    default:
      if action.targetFrame?.isMainFrame != false { UIApplication.shared.open(url) }
      decisionHandler(.cancel)
    }
  }

  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
               for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    if let url = action.request.url { UIApplication.shared.open(url) }
    return nil
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    webView.reload()
  }

  // MARK: - alert() / confirm() / prompt()
  // WKWebView silently drops JS dialogs unless the host presents them.

  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
    present(alert, orElse: completionHandler)
  }

  func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
    present(alert, orElse: { completionHandler(false) })
  }

  func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
               defaultText: String?, initiatedByFrame frame: WKFrameInfo,
               completionHandler: @escaping @MainActor (String?) -> Void) {
    let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
    alert.addTextField { field in
      field.text = defaultText
      field.clearButtonMode = .whileEditing
      // Every prompt in the app asks for a number (target score, nil points…).
      if let defaultText, !defaultText.isEmpty, defaultText.allSatisfy(\.isNumber) {
        field.keyboardType = .numberPad
      }
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
    alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
      completionHandler(alert?.textFields?.first?.text ?? "")
    })
    present(alert, orElse: { completionHandler(nil) })
  }

  private func present(_ alert: UIAlertController, orElse fallback: @escaping () -> Void) {
    guard view.window != nil, presentedViewController == nil else { return fallback() }
    present(alert, animated: true)
  }
}
