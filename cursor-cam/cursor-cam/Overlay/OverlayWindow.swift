import AppKit

final class OverlayWindow: NSWindow {
    weak var assignedScreen: NSScreen?

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.hasShadow = false
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        self.assignedScreen = screen
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
