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
        XCTAssertEqual(store.cameraShape, .circle)
        XCTAssertEqual(store.cameraSize, .medium)
        XCTAssertTrue(store.isMirrored)
        XCTAssertNil(store.selectedCameraUniqueID)
        XCTAssertNil(store.freeDragPosition)
        XCTAssertFalse(store.isCamOn)
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
        XCTAssertEqual(reloaded.cameraSize.pixelValue, 180)
        XCTAssertEqual(reloaded.cameraSize.cornerRadius, 30)
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

    func testSelectedCameraUniqueIDNilRoundTrip() {
        let store = SettingsStore()
        store.selectedCameraUniqueID = "some-id"
        store.selectedCameraUniqueID = nil

        let reloaded = SettingsStore()
        XCTAssertNil(reloaded.selectedCameraUniqueID)
    }

    func testFreeDragPositionRoundTrip() {
        let store = SettingsStore()
        let point = CGPoint(x: 500, y: 300)
        store.freeDragPosition = point

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.freeDragPosition?.x, 500)
        XCTAssertEqual(reloaded.freeDragPosition?.y, 300)
    }

    func testFreeDragPositionNegativeCoordinates() {
        let store = SettingsStore()
        let point = CGPoint(x: -100, y: -200)
        store.freeDragPosition = point

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.freeDragPosition?.x, -100)
        XCTAssertEqual(reloaded.freeDragPosition?.y, -200)
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

    func testCameraSizePixelValues() {
        XCTAssertEqual(CameraSize.small.pixelValue, 80)
        XCTAssertEqual(CameraSize.medium.pixelValue, 120)
        XCTAssertEqual(CameraSize.large.pixelValue, 180)
    }

    func testRapidSuccessiveWritesDontLoseValues() {
        let store = SettingsStore()
        store.cameraSize = .large
        store.cameraSize = .small
        store.cameraShape = .roundedSquare
        store.positioningMode = .freeDrag

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.cameraSize, .small)
        XCTAssertEqual(reloaded.cameraShape, .roundedSquare)
        XCTAssertEqual(reloaded.positioningMode, .freeDrag)
    }
}
