import SwiftUI

struct DNSEncryptionView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var showingCustomConfiguration = false
    @State private var showingExceptionDialog = false
    @State private var newExceptionDomain = ""
    @State private var newExceptionDNSServer = ""
    @State private var testResult: TestResult?
    @State private var isTestingConnection = false
    @State private var selectedTestDomain = "Random Domain"
    @State private var activeSheet: ActiveSheet? = nil
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    enum ActiveSheet: Identifiable {
        case customConfiguration
        case exception
        
        var id: Int {
            switch self {
            case .customConfiguration: return 1
            case .exception: return 2
            }
        }
    }
    
    // Predefined test domains
    private let testDomains = [
        "Random Domain",
        "Google.com",
        "Facebook.com", 
        "GitHub.com",
        "Apple.com",
        "Microsoft.com",
        "Amazon.com",
        "Netflix.com"
    ]
    
    var body: some View {
        ZStack {
            // Main background
            DesignSystem.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // DNS Encryption Toggle Section
                dnsEncryptionToggleSection
                
                // DNS Provider Selection
                dnsProviderSection
                
                // Test Connection Section
                testConnectionSection
                
                // Add Exception Section
                addExceptionSection
                
                // Current Exceptions Section
                if !settingsManager.dnsExceptions.isEmpty {
                    currentExceptionsSection
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.sectionMargin)
            .padding(.vertical, DesignSystem.Spacing.layoutPadding)
        }
        .sheet(isPresented: Binding(
            get: { activeSheet == .customConfiguration },
            set: { isPresented in
                if !isPresented {
                    activeSheet = nil
                }
            }
        )) {
            CustomDNSConfigurationView(
                settingsManager: settingsManager,
                isPresented: Binding(
                    get: { activeSheet == .customConfiguration },
                    set: { _ in activeSheet = nil }
                )
            )
            .onAppear {
                print("🔧 CustomDNSConfigurationView appeared")
            }
        }
        .sheet(isPresented: Binding(
            get: { activeSheet == .exception },
            set: { isPresented in
                if !isPresented {
                    activeSheet = nil
                }
            }
        )) {
            AddExceptionView(
                domain: $newExceptionDomain,
                dnsServer: $newExceptionDNSServer,
                isPresented: Binding(
                    get: { activeSheet == .exception },
                    set: { _ in activeSheet = nil }
                ),
                settingsManager: settingsManager
            )
        }
    }
    
    // MARK: - DNS Encryption Toggle Section
    private var dnsEncryptionToggleSection: some View {
        ModernToggle(
            "DNS Encryption",
            description: "DNS lookups are performed in encrypted form.",
            isOn: $settingsManager.encryptedDNSEnabled,
            onChange: {
                Task {
                    await settingsManager.updateDNSConfiguration()
                }
            }
        )
    }
    
    // MARK: - DNS Provider Section
    private var dnsProviderSection: some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                SectionHeader("DNS Provider", subtitle: "Select your preferred DNS service")
                
                // DNS Provider Dropdown
                Menu {
                    ForEach(SettingsManager.DNSProvider.allCases.filter { $0 != .custom }) { provider in
                        Button(action: {
                            settingsManager.selectedDNSProvider = provider
                            Task {
                                await settingsManager.updateDNSConfiguration()
                            }
                        }) {
                            HStack {
                                Text(provider.displayName)
                                if settingsManager.selectedDNSProvider == provider {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        settingsManager.selectedDNSProvider = .custom
                        showingCustomConfiguration = true
                    }) {
                        HStack {
                            Text("Custom")
                            if settingsManager.selectedDNSProvider == .custom {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(settingsManager.selectedDNSProvider.displayName)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .font(DesignSystem.Typography.bodyMedium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Protocol Selection (when not custom)
                if settingsManager.selectedDNSProvider != .custom {
                    Menu {
                        ForEach(SettingsManager.DNSProtocol.allCases) { dnsProtocol in
                            Button(action: {
                                settingsManager.selectedProtocol = dnsProtocol
                                Task {
                                    await settingsManager.updateDNSConfiguration()
                                }
                            }) {
                                HStack {
                                    Text(dnsProtocol.rawValue)
                                    if settingsManager.selectedProtocol == dnsProtocol {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(settingsManager.selectedProtocol.rawValue)
                                .foregroundColor(.primary)
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Edit button for custom configuration
                if settingsManager.selectedDNSProvider == .custom {
                    Button("Edit") {
                        print("🔧 Edit button clicked - opening custom configuration")
                        activeSheet = .customConfiguration
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // DNS Configuration Description
            let currentConfig = settingsManager.getCurrentDNSConfig()
            if settingsManager.selectedDNSProvider == .custom {
                // Show custom configuration status
                let isConfigured = (settingsManager.selectedProtocol == .doH && !currentConfig.url.isEmpty) || 
                                  (settingsManager.selectedProtocol != .doH && !currentConfig.host.isEmpty)
                
                HStack {
                    if isConfigured {
                        Text("DNS requests are sent to ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        + Text(getDisplayURL(config: currentConfig))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        + Text(" using ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        + Text(settingsManager.selectedProtocol.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        + Text(".")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Custom DNS configuration is incomplete. Click 'Edit' to configure your \(settingsManager.selectedProtocol.rawValue) server.")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            } else if !currentConfig.host.isEmpty {
                HStack {
                    Text("DNS requests are sent to ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(getDisplayURL(config: currentConfig))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(" using ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(settingsManager.selectedProtocol.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(".")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Test Connection Section
    private var testConnectionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    testConnection()
                }) {
                    HStack(spacing: 8) {
                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        
                        Text("Test")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .disabled(isTestingConnection)
                .buttonStyle(PlainButtonStyle())
                
                // Random Domain selector (for testing)
                Menu {
                    ForEach(testDomains, id: \.self) { domain in
                        Button(domain) {
                            selectedTestDomain = domain
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTestDomain)
                            .font(.system(size: 14, weight: .medium))
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            // Test result display
            if let testResult = testResult {
                HStack {
                    switch testResult {
                    case .success:
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("✅ Encrypted DNS is working correctly")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                                Text("DNS queries are being resolved using \(settingsManager.selectedProtocol.rawValue) encryption")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .failure(let error):
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("❌ DNS encryption test failed")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                Text(getDetailedErrorMessage(error))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Description text
            Text("Performs two test DNS queries. One using the system DNS resolver and another by sending a DNS query packet directly to the system DNS server.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Add Exception Section
    private var addExceptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Add Exception...") {
                    activeSheet = .exception
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Current Exceptions Section
    private var currentExceptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Exceptions")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(settingsManager.dnsExceptions) { exception in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exception.domain)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            if !exception.dnsServer.isEmpty {
                                Text("DNS: \(exception.dnsServer)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            settingsManager.removeDNSException(withId: exception.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getDisplayURL(config: SettingsManager.DNSServerConfig) -> String {
        switch settingsManager.selectedProtocol {
        case .doH:
            return config.url.isEmpty ? config.host : config.url
        case .doT, .doQ:
            return "\(config.host):\(config.port)"
        }
    }
    
    private func getTestDomain() -> String {
        let availableDomains = ["google.com", "facebook.com", "github.com", "apple.com", "microsoft.com", "amazon.com", "netflix.com"]
        
        if selectedTestDomain == "Random Domain" {
            return availableDomains.randomElement() ?? "google.com"
        } else {
            return selectedTestDomain.lowercased()
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        // Check if custom DNS configuration is complete
        if settingsManager.selectedDNSProvider == .custom {
            let config = settingsManager.getCurrentDNSConfig()
            
            // Validate based on protocol
            var configurationValid = false
            var errorMessage = ""
            
            switch settingsManager.selectedProtocol {
            case .doH:
                if !config.url.isEmpty {
                    configurationValid = true
                } else {
                    errorMessage = "Custom DoH configuration requires a valid HTTPS URL. Please edit the configuration."
                }
            case .doT, .doQ:
                if !config.host.isEmpty {
                    configurationValid = true
                } else {
                    errorMessage = "Custom \(settingsManager.selectedProtocol.rawValue) configuration requires a valid host. Please edit the configuration."
                }
            }
            
            if !configurationValid {
                isTestingConnection = false
                testResult = .failure(errorMessage)
                return
            }
        }
        
        Task {
            await settingsManager.testDNSConnection(testDomain: getTestDomain())
            
            await MainActor.run {
                isTestingConnection = false
                
                if let result = settingsManager.lastTestResult {
                    if result.success {
                        testResult = .success
                    } else {
                        testResult = .failure(result.error ?? "Unknown error")
                    }
                }
            }
        }
    }
    
    private func getDetailedErrorMessage(_ error: String) -> String {
        if error.contains("Invalid backend URL") {
            return "Backend service is not running. Please start the DNS service first."
        } else if error.contains("configuration is incomplete") || error.contains("configuration requires") {
            return "Click 'Edit' to configure your custom DNS server settings."
        } else if error.contains("Server returned error") {
            if settingsManager.selectedDNSProvider == .custom {
                return "Custom DNS server configuration is incomplete or invalid. Please check your settings."
            } else {
                return "DNS server returned an error. Please try a different DNS provider."
            }
        } else if error.contains("connection failed") {
            return "Unable to connect to the DNS server. Please check your network connection and server settings."
        } else if error.contains("Invalid JSON") {
            return "Communication error with backend service. Please restart the application."
        } else if error.contains("DoH request failed") {
            return "DNS over HTTPS request failed. Please check your DoH server URL and try again."
        } else if error.contains("DoT connection failed") {
            return "DNS over TLS connection failed. Please check your DoT server host and port."
        } else if error.contains("DoQ connection failed") {
            return "DNS over QUIC connection failed. Please check your DoQ server host and port."
        } else {
            return error
        }
    }
}

// MARK: - Custom Toggle Style
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button(action: {
                configuration.isOn.toggle()
            }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color.blue : Color(.controlBackgroundColor))
                    .frame(width: 44, height: 26)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: configuration.isOn ? 9 : -9)
                            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                    )
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(configuration.isOn ? "On" : "Off")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(configuration.isOn ? .blue : .secondary)
        }
    }
}

// MARK: - Custom DNS Configuration View
struct CustomDNSConfigurationView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isPresented: Bool
    @State private var selectedProtocol: SettingsManager.DNSProtocol = .doH
    @State private var serverURL = ""
    @State private var serverHost = ""
    @State private var serverPort = "853"
    @State private var username = ""
    @State private var password = ""
    @State private var serverSPKI = ""
    @State private var validationErrors: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DNS Server Configuration")
                    .font(.title2)
                    .fontWeight(.medium)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.controlBackgroundColor))
            
            // Content
            VStack(spacing: 24) {
                // Protocol Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Protocol")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Menu {
                        ForEach(SettingsManager.DNSProtocol.allCases) { dnsProtocol in
                            Button(action: {
                                selectedProtocol = dnsProtocol
                                loadConfigForProtocol(dnsProtocol)
                            }) {
                                HStack {
                                    Text(dnsProtocol.displayName)
                                    if selectedProtocol == dnsProtocol {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedProtocol.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(.separatorColor), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Configuration Fields
                configurationFields
                
                // Validation Errors
                if !validationErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(validationErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        // Reset values to original state
                        loadConfigForProtocol(settingsManager.selectedProtocol)
                        validationErrors = []
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Save") {
                        if validateAndSaveConfiguration() {
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .frame(width: 500, height: 500)
        .onAppear {
            loadConfigForProtocol(settingsManager.selectedProtocol)
            selectedProtocol = settingsManager.selectedProtocol
        }
    }
    
    @ViewBuilder
    private var configurationFields: some View {
        switch selectedProtocol {
        case .doH:
            VStack(spacing: 16) {
                // Server URL
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server URL")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    TextField("https://dns.example.com/dns-query", text: $serverURL)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Username (Optional)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Optional", text: $username)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Password (Optional)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    SecureField("Optional", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Server SPKI (Optional)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server SPKI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Optional", text: $serverSPKI)
                        .textFieldStyle(CustomTextFieldStyle())
                }
            }
            
        case .doT, .doQ:
            VStack(spacing: 16) {
                // Server Host
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server Host")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    TextField("dns.example.com", text: $serverHost)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Server Port
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server Port")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    TextField("853", text: $serverPort)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Server SPKI (Optional)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server SPKI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Optional", text: $serverSPKI)
                        .textFieldStyle(CustomTextFieldStyle())
                }
            }
        }
    }
    
    private func loadConfigForProtocol(_ dnsProtocol: SettingsManager.DNSProtocol) {
        let config = settingsManager.customDNSConfig.getConfig(for: dnsProtocol)
        
        switch dnsProtocol {
        case .doH:
            serverURL = config.url
            serverHost = config.host
        case .doT, .doQ:
            serverHost = config.host
            serverPort = String(config.port)
        }
    }
    
    private func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        switch selectedProtocol {
        case .doH:
            if serverURL.isEmpty {
                errors.append("Server URL is required for DoH")
            } else if !serverURL.hasPrefix("https://") {
                errors.append("Server URL must start with https://")
            }
        case .doT, .doQ:
            if serverHost.isEmpty {
                errors.append("Server Host is required")
            }
            if let port = Int(serverPort) {
                if port < 1 || port > 65535 {
                    errors.append("Port must be between 1 and 65535")
                }
            } else {
                errors.append("Port must be a valid number")
            }
        }
        
        return errors
    }
    
    private func validateAndSaveConfiguration() -> Bool {
        validationErrors = validateConfiguration()
        
        if !validationErrors.isEmpty {
            return false
        }
        
        var config = SettingsManager.DNSServerConfig()
        
        switch selectedProtocol {
        case .doH:
            config.url = serverURL
            config.host = serverHost
            config.port = 443
        case .doT, .doQ:
            config.host = serverHost
            config.port = Int(serverPort) ?? 853
        }
        
        settingsManager.updateCustomDNSConfig(for: selectedProtocol, config: config)
        settingsManager.selectedProtocol = selectedProtocol
        
        Task {
            await settingsManager.updateDNSConfiguration()
        }
        
        return true
    }
}

// MARK: - Add Exception View
struct AddExceptionView: View {
    @Binding var domain: String
    @Binding var dnsServer: String
    @Binding var isPresented: Bool
    @ObservedObject var settingsManager: SettingsManager
    @State private var validationError: String?
    
    var body: some View {
        ZStack {
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("Add Exception")
                    .font(.title2)
                    .fontWeight(.medium)
                
                // Domain field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Domain:")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    TextField("example.com", text: $domain)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // DNS Server field
                VStack(alignment: .leading, spacing: 8) {
                    Text("DNS Server:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Optional", text: $dnsServer)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Validation Error
                if let error = validationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Add Exception") {
                        if validateDomain() {
                            settingsManager.addDNSException(domain: domain, dnsServer: dnsServer)
                            domain = ""
                            dnsServer = ""
                            validationError = nil
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(domain.isEmpty)
                }
            }
            .padding(24)
        }
        .frame(width: 400, height: 250)
    }
    
    private func validateDomain() -> Bool {
        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedDomain.isEmpty {
            validationError = "Domain is required"
            return false
        }
        
        // Basic domain validation
        let domainRegex = "^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\\.[a-zA-Z]{2,}$"
        let domainPredicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        
        if !domainPredicate.evaluate(with: trimmedDomain) {
            validationError = "Please enter a valid domain name"
            return false
        }
        
        // Check if domain already exists
        if settingsManager.dnsExceptions.contains(where: { $0.domain == trimmedDomain }) {
            validationError = "This domain already has an exception"
            return false
        }
        
        validationError = nil
        return true
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
    }
}

struct DNSEncryptionView_Previews: PreviewProvider {
    static var previews: some View {
        DNSEncryptionView()
            .preferredColorScheme(.dark)
            .frame(width: 600, height: 500)
    }
}

struct AddExceptionView_Previews: PreviewProvider {
    static var previews: some View {
        AddExceptionView(
            domain: .constant(""),
            dnsServer: .constant(""),
            isPresented: .constant(true),
            settingsManager: SettingsManager()
        )
        .preferredColorScheme(.dark)
        .frame(width: 400, height: 250)
    }
}