import XCTest
@testable import cursor_cam

@MainActor
final class CamBehaviorControllerTests: XCTestCase {
    private var settings: SettingsStore!
    private var controller: CamBehaviorController!

    override func setUp() {
        super.setUp()
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        settings = SettingsStore()
        controller = CamBehaviorController(settings: settings)
    }

    // MARK: - Velocity Scale

    func testVelocityScaleDefaultsToOne() {
        XCTAssertEqual(controller.velocityScale, 1.0)
    }

    func testVelocityScaleDisabledWhenVelocityScalingOff() {
        settings.velocityScalingEnabled = false
        settings.positioningMode = .followCursor

        for i in 0..<10 {
            controller.tick(mouseLocation: CGPoint(x: CGFloat(i) * 100, y: 0))
        }

        XCTAssertEqual(controller.velocityScale, 1.0)
    }

    func testVelocityScaleDisabledInPinToCornerMode() {
        settings.positioningMode = .pinToCorner
        settings.velocityScalingEnabled = true

        for i in 0..<10 {
            controller.tick(mouseLocation: CGPoint(x: CGFloat(i) * 100, y: 0))
        }

        XCTAssertEqual(controller.velocityScale, 1.0)
    }

    func testResetClearsVelocityScale() {
        controller.tick(mouseLocation: CGPoint(x: 0, y: 0))
        controller.reset()
        XCTAssertEqual(controller.velocityScale, 1.0)
    }

    // MARK: - Idle Dim

    func testIdleDimMultiplierDefaultsToOne() {
        XCTAssertEqual(controller.idleDimMultiplier, 1.0)
    }

    func testIdleDimDisabledWhenIdleDimOff() {
        settings.idleDimEnabled = false
        settings.positioningMode = .followCursor

        controller.tick(mouseLocation: CGPoint(x: 0, y: 0))
        XCTAssertEqual(controller.idleDimMultiplier, 1.0)
    }

    func testIdleDimDisabledInFreeDragMode() {
        settings.positioningMode = .freeDrag
        settings.idleDimEnabled = true

        controller.tick(mouseLocation: CGPoint(x: 0, y: 0))
        XCTAssertEqual(controller.idleDimMultiplier, 1.0)
    }

    func testResetClearsIdleDimMultiplier() {
        controller.tick(mouseLocation: CGPoint(x: 0, y: 0))
        controller.reset()
        XCTAssertEqual(controller.idleDimMultiplier, 1.0)
    }
}
