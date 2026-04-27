import AppKit
import AVFoundation
import Combine
import SwiftUI

@MainActor
final class CursorCamAppDelegate: NSObject, NSApplicationDelegate {
    private var settingsStore: SettingsStore?
    private var cameraManager: CameraManager?
    private var overlayWindowManager: OverlayWindowManager?
    private var hotkeyMonitor: HotkeyMonitor?
    private var menuBarManager: MenuBarManager?
    private var permissionsManager: PermissionsManager?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsStore()
        let camera = CameraManager(settings: settings)
        let overlay = OverlayWindowManager(
            settings: settings,
            cameraManager: camera
        )
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

        hotkey.setToggleHandler { [weak overlay, weak camera, weak settings] in
            guard let overlay, let camera, let settings else { return }
            if overlay.isShowing {
                overlay.hide()
                settings.isCamOn = false
            } else {
                settings.isCamOn = true
                camera.startSession()
                overlay.show()
            }
        }

        menuBar.show()
        hotkey.start()

        if permissions.needsOnboarding {
            permissions.requestOnFirstLaunch()
        } else {
            permissions.refreshPermissions()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            menuBar.openMenu()
        }

        observePermissions(permissions, camera: camera, overlay: overlay, settings: settings)
        observeSystemNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cancellables.removeAll()
        hotkeyMonitor?.stop()
        cameraManager?.stopSession()
        overlayWindowManager?.hide()
        settingsStore = nil
    }

    private func observePermissions(
        _ permissions: PermissionsManager,
        camera: CameraManager,
        overlay: OverlayWindowManager,
        settings: SettingsStore
    ) {
        permissions.$cameraPermissionGranted
            .removeDuplicates()
            .dropFirst()
            .sink { [weak camera, weak overlay, weak settings] granted in
                guard let camera, let overlay, let settings else { return }
                if granted, settings.isCamOn, !overlay.isShowing {
                    camera.startSession()
                    overlay.show()
                }
            }
            .store(in: &cancellables)
    }

    private func observeSystemNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(handleDidWake), name: NSWorkspace.didWakeNotification, object: nil)
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
