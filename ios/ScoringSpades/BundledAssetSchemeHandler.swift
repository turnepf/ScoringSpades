import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves the web app in `public/` (copied into the bundle at build time) from
/// `scoringspades://app/…`. A real origin — rather than file:// — keeps the
/// site's root-relative links (`/how-to-play`, `/privacy`) and localStorage
/// working exactly as they do on scoringspades.com.
final class BundledAssetSchemeHandler: NSObject, WKURLSchemeHandler {
  static let scheme = "scoringspades"
  static let startURL = URL(string: "\(scheme)://app/")!

  private let root = Bundle.main.resourceURL!
    .appendingPathComponent("public", isDirectory: true)
    .standardizedFileURL

  func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
    guard let url = task.request.url else {
      return task.didFailWithError(URLError(.badURL))
    }

    // Same routing as Cloudflare static assets: "/" → index.html,
    // extensionless paths → .html.
    var path = url.path
    if path.isEmpty || path == "/" { path = "/index.html" }
    var file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL
    if file.pathExtension.isEmpty { file.appendPathExtension("html") }

    guard file.path.hasPrefix(root.path + "/"), var data = try? Data(contentsOf: file) else {
      return respond(task, url: url, status: 404, mime: "text/plain", data: Data("Not found".utf8))
    }

    // No analytics in the app: games never leave the device.
    if path == "/config.js" {
      data.append(Data("\nwindow.SCORING_CONFIG.gaId = '';\n".utf8))
    }

    let mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    respond(task, url: url, status: 200, mime: mime, data: data)
  }

  func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}

  private func respond(_ task: any WKURLSchemeTask, url: URL, status: Int, mime: String, data: Data) {
    let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: [
      "Content-Type": mime.hasPrefix("text/") || mime.hasSuffix("javascript") ? "\(mime); charset=utf-8" : mime,
      "Content-Length": String(data.count),
      "Cache-Control": "no-cache",
    ])!
    task.didReceive(response)
    task.didReceive(data)
    task.didFinish()
  }
}
