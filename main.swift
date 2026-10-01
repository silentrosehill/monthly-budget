import Cocoa
import WebKit
import CoreImage

let dataDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("Monthly Budget", isDirectory: true)
let dataFile = dataDir.appendingPathComponent("budget.json")

// Daily backups in "Monthly Budget/Backups" (the 14 most recent days are kept),
// and recovery from the newest good backup if the data file is ever unreadable
let backupDir = dataDir.appendingPathComponent("Backups", isDirectory: true)
func isReadableBudget(_ url: URL) -> Data? {
    guard let d = try? Data(contentsOf: url), (try? JSONSerialization.jsonObject(with: d)) is [String: Any] else { return nil }
    return d
}
func backupsNewestFirst() -> [URL] {
    ((try? FileManager.default.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: nil)) ?? [])
        .filter { $0.lastPathComponent.hasPrefix("budget-") && $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent > $1.lastPathComponent }
}
func loadBudgetWithRecovery() -> Data? {
    let fm = FileManager.default
    if let d = isReadableBudget(dataFile) { return d }
    guard fm.fileExists(atPath: dataFile.path) else { return nil }
    let stamp = Int(Date().timeIntervalSince1970)
    try? fm.moveItem(at: dataFile, to: dataDir.appendingPathComponent("budget.unreadable-\(stamp).json"))
    for b in backupsNewestFirst() {
        if let d = isReadableBudget(b) { try? d.write(to: dataFile, options: .atomic); return d }
    }
    return nil
}
func makeDailyBackup() {
    let fm = FileManager.default
    guard isReadableBudget(dataFile) != nil else { return }
    try? fm.createDirectory(at: backupDir, withIntermediateDirectories: true)
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
    let dest = backupDir.appendingPathComponent("budget-\(f.string(from: Date())).json")
    if isReadableBudget(dest) == nil { try? fm.removeItem(at: dest); try? fm.copyItem(at: dataFile, to: dest) }
    for old in backupsNewestFirst().dropFirst(14) { try? fm.removeItem(at: old) }
}

final class SaveHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let json = message.body as? String else { return }
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        try? json.data(using: .utf8)?.write(to: dataFile, options: .atomic)
    }
}

// ---------- Classic picture frame ----------
// Oak texture: stretched noise gives long grain streaks, a soft displacement makes them wave
func oakTexture(length: Int, thickness: Int, vertical: Bool) -> CGImage {
    let ci = CIContext()
    let rect = vertical ? CGRect(x: 0, y: 0, width: thickness, height: length) : CGRect(x: 0, y: 0, width: length, height: thickness)
    let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
    let along: CGFloat = 90, across: CGFloat = 1.6
    let streaks = noise.transformed(by: vertical ? CGAffineTransform(scaleX: across, y: along) : CGAffineTransform(scaleX: along, y: across))
        .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 0.8])
    let waves = noise.transformed(by: vertical ? CGAffineTransform(scaleX: 30, y: 260) : CGAffineTransform(scaleX: 260, y: 30))
        .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 10])
    let wavy = streaks.applyingFilter("CIDisplacementDistortion", parameters: [kCIInputImageKey: streaks, "inputDisplacementImage": waves, "inputScale": 22])
    let toned = wavy
        .applyingFilter("CIColorControls", parameters: ["inputSaturation": 0, "inputContrast": 1.7, "inputBrightness": -0.02])
        .applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(red: 0.37, green: 0.21, blue: 0.10),
            "inputColor1": CIColor(red: 0.76, green: 0.52, blue: 0.31)])
    return ci.createCGImage(toned.cropped(to: rect), from: rect)!
}

