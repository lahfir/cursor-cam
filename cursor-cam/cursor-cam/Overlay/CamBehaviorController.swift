import AppKit
import Combine
import SwiftUI

/// Encapsulates dynamic cam behaviors: velocity-based scaling and idle auto-dim.
/// Owned by OverlayWindowManager and updated on every positioning tick.
@MainActor
final class CamBehaviorController: ObservableObject {
    @Published private(set) var velocityScale: CGFloat = 1.0
    @Published private(set) var idleDimMultiplier: CGFloat = 1.0

    private let settings: SettingsStore

    // MARK: - Velocity Tracking
    private var cursorSampleBuffer: [(point: CGPoint, time: Date)] = []
    private static let velocitySampleCount = 6
    private static let velocityMin: CGFloat = 200
    private static let velocityMax: CGFloat = 800
    private static let maxScaleMultiplier: CGFloat = 1.15

    // MARK: - Idle Dimming
    private var lastCursorMoveTime: Date = .distantPast
    private var isIdleDimmed = false

    init(settings: SettingsStore) {
        self.settings = settings
    }

    // MARK: - Tick

    func tick(mouseLocation: CGPoint) {
        updateVelocityTracking(mouseLocation: mouseLocation)
        updateIdleDimming(mouseLocation: mouseLocation)
    }

    func reset() {
        velocityScale = 1.0
        idleDimMultiplier = 1.0
        cursorSampleBuffer.removeAll()
        isIdleDimmed = false
    }

    // MARK: - Velocity

    private func updateVelocityTracking(mouseLocation: CGPoint) {
        let now = Date()
        cursorSampleBuffer.append((mouseLocation, now))
        if cursorSampleBuffer.count > Self.velocitySampleCount {
            cursorSampleBuffer.removeFirst()
        }

        guard settings.velocityScalingEnabled,
              settings.positioningMode == .followCursor else {
            velocityScale = 1.0
            return
        }

        guard let oldest = cursorSampleBuffer.first,
              let newest = cursorSampleBuffer.last,
              newest.time > oldest.time else {
            velocityScale = 1.0
            return
        }

        let distance = hypot(newest.point.x - oldest.point.x, newest.point.y - oldest.point.y)
        let timeDelta = newest.time.timeIntervalSince(oldest.time)
        guard timeDelta > 0 else {
            velocityScale = 1.0
            return
        }

        let velocity = CGFloat(distance / timeDelta)
        let targetScale = scaleForVelocity(velocity)

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            velocityScale = targetScale
        } else {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0)) {
                velocityScale = targetScale
            }
        }
    }

    private func scaleForVelocity(_ velocity: CGFloat) -> CGFloat {
        if velocity <= Self.velocityMin { return 1.0 }
        if velocity >= Self.velocityMax { return Self.maxScaleMultiplier }
        let t = (velocity - Self.velocityMin) / (Self.velocityMax - Self.velocityMin)
        return 1.0 + t * (Self.maxScaleMultiplier - 1.0)
    }

    // MARK: - Idle Dimming

    private func updateIdleDimming(mouseLocation: CGPoint) {
        let now = Date()

        if cursorSampleBuffer.count >= 2 {
            let lastPos = cursorSampleBuffer[cursorSampleBuffer.count - 2].point
            let moved = hypot(mouseLocation.x - lastPos.x, mouseLocation.y - lastPos.y) > 1
            if moved {
                lastCursorMoveTime = now
                if isIdleDimmed {
                    isIdleDimmed = false
                    applyIdleDimAnimation(target: 1.0, duration: 0.2)
                }
            }
        }

        guard settings.idleDimEnabled else {
            if isIdleDimmed {
                isIdleDimmed = false
                applyIdleDimAnimation(target: 1.0, duration: 0.2)
            }
            return
        }

        if settings.positioningMode == .freeDrag {
            if isIdleDimmed {
                isIdleDimmed = false
                applyIdleDimAnimation(target: 1.0, duration: 0.2)
            }
            return
        }

        let idleDuration = now.timeIntervalSince(lastCursorMoveTime)
        let shouldBeDimmed = idleDuration >= settings.idleTimeoutSeconds

        if shouldBeDimmed && !isIdleDimmed {
            isIdleDimmed = true
            applyIdleDimAnimation(target: CGFloat(settings.idleDimmedOpacity), duration: 0.4)
        } else if !shouldBeDimmed && isIdleDimmed {
            isIdleDimmed = false
            applyIdleDimAnimation(target: 1.0, duration: 0.2)
        }
    }

    private func applyIdleDimAnimation(target: CGFloat, duration: TimeInterval) {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            idleDimMultiplier = target
        } else {
            withAnimation(.easeInOut(duration: duration)) {
                idleDimMultiplier = target
            }
        }
    }
}
