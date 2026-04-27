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
    case verticalPill
    case horizontalPill
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
        case .verticalPill:
            (base * 0.75, base * 1.33)
        case .horizontalPill:
            (base * 1.33, base * 0.75)
        }
    }

    func cornerRadius(for size: CameraSize) -> CGFloat {
        let dims = dimensions(for: size)
        let smaller = min(dims.width, dims.height)
        return switch self {
        case .circle:
            smaller / 2
        case .roundedSquare:
            smaller * 0.18
        case .verticalPill:
            smaller / 2
        case .horizontalPill:
            smaller / 2
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectedCameraUniqueID: String? {
        didSet { write(key: .cameraUniqueID, value: selectedCameraUniqueID) }
    }
    @Published var positioningMode: PositioningMode {
        didSet { write(key: .positioningMode, value: positioningMode.rawValue) }
    }
    @Published var pinnedCorner: Corner {
        didSet { write(key: .pinnedCorner, value: pinnedCorner.rawValue) }
    }
    @Published var cursorPosition: CursorPosition {
        didSet { write(key: .cursorPosition, value: cursorPosition.rawValue) }
    }
    @Published var cameraShape: CameraShape {
        didSet { write(key: .cameraShape, value: cameraShape.rawValue) }
    }
    @Published var cameraSize: CameraSize {
        didSet { write(key: .cameraSize, value: cameraSize.rawValue) }
    }
    @Published var isMirrored: Bool {
        didSet { write(key: .isMirrored, value: isMirrored) }
    }
    @Published var borderStyle: BorderStyle {
        didSet { write(key: .borderStyle, value: borderStyle.rawValue) }
    }
    @Published var borderWidth: CGFloat {
        didSet { write(key: .borderWidth, value: borderWidth) }
    }
    @Published var isGlowEnabled: Bool {
        didSet { write(key: .isGlowEnabled, value: isGlowEnabled) }
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
        self.positioningMode = Self.readEnum(key: .positioningMode, defaultValue: .followCursor)
        self.pinnedCorner = Self.readEnum(key: .pinnedCorner, defaultValue: .bottomRight)
        self.cursorPosition = Self.readEnum(key: .cursorPosition, defaultValue: .center)
        self.cameraShape = Self.readEnum(key: .cameraShape, defaultValue: .circle)
        self.cameraSize = Self.readEnum(key: .cameraSize, defaultValue: .medium)
        self.isMirrored = defaults.object(forKey: Keys.isMirrored.rawValue) as? Bool ?? true
        self.borderStyle = Self.readEnum(key: .borderStyle, defaultValue: .none)
        self.borderWidth = defaults.object(forKey: Keys.borderWidth.rawValue) as? CGFloat ?? 2
        self.isGlowEnabled = defaults.object(forKey: Keys.isGlowEnabled.rawValue) as? Bool ?? false
        self.selectedCameraUniqueID = defaults.string(forKey: Keys.cameraUniqueID.rawValue)

        if let x = defaults.object(forKey: Keys.freeDragPositionX.rawValue) as? CGFloat,
           let y = defaults.object(forKey: Keys.freeDragPositionY.rawValue) as? CGFloat {
            self.freeDragPosition = CGPoint(x: x, y: y)
        } else {
            self.freeDragPosition = nil
        }
    }

    private func write<T>(key: Keys, value: T?) {
        if let value {
            defaults.set(value, forKey: key.rawValue)
        } else {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    private static func readEnum<T: RawRepresentable>(
        key: Keys,
        defaultValue: T
    ) -> T where T.RawValue == String {
        guard let raw = UserDefaults.standard.string(forKey: key.rawValue),
              let value = T(rawValue: raw) else {
            return defaultValue
        }
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
    case isGlowEnabled
    case freeDragPositionX
    case freeDragPositionY
}
