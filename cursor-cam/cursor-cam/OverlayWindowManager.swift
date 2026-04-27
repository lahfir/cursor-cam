import AppKit
import AVFoundation
import Combine
import SwiftUI

struct ScreenCamState: Equatable {
    var position: CGPoint = .zero
    var alpha: CGFloat = 0
}

@MainActor
final class OverlayWindowManager: ObservableObject {
    private var overlayWindows: [OverlayWindow] = []
    private var cursorTrackingTimer: Timer?
    private var isVisible = false
    private var showIntent = false
    private var modeSwitchTask: Task<Void, Never>?

    private let settings: SettingsStore
    private let cameraManager: CameraManager

    private static let camGap: CGFloat = 8
    private static let cornerMargin: CGFloat = 20
    private static let screenSwitchDebounce: TimeInterval = 0.15

    private var lastScreenSwitchTime: Date = .distantPast
    private var previousActiveFrame: CGRect?

    @Published private(set) var screenStates: [ObjectIdentifier: ScreenCamState] = [:]

    init(settings: SettingsStore, cameraManager: CameraManager) {
        self.settings = settings
        self.cameraManager = cameraManager
        observeScreenChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var isShowing: Bool { isVisible }

    func stateForScreen(_ screen: NSScreen) -> ScreenCamState {
        screenStates[ObjectIdentifier(screen)] ?? ScreenCamState()
    }

    func show() {
        showIntent = true
        guard !isVisible else { return }

        hideOverlayWindows()

        let mouse = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let ignores = settings.positioningMode != .freeDrag
        var initialStates: [ObjectIdentifier: ScreenCamState] = [:]

        for screen in screens {
            let window = OverlayWindow(screen: screen)
            window.assignedScreen = screen
            window.ignoresMouseEvents = ignores

            let previewView = CameraPreviewView(
                cameraManager: cameraManager,
                settings: settings,
                overlayManager: self,
                screen: screen
            )

            let hostingView = NSHostingView(rootView: previewView)
            hostingView.frame = screen.frame
            hostingView.wantsLayer = true
            window.contentView = hostingView

            let id = ObjectIdentifier(screen)
            var state = ScreenCamState()

            if screen.frame.contains(mouse) {
                state.alpha = 1
                state.position = computePosition(for: screen)
            } else {
                state.alpha = 0
            }
            initialStates[id] = state

            window.alphaValue = state.alpha
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }

        screenStates = initialStates
        isVisible = true
        startPositioningLoop()
    }

    func hide() {
        showIntent = false
        modeSwitchTask?.cancel()
        modeSwitchTask = nil
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
        isVisible = false

        let windows = overlayWindows
        overlayWindows.removeAll()
        screenStates.removeAll()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            for window in windows {
                window.animator().alphaValue = 0
            }
        }, completionHandler: {
            for window in windows {
                window.orderOut(nil)
                window.contentView = nil
            }
        })
    }

    func toggle() {
        if showIntent {
            hide()
        } else {
            show()
        }
    }

    func updateCamVisuals() {
        guard isVisible else { return }
        hide()
        show()
    }

    func onModeChanged() {
        guard isVisible else { return }

        let ignores = settings.positioningMode != .freeDrag
        for window in overlayWindows {
            window.ignoresMouseEvents = ignores
        }

        if settings.positioningMode == .freeDrag && settings.freeDragPosition == nil {
            if let screen = screenContainingCursor() {
                settings.freeDragPosition = camPosition(for: screen)
            }
        }

        modeSwitchTask?.cancel()
    }

    func onFreeDragMoved(to position: CGPoint, screen: NSScreen) {
        guard settings.positioningMode == .freeDrag else { return }
        settings.freeDragPosition = position

        let id = ObjectIdentifier(screen)
        var state = screenStates[id] ?? ScreenCamState()
        state.position = position
        screenStates[id] = state
    }

    func camPosition(for screen: NSScreen) -> CGPoint {
        let mouse = NSEvent.mouseLocation
        let base = convertToSwiftUICoordinates(mouse, screen: screen)
        let (width, height) = settings.cameraShape.dimensions(for: settings.cameraSize)
        let halfW = width / 2
        let halfH = height / 2
        let gap = Self.camGap

        return switch settings.cursorPosition {
        case .center:
            base
        case .bottomRight:
            CGPoint(x: base.x + halfW + gap, y: base.y + halfH + gap)
        case .bottomLeft:
            CGPoint(x: base.x - halfW - gap, y: base.y + halfH + gap)
        case .topLeft:
            CGPoint(x: base.x - halfW - gap, y: base.y - halfH - gap)
        case .topRight:
            CGPoint(x: base.x + halfW + gap, y: base.y - halfH - gap)
        }
    }

    func cornerPosition(for corner: Corner, screen: NSScreen) -> CGPoint {
        let margin = Self.cornerMargin
        let (width, height) = settings.cameraShape.dimensions(for: settings.cameraSize)
        let halfW = width / 2
        let halfH = height / 2

        return switch corner {
        case .topLeft:
            CGPoint(x: margin + halfW, y: margin + halfH)
        case .topRight:
            CGPoint(x: screen.frame.width - margin - halfW, y: margin + halfH)
        case .bottomLeft:
            CGPoint(x: margin + halfW, y: screen.frame.height - margin - halfH)
        case .bottomRight:
            CGPoint(x: screen.frame.width - margin - halfW, y: screen.frame.height - margin - halfH)
        }
    }

    func screenContainingCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouseLocation) }
    }

    func overlayForScreen(_ screen: NSScreen) -> OverlayWindow? {
        overlayWindows.first { $0.assignedScreen == screen }
    }

    func handleSleep() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
    }

    func handleWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if self.isVisible {
                self.syncOverlaysToScreens()
                self.startPositioningLoop()
            }
        }
    }

    // MARK: - Private

    private func computePosition(for screen: NSScreen) -> CGPoint {
        switch settings.positioningMode {
        case .followCursor:
            return camPosition(for: screen)
        case .pinToCorner:
            return cornerPosition(for: settings.pinnedCorner, screen: screen)
        case .freeDrag:
            return settings.freeDragPosition ?? camPosition(for: screen)
        }
    }

    private func hideOverlayWindows() {
        for window in overlayWindows {
            window.orderOut(nil)
            window.contentView = nil
        }
        overlayWindows.removeAll()
    }

    private func startPositioningLoop() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.positioningTick()
            }
        }
    }

    private func positioningTick() {
        guard isVisible, showIntent, !Task.isCancelled else { return }

        let mouseLocation = NSEvent.mouseLocation

        switch settings.positioningMode {
        case .followCursor:
            tickFollowCursor(mouseLocation: mouseLocation)
        case .pinToCorner:
            tickPinToCorner(mouseLocation: mouseLocation)
        case .freeDrag:
            tickFreeDrag(mouseLocation: mouseLocation)
        }
    }

    private func tickFollowCursor(mouseLocation: CGPoint) {
        let activeFrame = NSScreen.screens.first { $0.frame.contains(mouseLocation) }?.frame
        if activeFrame != previousActiveFrame {
            let now = Date()
            if now.timeIntervalSince(lastScreenSwitchTime) < Self.screenSwitchDebounce { return }
            lastScreenSwitchTime = now
            previousActiveFrame = activeFrame
        }
        applyTick { screen in
            screen.frame.contains(mouseLocation) ? camPosition(for: screen) : nil
        }
    }

    private func tickPinToCorner(mouseLocation: CGPoint) {
        applyTick { screen in
            screen.frame.contains(mouseLocation) ? cornerPosition(for: settings.pinnedCorner, screen: screen) : nil
        }
    }

    private func tickFreeDrag(mouseLocation: CGPoint) {
        guard let pos = settings.freeDragPosition else {
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
                settings.freeDragPosition = camPosition(for: screen)
            }
            return
        }
        applyTick { screen in
            screen.frame.contains(pos) ? pos : nil
        }
    }

    private func applyTick(positionProvider: (NSScreen) -> CGPoint?) {
        var newStates = screenStates
        for window in overlayWindows {
            guard let screen = window.assignedScreen else { continue }
            let id = ObjectIdentifier(screen)
            var state = newStates[id] ?? ScreenCamState()
            if let pos = positionProvider(screen) {
                state.alpha = 1
                state.position = pos
            } else {
                state.alpha = 0
            }
            newStates[id] = state
        }
        screenStates = newStates
    }

    private func convertToSwiftUICoordinates(_ point: CGPoint, screen: NSScreen) -> CGPoint {
        let x = point.x - screen.frame.origin.x
        let y = (screen.frame.origin.y + screen.frame.height) - point.y
        return CGPoint(x: x, y: y)
    }

    private func syncOverlaysToScreens() {
        guard isVisible else { return }
        hide()
        show()
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleScreenChange() {
        guard isVisible else { return }
        syncOverlaysToScreens()
    }
}

final class OverlayWindow: NSWindow {
    weak var assignedScreen: NSScreen?

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
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

        self.assignedScreen = screen
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
