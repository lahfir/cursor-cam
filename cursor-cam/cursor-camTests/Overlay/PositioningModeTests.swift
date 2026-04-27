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

    func testDefaultCursorPositionIsCenter() {
        XCTAssertEqual(settings.cursorPosition, .center)
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

    func testCamPositionWithCenterOffset() {
        guard let screen = NSScreen.main else { return }
        settings.cursorPosition = .center
        let pos = overlayManager.camPosition(for: screen)
        let mouse = NSEvent.mouseLocation
        let expected = convertForTest(mouse, screen: screen)
        XCTAssertEqual(pos.x, expected.x, accuracy: 0.1)
        XCTAssertEqual(pos.y, expected.y, accuracy: 0.1)
    }

    func testCamPositionWithBottomRightOffset() {
        guard let screen = NSScreen.main else { return }
        settings.cursorPosition = .bottomRight
        settings.cameraSize = .medium
        let pos = overlayManager.camPosition(for: screen)
        let mouse = NSEvent.mouseLocation
        let base = convertForTest(mouse, screen: screen)
        let dims = CameraShape.circle.dimensions(for: .medium)
        let halfW = dims.width / 2
        let halfH = dims.height / 2
        XCTAssertEqual(pos.x, base.x + halfW + 8, accuracy: 0.1)
        XCTAssertEqual(pos.y, base.y + halfH + 8, accuracy: 0.1)
    }

    func testAllCursorPositionsAreCaseIterable() {
        let positions = CursorPosition.allCases
        XCTAssertEqual(positions.count, 5)
        XCTAssertTrue(positions.contains(.center))
        XCTAssertTrue(positions.contains(.bottomRight))
        XCTAssertTrue(positions.contains(.bottomLeft))
        XCTAssertTrue(positions.contains(.topLeft))
        XCTAssertTrue(positions.contains(.topRight))
    }

    func testAllPositioningModesAreCaseIterable() {
        let modes = PositioningMode.allCases
        XCTAssertEqual(modes.count, 3)
        XCTAssertTrue(modes.contains(.followCursor))
        XCTAssertTrue(modes.contains(.pinToCorner))
        XCTAssertTrue(modes.contains(.freeDrag))
    }

    private func convertForTest(_ point: CGPoint, screen: NSScreen) -> CGPoint {
        let x = point.x - screen.frame.origin.x
        let y = (screen.frame.origin.y + screen.frame.height) - point.y
        return CGPoint(x: x, y: y)
    }
}