final class WoodFrameView: NSView {
    var top: CGFloat = 42, side: CGFloat = 20, bottom: CGFloat = 20
    private let horiz = oakTexture(length: 2200, thickness: 64, vertical: false)
    private let vert = oakTexture(length: 1600, thickness: 32, vertical: true)
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let g = NSGraphicsContext.current?.cgContext else { return }
        let W = bounds.width, H = bounds.height
        let inner = CGRect(x: side, y: top, width: W - 2 * side, height: H - top - bottom)
        let cs = CGColorSpaceCreateDeviceRGB()
        // Moulding profile across each band: bright rounded outer edge, darker toward the board
        let profile = CGGradient(colorsSpace: cs, colors: [
            CGColor(red: 1, green: 0.95, blue: 0.85, alpha: 0.30), CGColor(red: 1, green: 0.95, blue: 0.85, alpha: 0.05),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0.0), CGColor(red: 0.12, green: 0.05, blue: 0, alpha: 0.38)] as CFArray,
            locations: [0, 0.3, 0.55, 1])!

        func piece(_ pts: [CGPoint], image: CGImage, imageRect: CGRect, from: CGPoint, to: CGPoint) {
            g.saveGState()
            g.beginPath(); g.addLines(between: pts); g.closePath(); g.clip()
            g.draw(image, in: imageRect)
            g.drawLinearGradient(profile, start: from, end: to, options: [])
            g.restoreGState()
        }
        piece([CGPoint(x: 0, y: 0), CGPoint(x: W, y: 0), CGPoint(x: inner.maxX, y: inner.minY), CGPoint(x: inner.minX, y: inner.minY)],
              image: horiz, imageRect: CGRect(x: 0, y: 0, width: W, height: top), from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: top))
        piece([CGPoint(x: 0, y: H), CGPoint(x: W, y: H), CGPoint(x: inner.maxX, y: inner.maxY), CGPoint(x: inner.minX, y: inner.maxY)],
              image: horiz, imageRect: CGRect(x: 0, y: inner.maxY, width: W, height: bottom), from: CGPoint(x: 0, y: H), to: CGPoint(x: 0, y: inner.maxY))
        piece([CGPoint(x: 0, y: 0), CGPoint(x: inner.minX, y: inner.minY), CGPoint(x: inner.minX, y: inner.maxY), CGPoint(x: 0, y: H)],
              image: vert, imageRect: CGRect(x: 0, y: 0, width: side, height: H), from: CGPoint(x: 0, y: 0), to: CGPoint(x: side, y: 0))
        piece([CGPoint(x: W, y: 0), CGPoint(x: inner.maxX, y: inner.minY), CGPoint(x: inner.maxX, y: inner.maxY), CGPoint(x: W, y: H)],
              image: vert, imageRect: CGRect(x: inner.maxX, y: 0, width: side, height: H), from: CGPoint(x: W, y: 0), to: CGPoint(x: inner.maxX, y: 0))

        // Mitred joints at the corners
        g.setLineWidth(1)
        for (a, b) in [(CGPoint(x: 0, y: 0), CGPoint(x: inner.minX, y: inner.minY)), (CGPoint(x: W, y: 0), CGPoint(x: inner.maxX, y: inner.minY)),
                       (CGPoint(x: 0, y: H), CGPoint(x: inner.minX, y: inner.maxY)), (CGPoint(x: W, y: H), CGPoint(x: inner.maxX, y: inner.maxY))] {
            g.setStrokeColor(CGColor(red: 0.15, green: 0.07, blue: 0.02, alpha: 0.55)); g.strokeLineSegments(between: [a, b])
            g.setStrokeColor(CGColor(red: 1, green: 0.9, blue: 0.75, alpha: 0.18)); g.strokeLineSegments(between: [CGPoint(x: a.x + 1, y: a.y), CGPoint(x: b.x + 1, y: b.y)])
        }
        // Outer bevel highlight and the lip where the frame meets the cork
        g.setStrokeColor(CGColor(red: 1, green: 0.93, blue: 0.8, alpha: 0.35)); g.setLineWidth(1)
        g.stroke(bounds.insetBy(dx: 0.5, dy: 0.5))
        g.setStrokeColor(CGColor(red: 1, green: 0.9, blue: 0.75, alpha: 0.30)); g.stroke(inner.insetBy(dx: -2.5, dy: -2.5))
        g.setStrokeColor(CGColor(red: 0.16, green: 0.08, blue: 0.02, alpha: 0.85)); g.setLineWidth(2)
        g.stroke(inner.insetBy(dx: -1, dy: -1))
    }
}

