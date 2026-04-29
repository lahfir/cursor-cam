import AppKit
import AVFoundation
import Combine
import SwiftUI

struct CamState: Equatable {
    var position: CGPoint = .zero
    var alpha: CGFloat = 0
}

@MainActor
final class OverlayWindowManager: ObservableObject {
    private var overlay: OverlayWindow?
    private var hostingView: NSHostingView<CameraPreviewView>?
    private var cursorTrackingTimer: Timer?
    private var isVisible = false
    private var showIntent = false
    private var activeScreen: NSScreen?
    private var isHandingOff = false

    private let settings: SettingsStore
    private let cameraManager: CameraManager
    private let behaviorController: CamBehaviorController
    private let positionResolver: CamPositionResolver

    private static let tickInterval: TimeInterval = 1.0 / 60.0

    @Published private(set) var camState: CamState = CamState()
    @Published private(set) var velocityScale: CGFloat = 1.0
    @Published private(set) var idleDimMultiplier: CGFloat = 1.0

    init(settings: SettingsStore, cameraManager: CameraManager) {
        self.settings = settings
        self.cameraManager = cameraManager
        self.behaviorController = CamBehaviorController(settings: settings)
        self.positionResolver = CamPositionResolver(settings: settings)
        observeScreenChanges()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    var isShowing: Bool { isVisible }

    func show() {
        showIntent = true
        guard !isVisible else { return }

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let window = overlay ?? buildWindow()
        overlay = window
        moveWindow(to: screen)
        activeScreen = screen

        camState = CamState(position: positionResolver.position(for: settings.positioningMode, screen: screen), alpha: 1)
        window.alphaValue = 0
        window.ignoresMouseEvents = settings.positioningMode != .freeDrag
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }

        isVisible = true
        startPositioningLoop()
    }

    func hide() {
        showIntent = false
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
        isVisible = false
        behaviorController.reset()

        guard let window = overlay else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.camState = CamState()
        })
    }

    func toggle() {
        showIntent ? hide() : show()
    }

    func updateCamVisuals() {
        guard isVisible, let screen = activeScreen else { return }
        camState.position = positionResolver.position(for: settings.positioningMode, screen: screen)
    }

    func onModeChanged() {
        guard isVisible else { return }
        overlay?.ignoresMouseEvents = settings.positioningMode != .freeDrag
    }

    func onFreeDragMoved(to position: CGPoint, screen: NSScreen) {
        guard settings.positioningMode == .freeDrag else { return }
        settings.freeDragPosition = position
        camState.position = position
    }

    func screenContainingCursor() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) }
    }

    func handleSleep() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = nil
    }

    func handleWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.isVisible else { return }
            self.startPositioningLoop()
        }
    }

    private func buildWindow() -> OverlayWindow {
        let window = OverlayWindow()
        let preview = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: self
        )
        let hosting = NSHostingView(rootView: preview)
        hosting.wantsLayer = true
        hosting.frame = NSRect(origin: .zero, size: window.frame.size)
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
        self.hostingView = hosting
        return window
    }

    private func moveWindow(to screen: NSScreen) {
        overlay?.setFrame(screen.frame, display: true)
    }

    private func startPositioningLoop() {
        cursorTrackingTimer?.invalidate()
        cursorTrackingTimer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
    }

    private func tick() {
        guard isVisible, showIntent, !isHandingOff else { return }

        let mouse = NSEvent.mouseLocation
        behaviorController.tick(mouseLocation: mouse)
        velocityScale = behaviorController.velocityScale
        idleDimMultiplier = behaviorController.idleDimMultiplier

        let target = targetScreen(for: mouse) ?? activeScreen
        guard let screen = target else { return }

        if screen !== activeScreen {
            handoffToScreen(screen)
            return
        }

        camState.position = positionResolver.position(for: settings.positioningMode, screen: screen)
        camState.alpha = 1
    }

    private func targetScreen(for mouse: CGPoint) -> NSScreen? {
        switch settings.positioningMode {
        case .followCursor, .pinToCorner:
            return NSScreen.screens.first { $0.frame.contains(mouse) }
        case .freeDrag:
            return activeScreen ?? NSScreen.screens.first { $0.frame.contains(mouse) }
        }
    }

    private func handoffToScreen(_ screen: NSScreen) {
        guard let window = overlay else { return }
        isHandingOff = true

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self else { return }
            window.setFrame(screen.frame, display: true)
            self.activeScreen = screen
            withTransaction(Transaction(animation: nil)) {
                self.camState = CamState(
                    position: self.positionResolver.position(for: self.settings.positioningMode, screen: screen),
                    alpha: 1
                )
            }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.20
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1
            }, completionHandler: { [weak self] in
                self?.isHandingOff = false
            })
        })
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
        guard isVisible, let screen = screenContainingCursor() ?? NSScreen.main else { return }
        moveWindow(to: screen)
        activeScreen = screen
    }
}
