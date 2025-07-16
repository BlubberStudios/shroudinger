import Foundation
import SwiftUI

@MainActor
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
    
    // Service Management
    @Published var servicesRunning: Bool = false
    @Published var blockedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var lastStatsUpdate: Date = Date()
    
    // Testing and Development
    @Published var testingLogsEnabled: Bool = false
    @Published var testingLogsVisible: Bool = false
    
    // Service Status
    @Published var apiServiceStatus: ServiceStatus = .stopped
    @Published var dnsServiceStatus: ServiceStatus = .stopped
    @Published var middlewareServiceStatus: ServiceStatus = .stopped
    @Published var blocklistServiceStatus: ServiceStatus = .stopped
    
    private let userDefaults = UserDefaults.standard
    
    // Service Status
    enum ServiceStatus: Equatable {
        case stopped
        case starting
        case running
        case error(String)
        
        var displayName: String {
            switch self {
            case .stopped: return "Stopped"
            case .starting: return "Starting"
            case .running: return "Running"
            case .error(let message): return "Error: \(message)"
            }
        }
    }
    
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
        // Initialize all properties with safe defaults
        blockedCount = 0
        totalCount = 0
        lastStatsUpdate = Date()
        
        // Only load basic settings, skip service checks for now
        loadBasicSettings()
        
        // Defer service checks to avoid blocking initialization
        // checkInitialServiceStatus()
    }
    
    private func loadBasicSettings() {
        // Load only essential settings without complex operations
        if let providerRaw = userDefaults.string(forKey: "selectedDNSProvider"),
           let provider = DNSProvider(rawValue: providerRaw) {
            selectedDNSProvider = provider
        }
        
        if let protocolRaw = userDefaults.string(forKey: "selectedProtocol"),
           let dnsProtocol = DNSProtocol(rawValue: protocolRaw) {
            selectedProtocol = dnsProtocol
        }
        
        // Set safe defaults for booleans
        encryptedDNSEnabled = userDefaults.object(forKey: "encryptedDNSEnabled") as? Bool ?? true
        blockAdsEnabled = userDefaults.object(forKey: "blockAdsEnabled") as? Bool ?? true
        blockTrackersEnabled = userDefaults.object(forKey: "blockTrackersEnabled") as? Bool ?? true
        blockMalwareEnabled = userDefaults.object(forKey: "blockMalwareEnabled") as? Bool ?? true
        testingLogsEnabled = userDefaults.object(forKey: "testingLogsEnabled") as? Bool ?? false
        testingLogsVisible = userDefaults.object(forKey: "testingLogsVisible") as? Bool ?? false
    }
    
    // MARK: - Service Status Testing
    
    func checkBackendServicesStatus() async -> Bool {
        let services = [
            "http://localhost:8080/health",  // API Server
            "http://localhost:8082/health",  // DNS Service
            "http://localhost:8083/health",  // Middleware
            "http://localhost:8081/health"   // Blocklist Service
        ]
        
        var servicesRunning = 0
        
        for serviceURL in services {
            if await isServiceRunning(serviceURL) {
                servicesRunning += 1
            }
        }
        
        // Return true if at least half the services are running
        return servicesRunning >= 2
    }
    
    private func isServiceRunning(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 2.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Service not available
        }
        
        return false
    }
    
    private func checkInitialServiceStatus() {
        // Delay the service check to avoid blocking app startup
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            await checkServiceHealth()
            let allServicesRunning = apiServiceStatus == .running && 
                                    dnsServiceStatus == .running && 
                                    middlewareServiceStatus == .running && 
                                    blocklistServiceStatus == .running
            
            if allServicesRunning {
                servicesRunning = true
                startStatsMonitoring()
            }
        }
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
        testingLogsEnabled = userDefaults.bool(forKey: "testingLogsEnabled")
        testingLogsVisible = userDefaults.bool(forKey: "testingLogsVisible")
        
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
        userDefaults.set(testingLogsEnabled, forKey: "testingLogsEnabled")
        userDefaults.set(testingLogsVisible, forKey: "testingLogsVisible")
        
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
        isTestingConnection = true
        
        let config = getCurrentDNSConfig()
        let startTime = Date()
        
        // First, try to test the backend DNS service if available
        let backendTestResult = await testBackendDNSService(testDomain: testDomain)
        
        if let backendResult = backendTestResult {
            lastTestResult = backendResult
        } else {
            // Backend not available, try a simple connectivity test
            await performBasicConnectivityTest(config: config, startTime: startTime)
        }
        
        isTestingConnection = false
    }
    
    private func testBackendDNSService(testDomain: String) async -> DNSTestResult? {
        guard let url = URL(string: "http://localhost:8082/api/v1/dns/test") else {
            return nil
        }
        
        let config = getCurrentDNSConfig()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        let testRequest = [
            "protocol": selectedProtocol.rawValue,
            "host": config.host,
            "port": config.port,
            "url": config.url,
            "testDomain": testDomain
        ] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testRequest)
            
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let success = jsonResponse["success"] as? Bool ?? false
                    let error = jsonResponse["error"] as? String
                    
                    return DNSTestResult(
                        success: success,
                        responseTime: responseTime,
                        error: error,
                        dnsProtocol: selectedProtocol,
                        server: config.host.isEmpty ? "Backend DNS Service" : config.host
                    )
                }
            }
            
            return DNSTestResult(
                success: false,
                responseTime: responseTime,
                error: "Backend service responded with error",
                dnsProtocol: selectedProtocol,
                server: "Backend DNS Service"
            )
            
        } catch {
            // Backend service not available
            return nil
        }
    }
    
    private func performBasicConnectivityTest(config: DNSServerConfig, startTime: Date) async {
        // Test multiple endpoints to avoid DNS blocking issues
        let testEndpoints = [
            "http://www.google.com",
            "http://www.apple.com",
            "http://httpbin.org/status/200"
        ]
        
        var lastError: String = "All connectivity tests failed"
        
        for endpoint in testEndpoints {
            do {
                guard let testURL = URL(string: endpoint) else { continue }
                
                var request = URLRequest(url: testURL)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 3.0
                
                let (_, response) = try await URLSession.shared.data(for: request)
                let responseTime = Date().timeIntervalSince(startTime)
                
                if let httpResponse = response as? HTTPURLResponse, 
                   httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    
                    lastTestResult = DNSTestResult(
                        success: true,
                        responseTime: responseTime,
                        error: nil,
                        dnsProtocol: selectedProtocol,
                        server: config.host.isEmpty ? "System DNS" : config.host
                    )
                    return
                }
                
            } catch {
                lastError = "Network connectivity test failed: \(error.localizedDescription)"
                continue
            }
        }
        
        // All tests failed
        let responseTime = Date().timeIntervalSince(startTime)
        lastTestResult = DNSTestResult(
            success: false,
            responseTime: responseTime,
            error: lastError,
            dnsProtocol: selectedProtocol,
            server: config.host.isEmpty ? "System DNS" : config.host
        )
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
    
    // MARK: - Service Management
    
    func startServices() async {
        // First check if services are already running
        await checkServiceHealth()
        
        let allServicesRunning = apiServiceStatus == .running && 
                                dnsServiceStatus == .running && 
                                middlewareServiceStatus == .running && 
                                blocklistServiceStatus == .running
        
        if allServicesRunning {
            // Services are already running, just update state
            servicesRunning = true
            startStatsMonitoring()
            return
        }
        
        // Services not running, start them
        print("🚀 Starting services...")
        apiServiceStatus = .starting
        dnsServiceStatus = .starting
        middlewareServiceStatus = .starting
        blocklistServiceStatus = .starting
        
        // Start backend services using the dedicated script
        let projectRoot = getProjectRoot()
        let scriptPath = projectRoot + "/scripts/start-services.sh"
        let environment = getTestingEnvironment()
        
        print("🔍 Project root: \(projectRoot)")
        print("🔍 Script path: \(scriptPath)")
        print("🔍 Environment: \(environment)")
        
        let result = await executeCommand("bash", args: [scriptPath], workingDirectory: projectRoot, environment: environment)
        
        print("📋 Script result - success: \(result.success), error: \(result.error ?? "none")")
        
        if result.success {
            // Give services time to start
            print("⏳ Waiting for services to start...")
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Check service health
            await checkServiceHealth()
            
            // Verify services actually started
            let servicesStarted = apiServiceStatus == .running && 
                                 dnsServiceStatus == .running && 
                                 middlewareServiceStatus == .running && 
                                 blocklistServiceStatus == .running
            
            if servicesStarted {
                print("✅ All services started successfully")
                servicesRunning = true
                startStatsMonitoring()
            } else {
                print("❌ Some services failed to start")
                print("📊 Service statuses:")
                print("  - API: \(apiServiceStatus.displayName)")
                print("  - DNS: \(dnsServiceStatus.displayName)")
                print("  - Middleware: \(middlewareServiceStatus.displayName)")
                print("  - Blocklist: \(blocklistServiceStatus.displayName)")
                servicesRunning = false
            }
        } else {
            print("❌ Script execution failed: \(result.error ?? "Unknown error")")
            servicesRunning = false
            let errorMessage = result.error ?? "Script execution failed"
            apiServiceStatus = .error(errorMessage)
            dnsServiceStatus = .error(errorMessage)
            middlewareServiceStatus = .error(errorMessage)
            blocklistServiceStatus = .error(errorMessage)
        }
    }
    
    func stopServices() async {
        servicesRunning = false
        apiServiceStatus = .stopped
        dnsServiceStatus = .stopped
        middlewareServiceStatus = .stopped
        blocklistServiceStatus = .stopped
        
        // Stop backend services using the dedicated script
        let scriptPath = getProjectRoot() + "/scripts/stop-services.sh"
        let _ = await executeCommand("bash", args: [scriptPath], workingDirectory: getProjectRoot())
        
        // Stop stats monitoring
        stopStatsMonitoring()
    }
    
    private func checkServiceHealth() async {
        // Check each service health endpoint
        let services = [
            ("API", "http://localhost:8080/health", \SettingsManager.apiServiceStatus),
            ("DNS", "http://localhost:8082/health", \SettingsManager.dnsServiceStatus),
            ("Middleware", "http://localhost:8083/health", \SettingsManager.middlewareServiceStatus),
            ("Blocklist", "http://localhost:8081/health", \SettingsManager.blocklistServiceStatus)
        ]
        
        for (_, urlString, statusKeyPath) in services {
            guard let url = URL(string: urlString) else {
                self[keyPath: statusKeyPath] = .error("Invalid URL")
                continue
            }
            
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 2.0 // 2 second timeout
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self[keyPath: statusKeyPath] = .running
                    } else {
                        self[keyPath: statusKeyPath] = .error("HTTP \(httpResponse.statusCode)")
                    }
                }
            } catch {
                self[keyPath: statusKeyPath] = .error(error.localizedDescription)
            }
        }
    }
    
    private func executeCommand(_ command: String, args: [String], workingDirectory: String? = nil, environment: [String: String]? = nil) async -> (success: Bool, error: String?) {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + args
            
            // Set working directory if provided
            if let workingDir = workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            }
            
            // Set environment variables
            var processEnvironment = ProcessInfo.processInfo.environment
            if let env = environment {
                for (key, value) in env {
                    processEnvironment[key] = value
                }
            }
            process.environment = processEnvironment
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: (true, nil))
                } else {
                    continuation.resume(returning: (false, output))
                }
            } catch {
                continuation.resume(returning: (false, error.localizedDescription))
            }
        }
    }
    
    private func getProjectRoot() -> String {
        // For sandboxed apps, we need to use a location the app can access
        // We'll use the Application Support directory where we've copied the scripts
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportPath = supportDir.appendingPathComponent("Shroudinger").path
        
        // Check if our scripts are available in the app support directory
        let scriptPath = appSupportPath + "/scripts/start-services.sh"
        if FileManager.default.fileExists(atPath: scriptPath) {
            print("✅ Found scripts at: \(appSupportPath)")
            return appSupportPath
        }
        
        // If not found, try to copy them from the project directory
        let projectPath = "/Users/rexliu/shroudinger"
        let makefilePath = projectPath + "/Makefile"
        
        if FileManager.default.fileExists(atPath: makefilePath) {
            print("✅ Found project at: \(projectPath)")
            
            // Try to copy scripts to app support if they don't exist
            do {
                try FileManager.default.createDirectory(at: supportDir.appendingPathComponent("Shroudinger"), withIntermediateDirectories: true)
                let sourceScriptsPath = projectPath + "/scripts"
                let destScriptsPath = appSupportPath + "/scripts"
                
                if FileManager.default.fileExists(atPath: sourceScriptsPath) {
                    try FileManager.default.copyItem(atPath: sourceScriptsPath, toPath: destScriptsPath)
                    print("✅ Copied scripts to app support directory")
                    return appSupportPath
                }
            } catch {
                print("⚠️  Could not copy scripts to app support: \(error)")
            }
            
            return projectPath
        }
        
        // If not found, try to find it relative to the current directory
        let currentDir = FileManager.default.currentDirectoryPath
        var searchPath = currentDir
        
        print("🔍 Searching from current directory: \(currentDir)")
        
        // Look for Makefile in current directory or parent directories
        for _ in 0..<10 {
            let makefilePath = (searchPath as NSString).appendingPathComponent("Makefile")
            print("🔍 Checking: \(makefilePath)")
            if FileManager.default.fileExists(atPath: makefilePath) {
                print("✅ Found project at: \(searchPath)")
                return searchPath
            }
            
            let parentPath = (searchPath as NSString).deletingLastPathComponent
            if parentPath == searchPath {
                break // Reached root
            }
            searchPath = parentPath
        }
        
        // Final fallback - use the app support directory
        print("⚠️  Using app support directory: \(appSupportPath)")
        return appSupportPath
    }
    
    private func getTestingEnvironment() -> [String: String] {
        var env: [String: String] = [:]
        
        if testingLogsEnabled {
            env["SHROUDINGER_TESTING"] = "true"
        }
        
        return env
    }
    
    // MARK: - Statistics Monitoring
    
    private var statsTimer: Timer?
    
    private func startStatsMonitoring() {
        statsTimer?.invalidate()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await self.updateConnectionStats()
            }
        }
    }
    
    private func stopStatsMonitoring() {
        statsTimer?.invalidate()
        statsTimer = nil
    }
    
    private func updateConnectionStats() async {
        // Get stats from blocklist service
        guard let url = URL(string: "http://localhost:8081/api/v1/stats") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let blocked = jsonResponse["blocked_queries"] as? Int ?? 0
                let total = jsonResponse["total_queries"] as? Int ?? 0
                
                // Update properties - already on main thread due to @MainActor
                self.blockedCount = blocked
                self.totalCount = total
                self.lastStatsUpdate = Date()
            }
        } catch {
            // Stats update failed, but don't show error to user
            print("Failed to update stats: \(error)")
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