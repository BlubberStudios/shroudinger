import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    @Published var encryptedDNSEnabled: Bool = true
    @Published var blockAdsEnabled: Bool = true
    @Published var blockTrackersEnabled: Bool = true
    @Published var blockMalwareEnabled: Bool = true
    @Published var allowCustomDNS: Bool = false
    @Published var customDNSServers: [String] = []
    @Published var selectedDNSProvider: DNSProvider = .cloudflare
    @Published var enableLogging: Bool = false
    @Published var autoUpdateBlocklists: Bool = true
    @Published var updateInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private let userDefaults = UserDefaults.standard
    
    // DNS Provider enum
    enum DNSProvider: String, CaseIterable {
        case cloudflare = "1.1.1.1"
        case quad9 = "9.9.9.9"
        case google = "8.8.8.8"
        case openDNS = "208.67.222.222"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .cloudflare:
                return "Cloudflare (1.1.1.1)"
            case .quad9:
                return "Quad9 (9.9.9.9)"
            case .google:
                return "Google (8.8.8.8)"
            case .openDNS:
                return "OpenDNS (208.67.222.222)"
            case .custom:
                return "Custom"
            }
        }
    }
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        encryptedDNSEnabled = userDefaults.bool(forKey: "encryptedDNSEnabled")
        blockAdsEnabled = userDefaults.bool(forKey: "blockAdsEnabled")
        blockTrackersEnabled = userDefaults.bool(forKey: "blockTrackersEnabled")
        blockMalwareEnabled = userDefaults.bool(forKey: "blockMalwareEnabled")
        allowCustomDNS = userDefaults.bool(forKey: "allowCustomDNS")
        customDNSServers = userDefaults.array(forKey: "customDNSServers") as? [String] ?? []
        enableLogging = userDefaults.bool(forKey: "enableLogging")
        autoUpdateBlocklists = userDefaults.bool(forKey: "autoUpdateBlocklists")
        updateInterval = userDefaults.double(forKey: "updateInterval")
        
        if let providerRaw = userDefaults.string(forKey: "selectedDNSProvider"),
           let provider = DNSProvider(rawValue: providerRaw) {
            selectedDNSProvider = provider
        }
        
        // Set defaults if not previously set
        if !userDefaults.bool(forKey: "settingsInitialized") {
            setDefaults()
        }
    }
    
    private func setDefaults() {
        encryptedDNSEnabled = true
        blockAdsEnabled = true
        blockTrackersEnabled = true
        blockMalwareEnabled = true
        allowCustomDNS = false
        customDNSServers = []
        selectedDNSProvider = .cloudflare
        enableLogging = false
        autoUpdateBlocklists = true
        updateInterval = 24 * 60 * 60
        
        saveSettings()
        userDefaults.set(true, forKey: "settingsInitialized")
    }
    
    func saveSettings() {
        userDefaults.set(encryptedDNSEnabled, forKey: "encryptedDNSEnabled")
        userDefaults.set(blockAdsEnabled, forKey: "blockAdsEnabled")
        userDefaults.set(blockTrackersEnabled, forKey: "blockTrackersEnabled")
        userDefaults.set(blockMalwareEnabled, forKey: "blockMalwareEnabled")
        userDefaults.set(allowCustomDNS, forKey: "allowCustomDNS")
        userDefaults.set(customDNSServers, forKey: "customDNSServers")
        userDefaults.set(selectedDNSProvider.rawValue, forKey: "selectedDNSProvider")
        userDefaults.set(enableLogging, forKey: "enableLogging")
        userDefaults.set(autoUpdateBlocklists, forKey: "autoUpdateBlocklists")
        userDefaults.set(updateInterval, forKey: "updateInterval")
    }
    
    func resetToDefaults() {
        setDefaults()
    }
    
    func getCurrentDNSServers() -> [String] {
        switch selectedDNSProvider {
        case .cloudflare:
            return ["1.1.1.1", "1.0.0.1"]
        case .quad9:
            return ["9.9.9.9", "149.112.112.112"]
        case .google:
            return ["8.8.8.8", "8.8.4.4"]
        case .openDNS:
            return ["208.67.222.222", "208.67.220.220"]
        case .custom:
            return customDNSServers
        }
    }
}
