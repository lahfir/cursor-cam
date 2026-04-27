import Foundation
import Combine

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
}

enum BorderStyle: String, CaseIterable {
    case none
    case solid
    case dashed
}

enum CameraSize: String, CaseIterable {
    case small
    case medium
    case large

    var baseSize: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 120
        case .large: return 180
        }
    }
}

extension CameraShape {
    func dimensions(for size: CameraSize) -> (width: CGFloat, height: CGFloat) {
        let base = size.baseSize
        return switch self {
        case .circle, .roundedSquare:
            (base, base)
        case .horizontal:
            (base * 1.5, base * 0.65)
        case .vertical:
            (base * 0.65, base)
        }
    }

    func cornerRadius(for size: CameraSize) -> CGFloat {
        switch self {
        case .circle:
            return dimensions(for: size).width / 2
        case .roundedSquare:
            return 8
        case .horizontal, .vertical:
            return 6
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectedCameraUniqueID: String? {
        didSet { write(.cameraUniqueID, selectedCameraUniqueID) }
    }
    @Published var positioningMode: PositioningMode {
        didSet { write(.positioningMode, positioningMode.rawValue) }
    }
    @Published var pinnedCorner: Corner {
        didSet { write(.pinnedCorner, pinnedCorner.rawValue) }
    }
    @Published var cursorPosition: CursorPosition {
        didSet { write(.cursorPosition, cursorPosition.rawValue) }
    }
    @Published var cameraShape: CameraShape {
        didSet { write(.cameraShape, cameraShape.rawValue) }
    }
    @Published var cameraSize: CameraSize {
        didSet { write(.cameraSize, cameraSize.rawValue) }
    }
    @Published var isMirrored: Bool {
        didSet { write(.isMirrored, isMirrored) }
    }
    @Published var borderStyle: BorderStyle {
        didSet { write(.borderStyle, borderStyle.rawValue) }
    }
    @Published var borderWidth: CGFloat {
        didSet { write(.borderWidth, borderWidth) }
    }
    @Published var freeDragPosition: CGPoint? {
        didSet {
            defaults.set(freeDragPosition?.x, forKey: Keys.freeDragPositionX.rawValue)
            defaults.set(freeDragPosition?.y, forKey: Keys.freeDragPositionY.rawValue)
        }
    }
    @Published var isCamOn = false

    private let defaults = UserDefaults.standard

    init() {
        self.positioningMode = Self.read(.positioningMode, default: .followCursor)
        self.pinnedCorner = Self.read(.pinnedCorner, default: .bottomRight)
        self.cursorPosition = Self.read(.cursorPosition, default: .center)
        self.cameraShape = Self.read(.cameraShape, default: .circle)
        self.cameraSize = Self.read(.cameraSize, default: .medium)
        self.isMirrored = defaults.object(forKey: Keys.isMirrored.rawValue) as? Bool ?? true
        self.borderStyle = Self.read(.borderStyle, default: .none)
        self.borderWidth = defaults.object(forKey: Keys.borderWidth.rawValue) as? CGFloat ?? 2
        self.selectedCameraUniqueID = defaults.string(forKey: Keys.cameraUniqueID.rawValue)

        if let x = defaults.object(forKey: Keys.freeDragPositionX.rawValue) as? CGFloat,
           let y = defaults.object(forKey: Keys.freeDragPositionY.rawValue) as? CGFloat {
            self.freeDragPosition = CGPoint(x: x, y: y)
        } else {
            self.freeDragPosition = nil
        }
    }

    private func write<T>(_ key: Keys, _ value: T?) {
        if let value {
            defaults.set(value, forKey: key.rawValue)
        } else {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    private static func read<T: RawRepresentable>(_ key: Keys, default: T) -> T where T.RawValue == String {
        guard let raw = UserDefaults.standard.string(forKey: key.rawValue),
              let value = T(rawValue: raw) else { return `default` }
        return value
    }
}

private enum Keys: String {
    case cameraUniqueID
    case positioningMode
    case pinnedCorner
    case cursorPosition
    case cameraShape
    case cameraSize
    case isMirrored
    case borderStyle
    case borderWidth
    case freeDragPositionX
    case freeDragPositionY
}