final class ThemeHandler: NSObject, WKScriptMessageHandler {
    var apply: (String) -> Void = { _ in }
    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        if let t = message.body as? String { apply(t) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let saveHandler = SaveHandler()
    let themeHandler = ThemeHandler()
    var currentTheme = ""
    var web: WKWebView?

    func applicationDidFinishLaunching(_ n: Notification) {
        let controller = WKUserContentController()
        controller.add(saveHandler, name: "save")
        controller.add(themeHandler, name: "theme")
        var saved = "null"
        var startTheme = "glass"
        if let d = loadBudgetWithRecovery(), let s = String(data: d, encoding: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: d) {
            saved = s
            let dict = obj as? [String: Any]
            startTheme = ((dict?["theme"] as? String) ?? "glass") + ":" + ((dict?["mode"] as? String) ?? "auto")
        }
        makeDailyBackup()
        controller.addUserScript(WKUserScript(source: "window.__BUDGET__ = \(saved);",
                                              injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let config = WKWebViewConfiguration()
        config.userContentController = controller

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 860),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
        window.title = "Monthly Budget"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: 380, height: 500)
        window.setFrameAutosaveName("MonthlyBudgetWindow")

        let root = NSView()
        root.wantsLayer = true
        window.contentView = root
        func fill(_ v: NSView, top: CGFloat = 0) {
            v.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(v)
            NSLayoutConstraint.activate([
                v.topAnchor.constraint(equalTo: root.topAnchor, constant: top), v.bottomAnchor.constraint(equalTo: root.bottomAnchor),
                v.leadingAnchor.constraint(equalTo: root.leadingAnchor), v.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            ])
        }

        // Liquid Glass look: blur what's behind the window, then a green-tinted Liquid Glass layer on top
        let blur = NSVisualEffectView()
        blur.blendingMode = .behindWindow
        blur.material = .hudWindow
        blur.state = .active
        fill(blur)
        let glass = NSGlassEffectView()
        glass.style = .clear
        glass.cornerRadius = 16
        glass.tintColor = NSColor(srgbRed: 0.184, green: 0.42, blue: 0.31, alpha: 0.10)
        glass.contentView = NSView()
        fill(glass)

        let frameView = WoodFrameView()
        frameView.isHidden = true
        fill(frameView)

        let web = WKWebView(frame: .zero, configuration: config)
        web.setValue(false, forKey: "drawsBackground")
        web.underPageBackgroundColor = .clear
        web.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(web)
        // Glass: the page fills the window under the title bar. Classic: inset so the native wood frame shows around it.
        let webTop = web.topAnchor.constraint(equalTo: root.topAnchor, constant: 30)   // title bar stays free for dragging
        let webLeft = web.leadingAnchor.constraint(equalTo: root.leadingAnchor)
        let webRight = root.trailingAnchor.constraint(equalTo: web.trailingAnchor)
        let webBottom = root.bottomAnchor.constraint(equalTo: web.bottomAnchor)
        NSLayoutConstraint.activate([webTop, webLeft, webRight, webBottom])
        self.web = web

        // Classic look: the wooden frame is drawn natively so it follows the window edge while resizing
        let wood = NSColor(srgbRed: 0.62, green: 0.42, blue: 0.24, alpha: 1)
        let cork = NSColor(srgbRed: 0.75, green: 0.57, blue: 0.37, alpha: 1)
        themeHandler.apply = { [weak self] value in
            guard let self = self, value != self.currentTheme else { return }
            self.currentTheme = value
            let parts = value.split(separator: ":").map(String.init)
            let classic = parts.first == "classic"
            let mode = parts.count > 1 ? parts[1] : "auto"
            blur.isHidden = classic
            glass.isHidden = classic
            root.layer?.backgroundColor = NSColor.clear.cgColor
            frameView.isHidden = !classic
            webTop.constant = classic ? frameView.top : 30
            webLeft.constant = classic ? frameView.side : 0
            webRight.constant = classic ? frameView.side : 0
            webBottom.constant = classic ? frameView.bottom : 0
            // while the page catches up during a resize, show cork instead of an empty gap
            web.setValue(classic, forKey: "drawsBackground")
            web.underPageBackgroundColor = classic ? cork : .clear
            self.window.isOpaque = classic
            self.window.backgroundColor = classic ? wood : .clear
            self.window.appearance = classic ? NSAppearance(named: .aqua)
                : mode == "light" ? NSAppearance(named: .aqua)
                : mode == "dark" ? NSAppearance(named: .darkAqua) : nil
        }
        themeHandler.apply(startTheme)

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // Write any change typed in the last moment before quitting
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let web = web else { return .terminateNow }
        web.evaluateJavaScript("typeof flushSave === 'function' && flushSave()") { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { NSApp.reply(toApplicationShouldTerminate: true) }
        }
        return .terminateLater
    }
}

func buildMenu() -> NSMenu {
    let main = NSMenu()
    let appItem = NSMenuItem(); main.addItem(appItem)
    let appMenu = NSMenu()
    appMenu.addItem(withTitle: "Hide Monthly Budget", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
    appMenu.addItem(.separator())
    appMenu.addItem(withTitle: "Quit Monthly Budget", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    appItem.submenu = appMenu
    let editItem = NSMenuItem(); main.addItem(editItem)
    let edit = NSMenu(title: "Edit")
    edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    edit.addItem(.separator())
    edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    editItem.submenu = edit
    let winItem = NSMenuItem(); main.addItem(winItem)
    let win = NSMenu(title: "Window")
    win.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
    win.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    winItem.submenu = win
    return main
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.mainMenu = buildMenu()
app.run()
