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
    
    // DNS Protocol Configuration
    @Published var selectedProtocol: DNSProtocol = .doH
    @Published var customDNSConfig: CustomDNSConfig = CustomDNSConfig()
    @Published var isTestingConnection: Bool = false
    @Published var lastTestResult: DNSTestResult? = nil
    @Published var dnsExceptions: [DNSException] = []
    
    private let userDefaults = UserDefaults.standard
    
    // DNS Exception struct
    struct DNSException: Codable, Identifiable {
        let id: UUID
        let domain: String
        let dnsServer: String
        let dateAdded: Date
        
        init(domain: String, dnsServer: String = "") {
            self.id = UUID()
            self.domain = domain
            self.dnsServer = dnsServer
            self.dateAdded = Date()
        }
    }
    
    // DNS Provider enum
    enum DNSProvider: String, CaseIterable, Identifiable {
        case cloudflare = "cloudflare"
        case quad9 = "quad9"
        case google = "google"
        case dns0 = "dns0"
        case custom = "custom"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .cloudflare:
                return "Cloudflare"
            case .quad9:
                return "Quad9"
            case .google:
                return "Google"
            case .dns0:
                return "dns0.eu"
            case .custom:
                return "Custom"
            }
        }
        
        var description: String {
            switch self {
            case .cloudflare:
                return "Fast, privacy-focused DNS by Cloudflare"
            case .quad9:
                return "Security-focused DNS with malware blocking"
            case .google:
                return "Google's public DNS service"
            case .dns0:
                return "Privacy-focused DNS with zero-log policy"
            case .custom:
                return "Configure your own DNS server"
            }
        }
        
        var defaultConfigs: [DNSProtocol: DNSServerConfig] {
            switch self {
            case .cloudflare:
                return [
                    .doH: DNSServerConfig(host: "cloudflare-dns.com", port: 443, url: "https://cloudflare-dns.com/dns-query"),
                    .doT: DNSServerConfig(host: "1.1.1.1", port: 853, url: ""),
                    .doQ: DNSServerConfig(host: "1.1.1.1", port: 853, url: "")
                ]
            case .quad9:
                return [
                    .doH: DNSServerConfig(host: "dns.quad9.net", port: 443, url: "https://dns.quad9.net/dns-query"),
                    .doT: DNSServerConfig(host: "9.9.9.9", port: 853, url: ""),
                    .doQ: DNSServerConfig(host: "9.9.9.9", port: 853, url: "")
                ]
            case .google:
                return [
                    .doH: DNSServerConfig(host: "dns.google", port: 443, url: "https://dns.google/dns-query"),
                    .doT: DNSServerConfig(host: "8.8.8.8", port: 853, url: ""),
                    .doQ: DNSServerConfig(host: "8.8.8.8", port: 853, url: "")
                ]
            case .dns0:
                return [
                    .doH: DNSServerConfig(host: "dns0.eu", port: 443, url: "https://dns0.eu/dns-query"),
                    .doT: DNSServerConfig(host: "193.110.81.0", port: 853, url: ""),
                    .doQ: DNSServerConfig(host: "193.110.81.0", port: 853, url: "")
                ]
            case .custom:
                return [
                    .doH: DNSServerConfig(host: "", port: 443, url: ""),
                    .doT: DNSServerConfig(host: "", port: 853, url: ""),
                    .doQ: DNSServerConfig(host: "", port: 853, url: "")
                ]
            }
        }
    }
    
    // DNS Protocol enum
    enum DNSProtocol: String, CaseIterable, Identifiable {
        case doH = "DoH"
        case doT = "DoT"
        case doQ = "DoQ"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .doH:
                return "DNS over HTTPS (DoH)"
            case .doT:
                return "DNS over TLS (DoT)"
            case .doQ:
                return "DNS over QUIC (DoQ)"
            }
        }
        
        var description: String {
            switch self {
            case .doH:
                return "Encrypts DNS queries using HTTPS (Port 443)"
            case .doT:
                return "Encrypts DNS queries using TLS (Port 853)"
            case .doQ:
                return "Encrypts DNS queries using QUIC (Port 853)"
            }
        }
    }
    
    // DNS Server Configuration
    struct DNSServerConfig: Codable {
        var host: String
        var port: Int
        var url: String // Used for DoH
        
        init(host: String = "", port: Int = 853, url: String = "") {
            self.host = host
            self.port = port
            self.url = url
        }
    }
    
    // Custom DNS Configuration
    struct CustomDNSConfig: Codable {
        var doHConfig: DNSServerConfig = DNSServerConfig()
        var doTConfig: DNSServerConfig = DNSServerConfig()
        var doQConfig: DNSServerConfig = DNSServerConfig()
        
        mutating func updateConfig(for dnsProtocol: DNSProtocol, config: DNSServerConfig) {
            switch dnsProtocol {
            case .doH:
                doHConfig = config
            case .doT:
                doTConfig = config
            case .doQ:
                doQConfig = config
            }
        }
        
        func getConfig(for dnsProtocol: DNSProtocol) -> DNSServerConfig {
            switch dnsProtocol {
            case .doH:
                return doHConfig
            case .doT:
                return doTConfig
            case .doQ:
                return doQConfig
            }
        }
    }
    
    // DNS Test Result
    struct DNSTestResult {
        let success: Bool
        let responseTime: TimeInterval
        let error: String?
        let timestamp: Date
        let dnsProtocol: DNSProtocol
        let server: String
        
        init(success: Bool, responseTime: TimeInterval = 0, error: String? = nil, dnsProtocol: DNSProtocol, server: String) {
            self.success = success
            self.responseTime = responseTime
            self.error = error
            self.timestamp = Date()
            self.dnsProtocol = dnsProtocol
            self.server = server
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
        
        if let protocolRaw = userDefaults.string(forKey: "selectedProtocol"),
           let dnsProtocol = DNSProtocol(rawValue: protocolRaw) {
            selectedProtocol = dnsProtocol
        }
        
        loadCustomDNSConfig()
        loadDNSExceptions()
        
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
        selectedProtocol = .doH
        enableLogging = false
        autoUpdateBlocklists = true
        updateInterval = 24 * 60 * 60
        customDNSConfig = CustomDNSConfig()
        
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
        userDefaults.set(selectedProtocol.rawValue, forKey: "selectedProtocol")
        userDefaults.set(enableLogging, forKey: "enableLogging")
        userDefaults.set(autoUpdateBlocklists, forKey: "autoUpdateBlocklists")
        userDefaults.set(updateInterval, forKey: "updateInterval")
        
        saveCustomDNSConfig()
    }
    
    func resetToDefaults() {
        setDefaults()
    }
    
    func getCurrentDNSConfig() -> DNSServerConfig {
        if selectedDNSProvider == .custom {
            return customDNSConfig.getConfig(for: selectedProtocol)
        } else {
            return selectedDNSProvider.defaultConfigs[selectedProtocol] ?? DNSServerConfig()
        }
    }
    
    func updateCustomDNSConfig(for dnsProtocol: DNSProtocol, config: DNSServerConfig) {
        customDNSConfig.updateConfig(for: dnsProtocol, config: config)
        saveSettings()
    }
    
    private func saveCustomDNSConfig() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(customDNSConfig) {
            userDefaults.set(data, forKey: "customDNSConfig")
        }
    }
    
    private func loadCustomDNSConfig() {
        if let data = userDefaults.data(forKey: "customDNSConfig") {
            let decoder = JSONDecoder()
            if let config = try? decoder.decode(CustomDNSConfig.self, from: data) {
                customDNSConfig = config
            }
        }
    }
    
    // MARK: - Backend Communication
    
    func testDNSConnection(testDomain: String = "google.com") async {
        await MainActor.run {
            isTestingConnection = true
        }
        
        let config = getCurrentDNSConfig()
        
        // BACKEND CALL: Test DNS server connectivity
        // POST http://localhost:8082/api/v1/dns/test
        guard let url = URL(string: "http://localhost:8082/api/v1/dns/test") else {
            await MainActor.run {
                lastTestResult = DNSTestResult(
                    success: false,
                    error: "Invalid backend URL",
                    dnsProtocol: selectedProtocol,
                    server: config.host
                )
                isTestingConnection = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let testRequest = [
            "protocol": selectedProtocol.rawValue,
            "host": config.host,
            "port": config.port,
            "url": config.url,
            "testDomain": testDomain
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testRequest)
            
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let testCompleted = jsonResponse["status"] as? String == "test_complete"
                    let testSuccess = jsonResponse["success"] as? Bool ?? false
                    let encryption = jsonResponse["encryption"] as? String == "verified"
                    let errorMessage = jsonResponse["error"] as? String
                    
                    // Extract performance data
                    let actualResponseTime: TimeInterval = {
                        if let performance = jsonResponse["performance"] as? [String: Any],
                           let dnsTimeString = performance["dns_resolution_time"] as? String,
                           let parsed = parseDurationString(dnsTimeString) {
                            return parsed
                        }
                        return responseTime
                    }()
                    
                    await MainActor.run {
                        lastTestResult = DNSTestResult(
                            success: testCompleted && testSuccess && encryption,
                            responseTime: actualResponseTime,
                            error: testSuccess && encryption ? nil : (errorMessage ?? "Test failed"),
                            dnsProtocol: selectedProtocol,
                            server: config.host
                        )
                        isTestingConnection = false
                    }
                }
            } else {
                await MainActor.run {
                    lastTestResult = DNSTestResult(
                        success: false,
                        error: "Server returned error",
                        dnsProtocol: selectedProtocol,
                        server: config.host
                    )
                    isTestingConnection = false
                }
            }
        } catch {
            await MainActor.run {
                lastTestResult = DNSTestResult(
                    success: false,
                    error: error.localizedDescription,
                    dnsProtocol: selectedProtocol,
                    server: config.host
                )
                isTestingConnection = false
            }
        }
    }
    
    func updateDNSConfiguration() async {
        let config = getCurrentDNSConfig()
        
        // BACKEND CALL: Update DNS server configuration
        // POST http://localhost:8082/api/v1/dns/configure
        guard let url = URL(string: "http://localhost:8082/api/v1/dns/configure") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let configRequest = [
            "provider": selectedDNSProvider.rawValue,
            "protocol": selectedProtocol.rawValue,
            "host": config.host,
            "port": config.port,
            "url": config.url,
            "enabled": encryptedDNSEnabled
        ] as [String : Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: configRequest)
            let (_, _) = try await URLSession.shared.data(for: request)
            // Configuration updated successfully
        } catch {
            print("Failed to update DNS configuration: \(error)")
        }
    }
    
    // MARK: - Exception Management
    
    func addDNSException(domain: String, dnsServer: String = "") {
        let exception = DNSException(domain: domain, dnsServer: dnsServer)
        dnsExceptions.append(exception)
        saveDNSExceptions()
    }
    
    func removeDNSException(withId id: UUID) {
        dnsExceptions.removeAll { $0.id == id }
        saveDNSExceptions()
    }
    
    func removeDNSException(forDomain domain: String) {
        dnsExceptions.removeAll { $0.domain == domain }
        saveDNSExceptions()
    }
    
    private func saveDNSExceptions() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(dnsExceptions) {
            userDefaults.set(data, forKey: "dnsExceptions")
        }
    }
    
    private func loadDNSExceptions() {
        if let data = userDefaults.data(forKey: "dnsExceptions") {
            let decoder = JSONDecoder()
            if let exceptions = try? decoder.decode([DNSException].self, from: data) {
                dnsExceptions = exceptions
            }
        }
    }
    
    // Helper function to parse duration strings from backend
    private func parseDurationString(_ durationString: String) -> TimeInterval? {
        let cleanString = durationString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanString.hasSuffix("ms") {
            if let value = Double(String(cleanString.dropLast(2))) {
                return value / 1000.0 // Convert milliseconds to seconds
            }
        } else if cleanString.hasSuffix("s") {
            if let value = Double(String(cleanString.dropLast(1))) {
                return value
            }
        } else if cleanString.hasSuffix("µs") {
            if let value = Double(String(cleanString.dropLast(2))) {
                return value / 1_000_000.0 // Convert microseconds to seconds
            }
        }
        
        return nil
    }
}