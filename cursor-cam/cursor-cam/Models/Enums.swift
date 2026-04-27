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
        case .horizontal:             (base * 1.5, base * 0.65)
        case .vertical:               (base * 0.65, base)
        }
    }

    func cornerRadius(for size: CameraSize) -> CGFloat {
        switch self {
        case .circle:        return dimensions(for: size).width / 2
        case .roundedSquare: return 8
        case .horizontal, .vertical: return 6
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
