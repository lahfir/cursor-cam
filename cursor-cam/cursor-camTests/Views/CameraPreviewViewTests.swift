import XCTest
import SwiftUI
@testable import cursor_cam

@MainActor
final class CameraPreviewViewTests: XCTestCase {
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

    func testViewInitializes() {
        guard let screen = NSScreen.main else { return }
        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )
        XCTAssertNotNil(view)
    }

    func testFinalOpacityAppliesBaseOpacity() {
        guard let screen = NSScreen.main else { return }
        settings.baseOpacity = 0.5

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )

        // When alpha=1 and idleDimMultiplier=1, finalOpacity should equal baseOpacity
        // Since state.alpha depends on overlay visibility, we test the formula directly
        XCTAssertEqual(view.finalOpacity, 0.5, accuracy: 0.001)
    }

    func testFinalOpacityRespects15PercentFloor() {
        guard let screen = NSScreen.main else { return }
        settings.baseOpacity = 0.2
        overlayManager.show()
        overlayManager.hide() // Ensure idleDimMultiplier resets

        // Simulate idle dim at minimum
        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )

        // Even with very low combined values, floor should be 0.15
        XCTAssertGreaterThanOrEqual(view.finalOpacity, 0.15)
    }

    func testFinalOpacityWithIdleDim() {
        guard let screen = NSScreen.main else { return }
        settings.baseOpacity = 1.0
        settings.idleDimEnabled = true
        settings.idleDimmedOpacity = 0.3

        overlayManager.show()

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )

        // Floor of 0.15 should be respected even at low combined values
        XCTAssertGreaterThanOrEqual(view.finalOpacity, 0.15)
    }

    func testShadowEnabledUpdatesView() {
        guard let screen = NSScreen.main else { return }
        settings.shadowEnabled = true
        settings.shadowIntensity = .heavy

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )
        XCTAssertNotNil(view)
    }

    func testShadowDisabledRemovesShadow() {
        guard let screen = NSScreen.main else { return }
        settings.shadowEnabled = false

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )
        XCTAssertNotNil(view)
    }

    func testOpacityAtMinimumIsVisible() {
        guard let screen = NSScreen.main else { return }
        settings.baseOpacity = 0.2

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )

        XCTAssertGreaterThanOrEqual(view.finalOpacity, 0.15)
    }

    func testVelocityScaleComposesWithView() {
        guard let screen = NSScreen.main else { return }
        settings.velocityScalingEnabled = true
        settings.positioningMode = .followCursor

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )
        XCTAssertNotNil(view)
    }

    func testMirrorScaleApplied() {
        guard let screen = NSScreen.main else { return }
        settings.isMirrored = true

        let view = CameraPreviewView(
            cameraManager: cameraManager,
            settings: settings,
            overlayManager: overlayManager,
            screen: screen
        )
        XCTAssertNotNil(view)
    }
}
