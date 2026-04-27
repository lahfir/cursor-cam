import AppKit
import SwiftUI
import Combine

/// Manages the settings panel as a non-activating floating panel anchored to
/// the menu bar status item. Uses `NSPanel` with `.nonactivatingPanel` so the
/// user's current app retains key focus while the panel still supports
/// keyboard navigation. The panel is forced to the dark vibrant appearance
/// to keep the studio aesthetic consistent across light/dark modes.
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

    private static let gapBelowMenuBar: CGFloat = 6
    private static let screenMargin: CGFloat = 12
    private static let defaultHeight: CGFloat = 560

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
        if let monitor = clickOutsideMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
    }

    func attach(to statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        if panel == nil { createPanel() }
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

    // MARK: - Panel Construction

    private var hostingView: NSHostingView<SettingsPanelView>?

    private func createPanel() {
        let settingsView = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )

        let hosting = NSHostingView(rootView: settingsView)
        hosting.layer?.backgroundColor = .clear
        self.hostingView = hosting

        let frame = NSRect(x: 0, y: 0, width: Studio.panelWidth, height: Self.defaultHeight)
        let panel = KeyablePanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configure(panel: panel)
        panel.contentView = makeContainer(hosting: hosting, size: frame.size)
        self.panel = panel
    }

    private func configure(panel: NSPanel) {
        panel.appearance = NSAppearance(named: .vibrantDark)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isExcludedFromWindowsMenu = true
        panel.isMovableByWindowBackground = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    /// Wraps the SwiftUI hosting view inside an `NSVisualEffectView` so the
    /// panel reads as a frosted-glass surface that adapts to the desktop
    /// behind it. A rounded corner mask ties it together with `hasShadow`.
    private func makeContainer(hosting: NSHostingView<SettingsPanelView>, size: NSSize) -> NSView {
        let blur = NSVisualEffectView()
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 14
        blur.layer?.cornerCurve = .continuous
        blur.layer?.masksToBounds = true
        blur.frame = NSRect(origin: .zero, size: size)
        blur.autoresizingMask = [.width, .height]

        hosting.frame = blur.bounds
        hosting.autoresizingMask = [.width, .height]
        blur.addSubview(hosting)
        return blur
    }

    // MARK: - Positioning

    private func positionPanelBelowStatusItem() {
        guard let panel else { return }
        guard let buttonWindow = statusItem?.button?.window else { return }

        let statusFrame = buttonWindow.frame
        let height = Self.defaultHeight

        var originX = statusFrame.midX - (Studio.panelWidth / 2)
        let originY = statusFrame.minY - height - Self.gapBelowMenuBar

        if let screen = buttonWindow.screen {
            let screenFrame = screen.visibleFrame
            originX = max(screenFrame.minX + Self.screenMargin, originX)
            originX = min(screenFrame.maxX - Studio.panelWidth - Self.screenMargin, originX)
        }

        panel.setFrame(
            NSRect(x: originX, y: originY, width: Studio.panelWidth, height: height),
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
                guard let panel = self.panel, panel.isVisible else { return }
                let location = NSEvent.mouseLocation
                if !panel.frame.contains(location) { self.hide() }
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

/// `NSPanel` subclass that can become key while still using the
/// `.nonactivatingPanel` style mask. This enables Tab / Space / Enter / Escape
/// keyboard navigation inside the panel without ever stealing focus from the
/// user's frontmost app.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
