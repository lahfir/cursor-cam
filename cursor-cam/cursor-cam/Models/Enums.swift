import Foundation

enum PositioningMode: String, CaseIterable {
    case followCursor
    case pinToCorner
    case freeDrag
}

enum Corner: String, CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

enum CursorPosition: String, CaseIterable {
    case center
    case bottomRight
    case bottomLeft
    case topLeft
    case topRight
}

enum CameraShape: String, CaseIterable {
    case circle
    case roundedSquare
    case horizontal
    case vertical

    func dimensions(for size: CameraSize) -> (width: CGFloat, height: CGFloat) {
        let base = size.baseSize
        return switch self {
        case .circle, .roundedSquare: (base, base)
        case .horizontal:             (base * 1.5, base * 0.95)
        case .vertical:               (base * 0.80, base * 1.15)
        }
    }

    func cornerRadius(for size: CameraSize) -> CGFloat {
        let dims = dimensions(for: size)
        switch self {
        case .circle:        return dims.width / 2
        case .roundedSquare: return min(dims.width, dims.height) * 0.32
        case .horizontal, .vertical: return min(dims.width, dims.height) * 0.22
        }
    }
}

enum CameraSize: String, CaseIterable {
    case small
    case medium
    case large
    var baseSize: CGFloat { switch self { case .small: 80; case .medium: 120; case .large: 180 } }
}

enum BorderStyle: String, CaseIterable {
    case none
    case solid
    case dashed
}

enum ShadowIntensity: String, CaseIterable {
    case light
    case medium
    case heavy

    var shadowOpacity: Double {
        switch self {
        case .light:  return 0.15
        case .medium: return 0.30
        case .heavy:  return 0.50
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .light:  return 6
        case .medium: return 12
        case .heavy:  return 20
        }
    }

    var shadowOffset: CGFloat {
        switch self {
        case .light:  return 2
        case .medium: return 4
        case .heavy:  return 6
        }
    }
}
