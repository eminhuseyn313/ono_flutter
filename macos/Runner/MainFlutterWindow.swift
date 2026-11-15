import Cocoa
import FlutterMacOS

/// ONO on the Mac: one phone-shaped column (the app keeps a 480 pt column
/// on wide windows), so the window opens at that size and can grow.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    let size = NSSize(width: 480, height: 860)
    self.setContentSize(size)
    self.contentMinSize = NSSize(width: 380, height: 600)
    self.title = "ONO"
    self.center()
    self.setFrameAutosaveName("ONOMain")

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
