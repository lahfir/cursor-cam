import AppKit

/// Borderless transparent window that hosts the floating cam overlay. A single
/// instance is reused across screens — `OverlayWindowManager` repositions it
/// to whichever screen currently contains the cursor. Single-window design
/// avoids the `AVCaptureVideoPreviewLayer` conflict (a preview layer cannot
/// live in two CALayer hierarchies at once).
final class OverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.hasShadow = false
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
