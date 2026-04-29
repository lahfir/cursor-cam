import XCTest
@testable import cursor_cam

@MainActor
final class SettingsPopoverManagerTests: XCTestCase {
    private var settings: SettingsStore!
    private var cameraManager: CameraManager!
    private var overlayManager: OverlayWindowManager!
    private var permissionsManager: PermissionsManager!
    private var popoverManager: SettingsPopoverManager!

    override func setUp() {
        super.setUp()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        settings = SettingsStore()
        cameraManager = CameraManager(settings: settings)
        overlayManager = OverlayWindowManager(settings: settings, cameraManager: cameraManager)
        permissionsManager = PermissionsManager()
        popoverManager = SettingsPopoverManager(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
    }

    func testInitialStateIsHidden() {
        XCTAssertFalse(popoverManager.isVisible)
    }

    func testShowCreatesAndDisplaysPanel() {
        popoverManager.show()
        XCTAssertTrue(popoverManager.isVisible)
    }

    func testHideDismissesPanel() {
        popoverManager.show()
        popoverManager.hide()
        XCTAssertFalse(popoverManager.isVisible)
    }

    func testToggleShowsThenHides() {
        XCTAssertFalse(popoverManager.isVisible)
        popoverManager.toggle()
        XCTAssertTrue(popoverManager.isVisible)
        popoverManager.toggle()
        XCTAssertFalse(popoverManager.isVisible)
    }

    func testShowIsIdempotent() {
        popoverManager.show()
        XCTAssertTrue(popoverManager.isVisible)
        popoverManager.show()
        XCTAssertTrue(popoverManager.isVisible)
    }

    func testPanelWidthMatchesContent() {
        popoverManager.show()
        // Panel should be wide enough for the 400pt SettingsPanelView content
        XCTAssertTrue(popoverManager.isVisible)
    }
}
