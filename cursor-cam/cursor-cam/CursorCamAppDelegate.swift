import AppKit
import SwiftUI

@MainActor
final class CursorCamAppDelegate: NSObject, NSApplicationDelegate {
    private var settingsStore: SettingsStore?
    private var cameraManager: CameraManager?
    private var overlayWindowManager: OverlayWindowManager?
    private var hotkeyMonitor: HotkeyMonitor?
    private var menuBarManager: MenuBarManager?
    private var permissionsManager: PermissionsManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore()
        let camera = CameraManager(settings: settings)
        let overlay = OverlayWindowManager(settings: settings, cameraManager: camera)
        let hotkey = HotkeyMonitor()
        let menuBar = MenuBarManager(
            settings: settings,
            cameraManager: camera,
            overlayManager: overlay
        )
        let permissions = PermissionsManager()

        settingsStore = settings
        cameraManager = camera
        overlayWindowManager = overlay
        hotkeyMonitor = hotkey
        menuBarManager = menuBar
        permissionsManager = permissions

        menuBar.setPermissionsManager(permissions)

        hotkey.setToggleHandler { [weak overlay, weak camera] in
            guard let overlay, let camera else { return }
            if overlay.isShowing {
                overlay.hide()
            } else {
                camera.startSession()
                overlay.show()
            }
        }

        menuBar.show()
        permissions.requestOnFirstLaunch()
        hotkey.start()

        observeSystemNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyMonitor?.stop()
        cameraManager?.stopSession()
        overlayWindowManager?.hide()
        settingsStore = nil
    }

    private func observeSystemNotifications() {
        let center = NotificationCenter.default

        center.addObserver(
            self,
            selector: #selector(handleWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        center.addObserver(
            self,
            selector: #selector(handleDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWillSleep() {
        overlayWindowManager?.handleSleep()
        cameraManager?.handleSleep()
    }

    @objc private func handleDidWake() {
        overlayWindowManager?.handleWake()
        cameraManager?.handleWake()
        hotkeyMonitor?.restart()
    }
}
