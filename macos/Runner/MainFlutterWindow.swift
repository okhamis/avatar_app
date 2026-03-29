import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // Set iPhone-like fixed window size (390x844 is iPhone 15 logical size)
    let contentSize = NSSize(width: 390, height: 844)
    let newFrame = NSRect(origin: self.frame.origin, size: contentSize)
    self.contentViewController = flutterViewController
    self.setFrame(newFrame, display: true)

    // Make window draggable from the title bar (macOS standard behavior)
    // Set size constraints to maintain aspect ratio
    self.minSize = NSSize(width: 390, height: 844)
    self.maxSize = NSSize(width: 390, height: 844)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
