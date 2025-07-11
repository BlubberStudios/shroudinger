import XCTest

final class ShroudingerAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testMainWindowExists() throws {
        // Test that the main window exists
        XCTAssertTrue(app.windows.firstMatch.exists)
    }
    
    func testAppTitle() throws {
        // Test that the app title is displayed
        let titleText = app.staticTexts["Shroudinger DNS Privacy"]
        XCTAssertTrue(titleText.exists)
    }
    
    func testToggleControls() throws {
        // Test DNS Protection toggle
        let dnsProtectionToggle = app.switches["DNS Protection"]
        if dnsProtectionToggle.exists {
            dnsProtectionToggle.click()
        }
        
        // Test Encrypted DNS toggle
        let encryptedDNSToggle = app.switches["Encrypted DNS"]
        if encryptedDNSToggle.exists {
            encryptedDNSToggle.click()
        }
        
        // Test Block Ads toggle
        let blockAdsToggle = app.switches["Block Ads"]
        if blockAdsToggle.exists {
            blockAdsToggle.click()
        }
        
        // Test Block Trackers toggle
        let blockTrackersToggle = app.switches["Block Trackers"]
        if blockTrackersToggle.exists {
            blockTrackersToggle.click()
        }
    }
    
    func testActionButtons() throws {
        // Test Settings button
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        
        // Test View Logs button
        let viewLogsButton = app.buttons["View Logs"]
        XCTAssertTrue(viewLogsButton.exists)
    }
    
    func testStatisticsDisplay() throws {
        // Test that statistics are displayed
        let blockedText = app.staticTexts["Blocked"]
        let totalQueriesText = app.staticTexts["Total Queries"]
        let blockedRateText = app.staticTexts["Blocked Rate"]
        
        XCTAssertTrue(blockedText.exists)
        XCTAssertTrue(totalQueriesText.exists)
        XCTAssertTrue(blockedRateText.exists)
    }
    
    func testProtectionStatusDisplay() throws {
        // Test that protection status is displayed
        let protectionActiveText = app.staticTexts["Protection Active"]
        let protectionInactiveText = app.staticTexts["Protection Inactive"]
        
        // One of these should exist
        XCTAssertTrue(protectionActiveText.exists || protectionInactiveText.exists)
    }
}