import AppKit
import SwiftUI

@MainActor
final class MenuBarManager {
    private var statusItem: NSStatusItem?
    private let popoverManager: SettingsPopoverManager

    init(
        settings: SettingsStore,
        cameraManager: CameraManager,
        overlayManager: OverlayWindowManager,
        permissionsManager: PermissionsManager
    ) {
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

        guard let button = statusItem?.button, let item = statusItem else { return }
        button.action = #selector(statusItemClicked)
        button.target = self

        popoverManager.attach(to: item)
    }

    func openMenu() {
        popoverManager.show()
    }

    func updateIcon() {
        guard let button = statusItem?.button else { return }
        if let image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
        }
        button.toolTip = "Cursor-Cam"
    }

    @objc private func statusItemClicked() {
        popoverManager.toggle()
    }
}
