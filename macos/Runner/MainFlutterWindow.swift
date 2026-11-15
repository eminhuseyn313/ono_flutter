import Cocoa
import FlutterMacOS

/// ONO on the Mac: a desktop window — sidebar, the page and today at a
/// glance. Narrow it below 900 pt and it becomes the phone layout.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    let size = NSSize(width: 1320, height: 860)
    self.setContentSize(size)
    self.contentMinSize = NSSize(width: 420, height: 600)
    self.title = "ONO"
    self.center()
    self.setFrameAutosaveName("ONOMainDesktop")

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
