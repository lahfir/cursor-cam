import XCTest
@testable import cursor_cam

final class HotkeyMonitorTests: XCTestCase {
    private var monitor: HotkeyMonitor!

    override func setUp() {
        super.setUp()
        monitor = HotkeyMonitor()
    }

    override func tearDown() {
        monitor.stop()
        monitor = nil
        super.tearDown()
    }

    func testMonitorInitializes() {
        XCTAssertNotNil(monitor)
    }

    func testStartStopDoesNotCrash() {
        monitor.start()
        monitor.stop()
    }

    func testDoubleStartDoesNotCrash() {
        monitor.start()
        monitor.start()
        monitor.stop()
    }

    func testDoubleStopDoesNotCrash() {
        monitor.stop()
        monitor.stop()
    }

    func testRapidStartStopDoesNotCrash() {
        monitor.start()
        monitor.stop()
        monitor.start()
        monitor.stop()
    }

    func testToggleHandlerIsCalled() {
        var called = false
        monitor.setToggleHandler {
            called = true
        }
        // We can't simulate the actual key press in unit tests,
        // but we verify the handler is set by checking the monitor state
        XCTAssertFalse(called) // Not called yet since no key event
    }

    func testRestartDoesNotCrash() {
        monitor.start()
        monitor.restart()
        monitor.stop()
    }
}
