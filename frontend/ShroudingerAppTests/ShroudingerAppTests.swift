import XCTest
@testable import ShroudingerApp

final class ShroudingerAppTests: XCTestCase {
    
    var settingsManager: SettingsManager!
    
    override func setUpWithError() throws {
        super.setUp()
        settingsManager = SettingsManager()
    }
    
    override func tearDownWithError() throws {
        settingsManager = nil
        super.tearDown()
    }
    
    func testSettingsManagerInitialization() throws {
        XCTAssertNotNil(settingsManager)
        XCTAssertTrue(settingsManager.encryptedDNSEnabled)
        XCTAssertTrue(settingsManager.blockAdsEnabled)
        XCTAssertTrue(settingsManager.blockTrackersEnabled)
        XCTAssertEqual(settingsManager.selectedDNSProvider, .cloudflare)
    }
    
    func testDNSProviderConfiguration() throws {
        let cloudflareServers = settingsManager.getCurrentDNSServers()
        XCTAssertEqual(cloudflareServers, ["1.1.1.1", "1.0.0.1"])
        
        settingsManager.selectedDNSProvider = .quad9
        let quad9Servers = settingsManager.getCurrentDNSServers()
        XCTAssertEqual(quad9Servers, ["9.9.9.9", "149.112.112.112"])
        
        settingsManager.selectedDNSProvider = .google
        let googleServers = settingsManager.getCurrentDNSServers()
        XCTAssertEqual(googleServers, ["8.8.8.8", "8.8.4.4"])
    }
    
    func testCustomDNSServers() throws {
        settingsManager.selectedDNSProvider = .custom
        settingsManager.customDNSServers = ["1.2.3.4", "5.6.7.8"]
        
        let customServers = settingsManager.getCurrentDNSServers()
        XCTAssertEqual(customServers, ["1.2.3.4", "5.6.7.8"])
    }
    
    func testSettingsPersistence() throws {
        // Change settings
        settingsManager.blockAdsEnabled = false
        settingsManager.selectedDNSProvider = .quad9
        settingsManager.encryptedDNSEnabled = false
        
        // Save settings
        settingsManager.saveSettings()
        
        // Create new instance to test persistence
        let newSettingsManager = SettingsManager()
        
        XCTAssertFalse(newSettingsManager.blockAdsEnabled)
        XCTAssertEqual(newSettingsManager.selectedDNSProvider, .quad9)
        XCTAssertFalse(newSettingsManager.encryptedDNSEnabled)
    }
    
    func testResetToDefaults() throws {
        // Change settings
        settingsManager.blockAdsEnabled = false
        settingsManager.selectedDNSProvider = .google
        settingsManager.encryptedDNSEnabled = false
        
        // Reset to defaults
        settingsManager.resetToDefaults()
        
        // Verify defaults
        XCTAssertTrue(settingsManager.blockAdsEnabled)
        XCTAssertTrue(settingsManager.blockTrackersEnabled)
        XCTAssertTrue(settingsManager.encryptedDNSEnabled)
        XCTAssertEqual(settingsManager.selectedDNSProvider, .cloudflare)
    }
    
    func testConstants() throws {
        XCTAssertEqual(Constants.appName, "Shroudinger DNS Privacy")
        XCTAssertEqual(Constants.appBundleId, "com.shroudinger.app")
        XCTAssertEqual(Constants.extensionBundleId, "com.shroudinger.app.extension")
        
        XCTAssertEqual(Constants.DNSServers.cloudflare, ["1.1.1.1", "1.0.0.1"])
        XCTAssertEqual(Constants.DNSServers.quad9, ["9.9.9.9", "149.112.112.112"])
        XCTAssertEqual(Constants.DNSServers.google, ["8.8.8.8", "8.8.4.4"])
        
        XCTAssertEqual(Constants.Network.dnsPort, 53)
        XCTAssertEqual(Constants.Network.dotPort, 853)
        XCTAssertEqual(Constants.Network.dohPort, 443)
    }
}