import AppKit
import SwiftUI
import Combine

/// Manages the settings panel presentation as a non-activating floating panel
/// anchored to the menu bar status item. Uses NSPanel with .nonactivatingPanel
/// so the user's current app retains focus while the panel supports keyboard navigation.
@MainActor
final class SettingsPopoverManager: NSObject {
    private var panel: NSPanel?
    private var statusItem: NSStatusItem?
    private var clickOutsideMonitor: Any?
    private var keyMonitor: Any?

    private let settings: SettingsStore
    private let cameraManager: CameraManager
    private let overlayManager: OverlayWindowManager
    private let permissionsManager: PermissionsManager

    private let panelWidth: CGFloat = 400

    init(
        settings: SettingsStore,
        cameraManager: CameraManager,
        overlayManager: OverlayWindowManager,
        permissionsManager: PermissionsManager
    ) {
        self.settings = settings
        self.cameraManager = cameraManager
        self.overlayManager = overlayManager
        self.permissionsManager = permissionsManager
        super.init()
    }

    deinit {
        Task { @MainActor in
            removeClickOutsideMonitor()
            removeKeyMonitor()
        }
    }

    func attach(to statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        positionPanelBelowStatusItem()
        panel?.makeKeyAndOrderFront(nil)
        panel?.orderFrontRegardless()
        installClickOutsideMonitor()
        installKeyMonitor()
    }

    func hide() {
        panel?.orderOut(nil)
        removeClickOutsideMonitor()
        removeKeyMonitor()
    }

    // MARK: - Panel Lifecycle

    private func createPanel() {
        let settingsView = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
        .frame(width: panelWidth)

        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: 500)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear

        let settingsPanel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 500),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        settingsPanel.isFloatingPanel = true
        settingsPanel.level = .floating
        settingsPanel.isOpaque = false
        settingsPanel.backgroundColor = .clear
        settingsPanel.hasShadow = true
        settingsPanel.hidesOnDeactivate = false
        settingsPanel.isExcludedFromWindowsMenu = true
        settingsPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        settingsPanel.isMovableByWindowBackground = false
        settingsPanel.titleVisibility = .hidden
        settingsPanel.titlebarAppearsTransparent = true

        settingsPanel.contentView = hostingView
        panel = settingsPanel
    }

    private func positionPanelBelowStatusItem() {
        guard let panel else { return }
        guard let buttonWindow = statusItem?.button?.window else { return }

        let statusItemFrame = buttonWindow.frame
        let gapBelowMenuBar: CGFloat = 4
        let screenMargin: CGFloat = 12

        let fittingSize = panel.contentView?.fittingSize ?? CGSize(width: panelWidth, height: 500)
        let actualHeight = fittingSize.height

        var panelOriginX = statusItemFrame.midX - (panelWidth / 2)
        let panelOriginY = statusItemFrame.minY - actualHeight - gapBelowMenuBar

        // Clamp to screen bounds so the panel never clips off the left or right edge
        if let screen = buttonWindow.screen {
            let screenFrame = screen.visibleFrame
            panelOriginX = max(screenFrame.minX + screenMargin, panelOriginX)
            panelOriginX = min(screenFrame.maxX - panelWidth - screenMargin, panelOriginX)
        }

        panel.setFrame(
            NSRect(x: panelOriginX, y: panelOriginY, width: panelWidth, height: actualHeight),
            display: true
        )
    }

    // MARK: - Dismissal

    private func installClickOutsideMonitor() {
        removeClickOutsideMonitor()

        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard self.panel?.isVisible == true else { return }
                let clickLocation = NSEvent.mouseLocation
                if let panelFrame = self.panel?.frame,
                   !panelFrame.contains(clickLocation) {
                    self.hide()
                }
            }
        }
    }

    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.keyCode == 53 else { return event }
            self.hide()
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

// MARK: - Keyable Panel

/// NSPanel subclass that can become key while using .nonactivatingPanel style,
/// enabling keyboard navigation (Tab, Space, Enter, Escape) without activating
/// the app in the Dock or stealing focus from the user's current app.
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
