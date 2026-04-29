import XCTest
@testable import cursor_cam

@MainActor
final class SettingsStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func testDefaultValuesOnFreshInstall() {
        let store = SettingsStore()

        XCTAssertEqual(store.positioningMode, .followCursor)
        XCTAssertEqual(store.pinnedCorner, .bottomRight)
        XCTAssertEqual(store.cursorPosition, .center)
        XCTAssertEqual(store.cameraShape, .circle)
        XCTAssertEqual(store.cameraSize, .medium)
        XCTAssertTrue(store.isMirrored)
        XCTAssertEqual(store.borderStyle, .none)
        XCTAssertEqual(store.borderWidth, 2)
        XCTAssertNil(store.selectedCameraUniqueID)
        XCTAssertNil(store.freeDragPosition)
        XCTAssertFalse(store.isCamOn)

        // v1.5 defaults
        XCTAssertEqual(store.baseOpacity, 1.0)
        XCTAssertTrue(store.shadowEnabled)
        XCTAssertEqual(store.shadowIntensity, .medium)
        XCTAssertTrue(store.velocityScalingEnabled)
        XCTAssertTrue(store.idleDimEnabled)
        XCTAssertEqual(store.idleTimeoutSeconds, 3.0)
        XCTAssertEqual(store.idleDimmedOpacity, 0.3)
        XCTAssertTrue(store.clickFeedbackEnabled)
    }

    func testCursorPositionPersistsRoundTrip() {
        let store = SettingsStore()
        store.cursorPosition = .bottomRight

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.cursorPosition, .bottomRight)
    }

    func testBorderStylePersistsRoundTrip() {
        let store = SettingsStore()
        store.borderStyle = .dashed

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.borderStyle, .dashed)
    }

    func testBorderWidthPersistsRoundTrip() {
        let store = SettingsStore()
        store.borderWidth = 4

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.borderWidth, 4)
    }

    func testPositioningModePersistsRoundTrip() {
        let store = SettingsStore()
        store.positioningMode = .pinToCorner

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.positioningMode, .pinToCorner)
    }

    func testPinnedCornerPersistsRoundTrip() {
        let store = SettingsStore()
        store.pinnedCorner = .topLeft

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.pinnedCorner, .topLeft)
    }

    func testCameraShapePersistsRoundTrip() {
        let store = SettingsStore()
        store.cameraShape = .roundedSquare

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.cameraShape, .roundedSquare)
    }

    func testCameraSizePersistsRoundTrip() {
        let store = SettingsStore()
        store.cameraSize = .large

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.cameraSize, .large)
    }

    func testIsMirroredPersistsRoundTrip() {
        let store = SettingsStore()
        store.isMirrored = false

        let reloaded = SettingsStore()
        XCTAssertFalse(reloaded.isMirrored)
    }

    func testSelectedCameraUniqueIDRoundTrip() {
        let store = SettingsStore()
        store.selectedCameraUniqueID = "test-camera-id"

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.selectedCameraUniqueID, "test-camera-id")
    }

    func testFreeDragPositionRoundTrip() {
        let store = SettingsStore()
        let point = CGPoint(x: 500, y: 300)
        store.freeDragPosition = point

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.freeDragPosition?.x, 500)
        XCTAssertEqual(reloaded.freeDragPosition?.y, 300)
    }

    func testEnumFallsBackToDefaultOnUnknownRawValue() {
        UserDefaults.standard.set("bogusValue", forKey: "positioningMode")
        let store = SettingsStore()
        XCTAssertEqual(store.positioningMode, .followCursor)
    }

    func testIsCamOnNotPersisted() {
        let store = SettingsStore()
        store.isCamOn = true
        let reloaded = SettingsStore()
        XCTAssertFalse(reloaded.isCamOn)
    }

    func testAllCursorPositionsAreCaseIterable() {
        let positions = CursorPosition.allCases
        XCTAssertEqual(positions.count, 5)
        XCTAssertTrue(positions.contains(.center))
        XCTAssertTrue(positions.contains(.bottomRight))
    }

    func testBaseOpacityPersistsRoundTrip() {
        let store = SettingsStore()
        store.baseOpacity = 0.5

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.baseOpacity, 0.5)
    }

    func testShadowEnabledPersistsRoundTrip() {
        let store = SettingsStore()
        store.shadowEnabled = false

        let reloaded = SettingsStore()
        XCTAssertFalse(reloaded.shadowEnabled)
    }

    func testShadowIntensityPersistsRoundTrip() {
        let store = SettingsStore()
        store.shadowIntensity = .heavy

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.shadowIntensity, .heavy)
    }

    func testVelocityScalingEnabledPersistsRoundTrip() {
        let store = SettingsStore()
        store.velocityScalingEnabled = false

        let reloaded = SettingsStore()
        XCTAssertFalse(reloaded.velocityScalingEnabled)
    }

    func testIdleDimEnabledPersistsRoundTrip() {
        let store = SettingsStore()
        store.idleDimEnabled = false

        let reloaded = SettingsStore()
        XCTAssertFalse(reloaded.idleDimEnabled)
    }

    func testIdleTimeoutSecondsPersistsRoundTrip() {
        let store = SettingsStore()
        store.idleTimeoutSeconds = 7.0

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.idleTimeoutSeconds, 7.0)
    }

    func testIdleDimmedOpacityPersistsRoundTrip() {
        let store = SettingsStore()
        store.idleDimmedOpacity = 0.5

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.idleDimmedOpacity, 0.5)
    }

    func testClickFeedbackEnabledPersistsRoundTrip() {
        let store = SettingsStore()
        store.clickFeedbackEnabled = false

        let reloaded = SettingsStore()
        XCTAssertFalse(reloaded.clickFeedbackEnabled)
    }

    func testAllBorderStylesAreCaseIterable() {
        let styles = BorderStyle.allCases
        XCTAssertEqual(styles.count, 3)
        XCTAssertTrue(styles.contains(.none))
        XCTAssertTrue(styles.contains(.solid))
        XCTAssertTrue(styles.contains(.dashed))
    }

    func testAllShadowIntensitiesAreCaseIterable() {
        let intensities = ShadowIntensity.allCases
        XCTAssertEqual(intensities.count, 3)
        XCTAssertTrue(intensities.contains(.light))
        XCTAssertTrue(intensities.contains(.medium))
        XCTAssertTrue(intensities.contains(.heavy))
    }
}
