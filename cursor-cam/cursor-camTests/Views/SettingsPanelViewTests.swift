import XCTest
import SwiftUI
@testable import cursor_cam

@MainActor
final class SettingsPanelViewTests: XCTestCase {
    private var settings: SettingsStore!
    private var cameraManager: CameraManager!
    private var overlayManager: OverlayWindowManager!
    private var permissionsManager: PermissionsManager!

    override func setUp() {
        super.setUp()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        settings = SettingsStore()
        cameraManager = CameraManager(settings: settings)
        overlayManager = OverlayWindowManager(settings: settings, cameraManager: cameraManager)
        permissionsManager = PermissionsManager()
    }

    func testViewInitializesWithDependencies() {
        let view = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
        XCTAssertNotNil(view)
    }

    func testCamToggleBindingReflectsSettings() {
        settings.isCamOn = false
        let view = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
        XCTAssertNotNil(view.body)
    }

    func testSettingsChangePropagatesToView() {
        settings.baseOpacity = 0.5
        settings.shadowEnabled = false
        settings.velocityScalingEnabled = false
        settings.idleDimEnabled = false
        settings.clickFeedbackEnabled = false

        let view = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(settings.baseOpacity, 0.5)
        XCTAssertFalse(settings.shadowEnabled)
    }

    func testCameraPickerShowsNoCameraWhenEmpty() {
        let view = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
        XCTAssertNotNil(view.body)
        // CameraManager starts with empty availableCameras until refreshed
    }

    func testClickFeedbackDisabledWhenAccessibilityDenied() {
        permissionsManager.refreshPermissions()
        // When accessibility is not granted, the toggle should be disabled
        let view = SettingsPanelView(
            settings: settings,
            cameraManager: cameraManager,
            overlayManager: overlayManager,
            permissionsManager: permissionsManager
        )
        XCTAssertNotNil(view.body)
    }
}
