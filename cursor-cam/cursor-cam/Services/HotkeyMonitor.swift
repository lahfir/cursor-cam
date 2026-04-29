import AppKit
import CoreGraphics

extension Notification.Name {
    static let cursorCamClickFeedback = Notification.Name("cursorCamClickFeedback")
}

final class HotkeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isShortcutPressed = false
    private var toggleHandler: (() -> Void)?

    deinit {
        stop()
    }

    func start() {
        guard eventTap == nil else { return }
        guard PermissionsManager.hasAccessibilityPermission() else { return }

        let eventMask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
            | CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
            | CGEventMask(1 << CGEventType.rightMouseDown.rawValue)

        let callback: CGEventTapCallBack = { _, eventType, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            return monitor.handleEvent(type: eventType, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("HotkeyMonitor: Failed to create event tap")
            return
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        isShortcutPressed = false

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil

        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        eventTap = nil
    }

    func restart() {
        stop()
        start()
    }

    func setToggleHandler(_ handler: @escaping () -> Void) {
        toggleHandler = handler
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .leftMouseDown, .rightMouseDown:
            NotificationCenter.default.post(name: .cursorCamClickFeedback, object: nil)
            return Unmanaged.passUnretained(event)
        case .keyDown, .keyUp, .flagsChanged:
            break
        default:
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        // ⌃⌥C — keyCode 8 is 'c' key
        let isControlOptionC = keyCode == 8
            && flags.contains(.maskControl)
            && flags.contains(.maskAlternate)

        let supersetModifiers: CGEventFlags = [.maskShift, .maskCommand, .maskSecondaryFn]
        let hasSupersetModifiers = !flags.intersection(supersetModifiers).isEmpty

        guard isControlOptionC, !hasSupersetModifiers else {
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .keyDown:
            if !isShortcutPressed {
                isShortcutPressed = true
                toggleHandler?()
            }
        case .keyUp:
            isShortcutPressed = false
        case .flagsChanged:
            break
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }
}
