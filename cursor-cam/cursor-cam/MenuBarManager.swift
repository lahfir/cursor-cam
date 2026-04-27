import AppKit
import AVFoundation
import SwiftUI
import ServiceManagement

@MainActor
final class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var cameraMenuItems: [NSMenuItem] = []
    private var cornerMenuItems: [NSMenuItem] = []

    private let settings: SettingsStore
    private let cameraManager: CameraManager
    private let overlayManager: OverlayWindowManager
    private weak var permissionsManager: PermissionsManager?

    init(
        settings: SettingsStore,
        cameraManager: CameraManager,
        overlayManager: OverlayWindowManager
    ) {
        self.settings = settings
        self.cameraManager = cameraManager
        self.overlayManager = overlayManager
    }

    func setPermissionsManager(_ manager: PermissionsManager) {
        self.permissionsManager = manager
    }

    func show() {
        print("CursorCam: Creating menu bar status item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()
        buildMenu()
        print("CursorCam: Menu bar ready. Icon visible in menu bar (top-right).")
    }

    func openMenu() {
        statusItem?.button?.performClick(nil)
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

        let body: NSRect
        if rect.width > 10 {
            body = NSRect(x: 2, y: 4, width: 10, height: 7)
        } else {
            body = rect
        }

        NSColor.black.setStroke()
        path.lineWidth = 1.5
        path.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    func buildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: overlayManager.isShowing ? "Turn Cam Off" : "Turn Cam On",
            action: #selector(toggleCamAction),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        // Positioning Mode submenu
        let modeMenu = NSMenu()
        for mode in PositioningMode.allCases {
            let item = NSMenuItem(
                title: modeDisplayName(mode),
                action: #selector(selectModeAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = settings.positioningMode == mode ? .on : .off
            modeMenu.addItem(item)
        }
        let modeItem = NSMenuItem(title: "Positioning Mode", action: nil, keyEquivalent: "")
        menu.addItem(modeItem)
        menu.setSubmenu(modeMenu, for: modeItem)

        // Pin to Corner submenu
        let cornerMenu = NSMenu()
        let corners: [(Corner, String)] = [
            (.topLeft, "Top Left"),
            (.topRight, "Top Right"),
            (.bottomLeft, "Bottom Left"),
            (.bottomRight, "Bottom Right")
        ]
        cornerMenuItems.removeAll()
        for (corner, title) in corners {
            let item = NSMenuItem(
                title: title,
                action: #selector(selectCornerAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = corner.rawValue
            item.state = settings.pinnedCorner == corner ? .on : .off
            cornerMenu.addItem(item)
            cornerMenuItems.append(item)
        }
        let cornerItem = NSMenuItem(title: "Pin to Corner", action: nil, keyEquivalent: "")
        menu.addItem(cornerItem)
        menu.setSubmenu(cornerMenu, for: cornerItem)

        // Camera submenu
        let cameraMenu = NSMenu()
        cameraMenuItems.removeAll()
        for device in cameraManager.availableCameras {
            let item = NSMenuItem(
                title: device.localizedName,
                action: #selector(selectCameraAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.uniqueID
            item.state = (cameraManager.currentCamera?.uniqueID == device.uniqueID) ? .on : .off
            cameraMenu.addItem(item)
            cameraMenuItems.append(item)
        }
        if cameraManager.availableCameras.isEmpty {
            let noCam = NSMenuItem(title: "No Camera Available", action: nil, keyEquivalent: "")
            noCam.isEnabled = false
            cameraMenu.addItem(noCam)
        }
        let camMenuItem = NSMenuItem(title: "Camera", action: nil, keyEquivalent: "")
        menu.addItem(camMenuItem)
        menu.setSubmenu(cameraMenu, for: camMenuItem)

        // Shape submenu
        let shapeMenu = NSMenu()
        for shape in CameraShape.allCases {
            let item = NSMenuItem(
                title: shape == .circle ? "Circle" : "Rounded Square",
                action: #selector(selectShapeAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = shape.rawValue
            item.state = settings.cameraShape == shape ? .on : .off
            shapeMenu.addItem(item)
        }
        let shapeItem = NSMenuItem(title: "Shape", action: nil, keyEquivalent: "")
        menu.addItem(shapeItem)
        menu.setSubmenu(shapeMenu, for: shapeItem)

        // Size submenu
        let sizeMenu = NSMenu()
        let sizes: [(CameraSize, String)] = [(.small, "Small"), (.medium, "Medium"), (.large, "Large")]
        for (size, title) in sizes {
            let item = NSMenuItem(
                title: title,
                action: #selector(selectSizeAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = size.rawValue
            item.state = settings.cameraSize == size ? .on : .off
            sizeMenu.addItem(item)
        }
        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        menu.addItem(sizeItem)
        menu.setSubmenu(sizeMenu, for: sizeItem)

        // Mirror toggle
        let mirrorItem = NSMenuItem(
            title: "Mirror",
            action: #selector(toggleMirrorAction),
            keyEquivalent: ""
        )
        mirrorItem.target = self
        mirrorItem.state = settings.isMirrored ? .on : .off
        menu.addItem(mirrorItem)

        // Cursor Position submenu
        let cursorPosMenu = NSMenu()
        let cursorPositions: [(CursorPosition, String)] = [
            (.center, "Center"),
            (.bottomRight, "Bottom Right"),
            (.bottomLeft, "Bottom Left"),
            (.topLeft, "Top Left"),
            (.topRight, "Top Right")
        ]
        for (position, title) in cursorPositions {
            let item = NSMenuItem(
                title: title,
                action: #selector(selectCursorPositionAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = position.rawValue
            item.state = settings.cursorPosition == position ? .on : .off
            cursorPosMenu.addItem(item)
        }
        let cursorPosItem = NSMenuItem(title: "Cursor Position", action: nil, keyEquivalent: "")
        menu.addItem(cursorPosItem)
        menu.setSubmenu(cursorPosMenu, for: cursorPosItem)

        // Border submenu
        let borderMenu = NSMenu()

        let borderStyles: [(BorderStyle, String)] = [
            (.none, "None"),
            (.solid, "Solid"),
            (.dashed, "Dashed")
        ]
        for (style, name) in borderStyles {
            let item = NSMenuItem(
                title: name,
                action: #selector(selectBorderStyleAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = style.rawValue
            item.state = settings.borderStyle == style ? .on : .off
            borderMenu.addItem(item)
        }

        borderMenu.addItem(.separator())

        let widths: [(CGFloat, String)] = [(1, "1px"), (2, "2px"), (3, "3px"), (4, "4px"), (6, "6px")]
        for (width, label) in widths {
            let item = NSMenuItem(
                title: label,
                action: #selector(selectBorderWidthAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = width
            item.state = settings.borderWidth == width ? .on : .off
            borderMenu.addItem(item)
        }

        let borderItem = NSMenuItem(title: "Border", action: nil, keyEquivalent: "")
        menu.addItem(borderItem)
        menu.setSubmenu(borderMenu, for: borderItem)

        menu.addItem(.separator())

        // Permission status
        if let permMgr = permissionsManager {
            let camPermItem = NSMenuItem(
                title: "Camera: \(permMgr.cameraPermissionGranted ? "Granted" : "Not Granted")",
                action: nil,
                keyEquivalent: ""
            )
            camPermItem.isEnabled = false
            menu.addItem(camPermItem)

            let accPermItem = NSMenuItem(
                title: "Accessibility: \(permMgr.accessibilityPermissionGranted ? "Granted" : "Not Granted")",
                action: nil,
                keyEquivalent: ""
            )
            accPermItem.isEnabled = false
            menu.addItem(accPermItem)
        }

        let openPermsItem = NSMenuItem(
            title: "Check Permissions...",
            action: #selector(checkPermissionsAction),
            keyEquivalent: ""
        )
        openPermsItem.target = self
        menu.addItem(openPermsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Cursor-Cam",
            action: #selector(quitAction),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func toggleCamAction() {
        if overlayManager.isShowing {
            overlayManager.hide()
            settings.isCamOn = false
        } else {
            cameraManager.startSession()
            overlayManager.show()
            settings.isCamOn = true
        }
        updateIcon()
    }

    @objc private func selectModeAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = PositioningMode(rawValue: raw) else { return }
        settings.positioningMode = mode
        overlayManager.onModeChanged()
        buildMenu()
    }

    @objc private func selectCornerAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let corner = Corner(rawValue: raw) else { return }
        settings.pinnedCorner = corner
        buildMenu()
    }

    @objc private func selectCameraAction(_ sender: NSMenuItem) {
        guard let uniqueID = sender.representedObject as? String else { return }
        cameraManager.selectCamera(by: uniqueID)
        buildMenu()
    }

    @objc private func selectShapeAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let shape = CameraShape(rawValue: raw) else { return }
        settings.cameraShape = shape
        overlayManager.updateCamVisuals()
        buildMenu()
    }

    @objc private func selectSizeAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let size = CameraSize(rawValue: raw) else { return }
        settings.cameraSize = size
        overlayManager.updateCamVisuals()
        buildMenu()
    }

    @objc private func toggleMirrorAction() {
        settings.isMirrored.toggle()
        buildMenu()
    }

    @objc private func checkPermissionsAction() {
        permissionsManager?.requestPermissions()
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func selectCursorPositionAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let position = CursorPosition(rawValue: raw) else { return }
        settings.cursorPosition = position
        buildMenu()
    }

    @objc private func selectBorderStyleAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = BorderStyle(rawValue: raw) else { return }
        settings.borderStyle = style
        buildMenu()
    }

    @objc private func selectBorderWidthAction(_ sender: NSMenuItem) {
        guard let width = sender.representedObject as? CGFloat else { return }
        settings.borderWidth = width
        buildMenu()
    }

    private func modeDisplayName(_ mode: PositioningMode) -> String {
        switch mode {
        case .followCursor: return "Follow Cursor"
        case .pinToCorner: return "Pin to Corner"
        case .freeDrag: return "Free Drag"
        }
    }
}
