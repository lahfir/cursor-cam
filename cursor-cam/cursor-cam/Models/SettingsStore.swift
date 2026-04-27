import Foundation
import Combine

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
    @Published var baseOpacity: Double {
        didSet { write(.baseOpacity, baseOpacity) }
    }
    @Published var shadowEnabled: Bool {
        didSet { write(.shadowEnabled, shadowEnabled) }
    }
    @Published var shadowIntensity: ShadowIntensity {
        didSet { write(.shadowIntensity, shadowIntensity.rawValue) }
    }
    @Published var velocityScalingEnabled: Bool {
        didSet { write(.velocityScalingEnabled, velocityScalingEnabled) }
    }
    @Published var idleDimEnabled: Bool {
        didSet { write(.idleDimEnabled, idleDimEnabled) }
    }
    @Published var idleTimeoutSeconds: Double {
        didSet { write(.idleTimeoutSeconds, idleTimeoutSeconds) }
    }
    @Published var idleDimmedOpacity: Double {
        didSet { write(.idleDimmedOpacity, idleDimmedOpacity) }
    }
    @Published var clickFeedbackEnabled: Bool {
        didSet { write(.clickFeedbackEnabled, clickFeedbackEnabled) }
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

        self.baseOpacity = defaults.object(forKey: Keys.baseOpacity.rawValue) as? Double ?? 1.0
        self.shadowEnabled = defaults.object(forKey: Keys.shadowEnabled.rawValue) as? Bool ?? true
        self.shadowIntensity = Self.read(.shadowIntensity, default: .medium)
        self.velocityScalingEnabled = defaults.object(forKey: Keys.velocityScalingEnabled.rawValue) as? Bool ?? true
        self.idleDimEnabled = defaults.object(forKey: Keys.idleDimEnabled.rawValue) as? Bool ?? true
        self.idleTimeoutSeconds = defaults.object(forKey: Keys.idleTimeoutSeconds.rawValue) as? Double ?? 3.0
        self.idleDimmedOpacity = defaults.object(forKey: Keys.idleDimmedOpacity.rawValue) as? Double ?? 0.3
        self.clickFeedbackEnabled = defaults.object(forKey: Keys.clickFeedbackEnabled.rawValue) as? Bool ?? true

        if let x = defaults.object(forKey: Keys.freeDragPositionX.rawValue) as? CGFloat,
           let y = defaults.object(forKey: Keys.freeDragPositionY.rawValue) as? CGFloat {
            self.freeDragPosition = CGPoint(x: x, y: y)
        } else {
            self.freeDragPosition = nil
        }
    }

    private func write<T>(_ key: Keys, _ value: T?) {
        if let value { defaults.set(value, forKey: key.rawValue) }
        else { defaults.removeObject(forKey: key.rawValue) }
    }

    private static func read<T: RawRepresentable>(_ key: Keys, default: T) -> T where T.RawValue == String {
        guard let raw = UserDefaults.standard.string(forKey: key.rawValue),
              let value = T(rawValue: raw) else { return `default` }
        return value
    }
}

private enum Keys: String {
    case cameraUniqueID, positioningMode, pinnedCorner, cursorPosition
    case cameraShape, cameraSize, isMirrored, borderStyle, borderWidth
    case freeDragPositionX, freeDragPositionY
    case baseOpacity, shadowEnabled, shadowIntensity
    case velocityScalingEnabled, idleDimEnabled, idleTimeoutSeconds, idleDimmedOpacity
    case clickFeedbackEnabled
}
