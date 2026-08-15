import XCTest
@testable import OpenNotch

final class OpenNotchTests: XCTestCase {
    func testConstants() {
        XCTAssertEqual(NotchConstants.defaultCompactWidth, 210)
        XCTAssertEqual(NotchConstants.defaultCompactHeight, 34)
        XCTAssertGreaterThan(NotchConstants.defaultExpandedWidth, NotchConstants.defaultCompactWidth)
    }
    
    func testWidgetTabs() {
        XCTAssertEqual(WidgetTab.allCases.count, 9)
        XCTAssertEqual(WidgetTab.media.rawValue, "Media")
        XCTAssertEqual(WidgetTab.dropShelf.rawValue, "Drop Shelf")
        XCTAssertEqual(WidgetTab.mirror.rawValue, "Mirror")
        XCTAssertEqual(WidgetTab.timer.rawValue, "Timer")
        XCTAssertEqual(WidgetTab.bluetooth.rawValue, "Devices")
        XCTAssertEqual(WidgetTab.pipelines.rawValue, "Shortcuts")
        XCTAssertEqual(WidgetTab.devHUD.rawValue, "Dev HUD")
        XCTAssertEqual(WidgetTab.calendar.rawValue, "Calendar")
        XCTAssertEqual(WidgetTab.settings.rawValue, "Settings")
    }
    
    func testTimerService() {
        let timer = NotchTimerService.shared
        timer.setCountdown(minutes: 5)
        XCTAssertEqual(timer.totalSeconds, 300)
        XCTAssertEqual(timer.remainingSeconds, 300)
        XCTAssertEqual(timer.displayString, "05:00")
    }
    
    func testUserPreferences() {
        let prefs = UserPreferences.shared
        XCTAssertNotNil(prefs)
        XCTAssertGreaterThan(prefs.expandedWidth, 400)
    }
}
