import AppKit
import SwiftUI

@MainActor
final class MenuBarManager {
    private var statusItem: NSStatusItem?
    private let popoverManager: SettingsPopoverManager
    private let settings: SettingsStore
    private let cameraManager: CameraManager
    private let overlayManager: OverlayWindowManager

    init(
        settings: SettingsStore,
        cameraManager: CameraManager,
        overlayManager: OverlayWindowManager,
        permissionsManager: PermissionsManager
    ) {
        self.settings = settings
        self.cameraManager = cameraManager
        self.overlayManager = overlayManager
        self.popoverManager = SettingsPopoverManager(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
    }

    func show() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()

        guard let button = statusItem?.button else { return }
        button.action = #selector(statusItemClicked)
        button.target = self

        popoverManager.attach(to: statusItem!)
    }

    func openMenu() {
        popoverManager.show()
    }

    func updateIcon() {
        guard let button = statusItem?.button else { return }

        let iconName: String
        if !overlayManager.isShowing {
            iconName = "camera"
        } else if cameraManager.cameraState == .running {
            iconName = "camera.fill"
        } else {
            iconName = "camera.fill"
        }

        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
        } else {
            button.image = makeFallbackIcon()
        }

        button.toolTip = "Cursor-Cam"
    }

    private func makeFallbackIcon() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(x: 2, y: 2, width: 14, height: 14)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

        NSColor.black.setStroke()
        path.lineWidth = 1.5
        path.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    @objc private func statusItemClicked() {
        popoverManager.toggle()
    }

    @objc private func toggleCamAction() {
        if overlayManager.isShowing {
            overlayManager.hide()
            cameraManager.stopSession()
            settings.isCamOn = false
        } else {
            cameraManager.startSession()
            overlayManager.show()
            settings.isCamOn = true
        }
        updateIcon()
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
