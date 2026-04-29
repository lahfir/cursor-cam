import AppKit
import Foundation

@MainActor
struct CamPositionResolver {
    let settings: SettingsStore

    static let camGap: CGFloat = 8
    static let cornerMargin: CGFloat = 20
    static let edgeBandFraction: CGFloat = 0.22

    func position(for mode: PositioningMode, screen: NSScreen) -> CGPoint {
        switch mode {
        case .followCursor: return follow(for: screen)
        case .pinToCorner:  return corner(settings.pinnedCorner, screen: screen)
        case .freeDrag:
            if let pos = settings.freeDragPosition { return pos }
            let snapshot = corner(settings.pinnedCorner, screen: screen)
            settings.freeDragPosition = snapshot
            return snapshot
        }
    }

    func follow(for screen: NSScreen) -> CGPoint {
        let mouse = NSEvent.mouseLocation
        let base = toLocal(mouse, screen: screen)
        let dims = settings.cameraShape.dimensions(for: settings.cameraSize)
        let halfW = dims.width / 2
        let halfH = dims.height / 2
        let gap = Self.camGap

        guard settings.edgeAwareOffsetEnabled else {
            return manual(base: base, halfW: halfW, halfH: halfH, gap: gap)
        }
        let (dx, dy) = edgeSign(mouse: mouse, screen: screen)
        if dx == 0 && dy == 0 {
            return manual(base: base, halfW: halfW, halfH: halfH, gap: gap)
        }
        return CGPoint(x: base.x + dx * (halfW + gap), y: base.y + dy * (halfH + gap))
    }

    func corner(_ c: Corner, screen: NSScreen) -> CGPoint {
        let margin = Self.cornerMargin
        let dims = settings.cameraShape.dimensions(for: settings.cameraSize)
        let halfW = dims.width / 2
        let halfH = dims.height / 2
        let frame = screen.frame
        return switch c {
        case .topLeft:     CGPoint(x: margin + halfW, y: margin + halfH)
        case .topRight:    CGPoint(x: frame.width - margin - halfW, y: margin + halfH)
        case .bottomLeft:  CGPoint(x: margin + halfW, y: frame.height - margin - halfH)
        case .bottomRight: CGPoint(x: frame.width - margin - halfW, y: frame.height - margin - halfH)
        }
    }

    private func manual(base: CGPoint, halfW: CGFloat, halfH: CGFloat, gap: CGFloat) -> CGPoint {
        switch settings.cursorPosition {
        case .center:      return base
        case .bottomRight: return CGPoint(x: base.x + halfW + gap, y: base.y + halfH + gap)
        case .bottomLeft:  return CGPoint(x: base.x - halfW - gap, y: base.y + halfH + gap)
        case .topLeft:     return CGPoint(x: base.x - halfW - gap, y: base.y - halfH - gap)
        case .topRight:    return CGPoint(x: base.x + halfW + gap, y: base.y - halfH - gap)
        }
    }

    private func edgeSign(mouse: CGPoint, screen: NSScreen) -> (CGFloat, CGFloat) {
        let frame = screen.frame
        let bandX = frame.width * Self.edgeBandFraction
        let bandY = frame.height * Self.edgeBandFraction
        let relX = mouse.x - frame.minX
        let relY = mouse.y - frame.minY

        var dx: CGFloat = 0
        if relX < bandX { dx = +1 }
        else if relX > frame.width - bandX { dx = -1 }

        var dy: CGFloat = 0
        if relY > frame.height - bandY { dy = +1 }
        else if relY < bandY { dy = -1 }

        return (dx, dy)
    }

    private func toLocal(_ point: CGPoint, screen: NSScreen) -> CGPoint {
        CGPoint(
            x: point.x - screen.frame.origin.x,
            y: (screen.frame.origin.y + screen.frame.height) - point.y
        )
    }
}
