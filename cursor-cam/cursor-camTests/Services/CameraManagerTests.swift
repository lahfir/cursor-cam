import AVFoundation
import XCTest
@testable import cursor_cam

@MainActor
final class CameraManagerTests: XCTestCase {
    private var settings: SettingsStore!
    private var cameraManager: CameraManager!

    override func setUp() {
        super.setUp()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        settings = SettingsStore()
        cameraManager = CameraManager(settings: settings)
    }

    func testInitialStateIsUnavailable() {
        XCTAssertEqual(cameraManager.cameraState, .unavailable)
        XCTAssertNil(cameraManager.currentCamera)
        XCTAssertNil(cameraManager.previewLayer)
    }

    func testAvailableCamerasPopulates() {
        cameraManager.refreshAvailableCameras()
        let cameras = cameraManager.availableCameras
        XCTAssertFalse(cameras.isEmpty, "Expected at least one camera on a Mac")
    }

    func testStartSessionWhenAuthorizedCreatesPreviewLayer() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else { return }

        cameraManager.startSession()

        let expectation = XCTestExpectation(description: "Preview layer created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if cameraManager.previewLayer != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)

        if status == .authorized {
            XCTAssertNotNil(cameraManager.previewLayer)
            XCTAssertEqual(cameraManager.cameraState, .running)
        }
    }

    func testStopSessionTearsDown() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else { return }

        cameraManager.startSession()
        cameraManager.stopSession()

        XCTAssertNil(cameraManager.previewLayer)
        XCTAssertNil(cameraManager.currentCamera)
        XCTAssertEqual(cameraManager.cameraState, .unavailable)
    }

    func testDoubleStartDoesNotCrash() {
        cameraManager.startSession()
        cameraManager.startSession()
    }

    func testRapidStartStopDoesNotCrash() {
        cameraManager.startSession()
        cameraManager.stopSession()
        cameraManager.startSession()
        cameraManager.stopSession()
    }

    func testSelectCameraByNonexistentIDDoesNotChange() {
        cameraManager.selectCamera(by: "nonexistent-id-12345")
        XCTAssertNil(cameraManager.currentCamera)
    }

    func testAutoSelectFirstCameraWhenUniqueIDIsNil() {
        settings.selectedCameraUniqueID = nil
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else { return }

        cameraManager.startSession()

        let expectation = XCTestExpectation(description: "Camera selected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            if cameraManager.currentCamera != nil {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(cameraManager.currentCamera)
    }
}
