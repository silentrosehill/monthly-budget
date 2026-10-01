// Renders the app with the made-up budget in screenshots/demo.json and saves README screenshots.
// Usage: swift tools/screenshots.swift   (run from the project folder, after `python3 build.py`)
import Cocoa
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let page = root.appendingPathComponent("index.html")
let demo = try! String(contentsOf: root.appendingPathComponent("screenshots/demo.json"), encoding: .utf8)
let shots: [(file: String, theme: String, mode: String, tab: String)] = [
    ("classic-monthly", "classic", "auto", "monthly"),
    ("classic-daily", "classic", "auto", "daily"),
    ("glass-dark-monthly", "glass", "dark", "monthly"),
    ("glass-light-daily", "glass", "light", "daily"),
]
let size = NSSize(width: 1440, height: 930)
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)

final class Shooter: NSObject, WKNavigationDelegate {
    var queue = shots
    var window: NSWindow!
    var web: WKWebView!
    func next() {
        guard let shot = queue.first else { NSApp.terminate(nil); return }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let script = "window.__BUDGET__ = Object.assign(\(demo), { theme: '\(shot.theme)', mode: '\(shot.mode)', tab: '\(shot.tab)' });"
        config.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        web = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: config)
        web.appearance = NSAppearance(named: shot.mode == "dark" ? .darkAqua : .aqua)
        window = NSWindow(contentRect: NSRect(origin: NSPoint(x: -4000, y: 0), size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = web
        window.orderFrontRegardless()
        web.navigationDelegate = self
        web.loadFileURL(page, allowingReadAccessTo: root)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // off-screen windows don't get animation frames, so run the board layout directly
        webView.evaluateJavaScript("document.fonts.ready.then(() => { layout(); flowEl.classList.add('no-anim'); layout(); })")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let shot = self.queue.removeFirst()
            let cfg = WKSnapshotConfiguration(); cfg.snapshotWidth = 1440
            webView.takeSnapshot(with: cfg) { image, _ in
                if let image = image, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: root.appendingPathComponent("screenshots/\(shot.file).png"))
                    print("saved screenshots/\(shot.file).png")
                }
                self.window.orderOut(nil)
                self.next()
            }
        }
    }
}
let shooter = Shooter()
DispatchQueue.main.async { shooter.next() }
app.run()
