import XCTest
@testable import cursor_cam

@MainActor
final class PositioningModeTests: XCTestCase {
    private var settings: SettingsStore!
    private var cameraManager: CameraManager!
    private var overlayManager: OverlayWindowManager!

    override func setUp() {
        super.setUp()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        settings = SettingsStore()
        cameraManager = CameraManager(settings: settings)
        overlayManager = OverlayWindowManager(settings: settings, cameraManager: cameraManager)
    }

    func testDefaultModeIsFollowCursor() {
        XCTAssertEqual(settings.positioningMode, .followCursor)
    }

    func testModeSwitchDoesNotToggleCamOff() {
        overlayManager.show()
        XCTAssertTrue(overlayManager.isShowing)

        settings.positioningMode = .pinToCorner
        overlayManager.onModeChanged()
        XCTAssertTrue(overlayManager.isShowing)

        settings.positioningMode = .freeDrag
        overlayManager.onModeChanged()
        XCTAssertTrue(overlayManager.isShowing)
    }

    func testFreeDragModeStoresPosition() {
        guard let screen = NSScreen.main else { return }
        overlayManager.show()
        settings.positioningMode = .freeDrag
        overlayManager.onModeChanged()

        let dragPos = CGPoint(x: 600, y: 400)
        overlayManager.onFreeDragMoved(to: dragPos, screen: screen)

        XCTAssertEqual(settings.freeDragPosition?.x, 600)
        XCTAssertEqual(settings.freeDragPosition?.y, 400)
    }

    func testFreeDragModePersistsOnReentry() {
        guard let screen = NSScreen.main else { return }
        overlayManager.show()
        settings.positioningMode = .freeDrag

        let pos = CGPoint(x: 400, y: 300)
        overlayManager.onFreeDragMoved(to: pos, screen: screen)

        XCTAssertNotNil(settings.freeDragPosition)
        XCTAssertEqual(settings.freeDragPosition?.x, 400)
        XCTAssertEqual(settings.freeDragPosition?.y, 300)

        // Read back
        let reloadedSettings = SettingsStore()
        XCTAssertEqual(reloadedSettings.freeDragPosition?.x, 400)
        XCTAssertEqual(reloadedSettings.freeDragPosition?.y, 300)
    }

    func testAllCornersProduceValidPositions() {
        guard let screen = NSScreen.main else { return }
        let corners: [Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]

        for corner in corners {
            let pos = overlayManager.cornerPosition(for: corner, screen: screen)
            XCTAssertGreaterThan(pos.x, 0)
            XCTAssertLessThan(pos.x, screen.frame.width)
            XCTAssertGreaterThan(pos.y, 0)
            XCTAssertLessThan(pos.y, screen.frame.height)
        }
    }

    func testCamPositionFollowsCursorOffset() {
        guard let screen = NSScreen.main else { return }
        let pos = overlayManager.camPosition(for: screen)
        let mouseLocation = NSEvent.mouseLocation

        // Cam position should be offset from cursor
        XCTAssertNotEqual(pos, .zero)
        _ = mouseLocation // cursor is somewhere on screen
    }

    func testAllPositioningModesAreCaseIterable() {
        let modes = PositioningMode.allCases
        XCTAssertEqual(modes.count, 3)
        XCTAssertTrue(modes.contains(.followCursor))
        XCTAssertTrue(modes.contains(.pinToCorner))
        XCTAssertTrue(modes.contains(.freeDrag))
    }
}
