import Cocoa
import WebKit

// Minimal native HTML viewer: an NSWindow hosting a WKWebView.
// Usage: html-view <file.html | http(s)://url>
//   esc / ⌘W  close      ⌘R  reload      ⌘=/⌘- zoom

class WebWindow: NSWindow {
    weak var web: WKWebView?
    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Reached only for keys the web content didn't consume. Handle esc;
        // swallow the rest so macOS doesn't play the "unhandled key" beep.
        if event.keyCode == 53 { NSApp.terminate(nil) } // Escape
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), let key = event.charactersIgnoringModifiers {
            switch key {
            case "w": NSApp.terminate(nil); return true
            case "r": web?.reload(); return true
            case "=", "+": web?.pageZoom += 0.1; return true
            case "-": web?.pageZoom = max(0.2, web!.pageZoom - 0.1); return true
            case "0": web?.pageZoom = 1.0; return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let target: URL
    let readAccess: URL?
    var window: WebWindow!

    init(target: URL, readAccess: URL?) {
        self.target = target
        self.readAccess = readAccess
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let vf = NSScreen.main!.visibleFrame
        let w = vf.width * 0.85, h = vf.height * 0.9
        let rect = NSRect(x: vf.midX - w / 2, y: vf.midY - h / 2, width: w, height: h)

        window = WebWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = target.lastPathComponent.isEmpty ? target.absoluteString : target.lastPathComponent
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)

        let webView = WKWebView(frame: window.contentView!.bounds)
        webView.autoresizingMask = [.width, .height]
        window.web = webView

        if let dir = readAccess {
            webView.loadFileURL(target, allowingReadAccessTo: dir)
        } else {
            webView.load(URLRequest(url: target))
        }

        window.contentView!.addSubview(webView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }
}

// --- arg parsing ---
guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: html-view <file.html | http(s)://url>\n".data(using: .utf8)!)
    exit(2)
}

let arg = CommandLine.arguments[1]
let target: URL
let readAccess: URL?

if arg.hasPrefix("http://") || arg.hasPrefix("https://") {
    guard let u = URL(string: arg) else {
        FileHandle.standardError.write("invalid url: \(arg)\n".data(using: .utf8)!)
        exit(2)
    }
    target = u
    readAccess = nil
} else {
    let path = (arg as NSString).expandingTildeInPath
    guard FileManager.default.fileExists(atPath: path) else {
        FileHandle.standardError.write("no such file: \(path)\n".data(using: .utf8)!)
        exit(2)
    }
    target = URL(fileURLWithPath: path).standardizedFileURL
    readAccess = target.deletingLastPathComponent()
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate(target: target, readAccess: readAccess)
app.delegate = delegate
app.run()
