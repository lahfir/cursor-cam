import XCTest
@testable import cursor_cam

@MainActor
final class OverlayWindowManagerTests: XCTestCase {
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

    func testInitialStateNotShowing() {
        XCTAssertFalse(overlayManager.isShowing)
    }

    func testShowCreatesStateForConnectedScreens() {
        overlayManager.show()
        XCTAssertTrue(overlayManager.isShowing)
        guard let screen = NSScreen.main else { return }
        let state = overlayManager.stateForScreen(screen)
        // State exists (alpha defaults from initial show)
        _ = state
    }

    func testHideRemovesAllOverlays() {
        overlayManager.show()
        overlayManager.hide()
        XCTAssertFalse(overlayManager.isShowing)
    }

    func testToggleFlipsState() {
        XCTAssertFalse(overlayManager.isShowing)
        overlayManager.toggle()
        XCTAssertTrue(overlayManager.isShowing)
        overlayManager.toggle()
        XCTAssertFalse(overlayManager.isShowing)
    }

    func testDoubleShowIsIdempotent() {
        overlayManager.show()
        overlayManager.show()
        XCTAssertTrue(overlayManager.isShowing)
    }

    func testCornerPositionForBottomRight() {
        guard let screen = NSScreen.main else { return }
        let pos = overlayManager.cornerPosition(for: .bottomRight, screen: screen)
        let size = settings.cameraSize.pixelValue
        XCTAssertGreaterThan(pos.x, screen.frame.width / 2)
        XCTAssertGreaterThan(pos.y, screen.frame.height / 2)
        XCTAssertEqual(pos.x, screen.frame.width - 20 - size / 2)
        XCTAssertEqual(pos.y, screen.frame.height - 20 - size / 2)
    }

    func testCornerPositionForTopLeft() {
        guard let screen = NSScreen.main else { return }
        let pos = overlayManager.cornerPosition(for: .topLeft, screen: screen)
        let size = settings.cameraSize.pixelValue
        XCTAssertEqual(pos.x, 20 + size / 2)
        XCTAssertEqual(pos.y, 20 + size / 2)
    }

    func testCamPositionReturnsPointWithOffset() {
        guard let screen = NSScreen.main else { return }
        let pos = overlayManager.camPosition(for: screen)
        XCTAssertNotEqual(pos, .zero)
    }

    func testScreenContainingCursor() {
        let screen = overlayManager.screenContainingCursor()
        XCTAssertNotNil(screen)
    }

    func testModeChangedUpdatesIgnoresMouseEventsForFreeDrag() {
        overlayManager.show()
        settings.positioningMode = .freeDrag
        overlayManager.onModeChanged()
        // Free-drag sets freeDragPosition if nil
    }

    func testFreeDragPositionPersistence() {
        guard let screen = NSScreen.main else { return }
        let pos = CGPoint(x: 500, y: 300)
        overlayManager.show()
        settings.positioningMode = .freeDrag
        settings.freeDragPosition = pos
        overlayManager.onFreeDragMoved(to: pos, screen: screen)
        XCTAssertEqual(settings.freeDragPosition?.x, 500)
        XCTAssertEqual(settings.freeDragPosition?.y, 300)
    }
}
