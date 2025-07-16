import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var showAdvancedSettings = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Main Controls
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header with compact status
                ModernCard {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(settingsManager.servicesRunning ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            Text("Shroudinger")
                                .font(DesignSystem.Typography.title)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            StatusIndicator(status: settingsManager.servicesRunning ? .connected : .disconnected)
                        }
                        
                        Spacer()
                        
                        // Main toggle prominently placed
                        Toggle("DNS Protection", isOn: $settingsManager.servicesRunning)
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .onChange(of: settingsManager.servicesRunning) { newValue in
                                Task {
                                    if newValue {
                                        await settingsManager.startServices()
                                    } else {
                                        await settingsManager.stopServices()
                                    }
                                }
                            }
                    }
                }
                
                // Statistics - Horizontal Layout
                HStack(spacing: DesignSystem.Spacing.sm) {
                    StatCardView(title: "Blocked", value: blockedValue, color: DesignSystem.Colors.error)
                    StatCardView(title: "Total", value: totalValue, color: DesignSystem.Colors.info)
                    StatCardView(title: "Rate", value: rateValue, color: DesignSystem.Colors.warning)
                }
                
                // Privacy Settings - Placeholder
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Label("Privacy Settings", systemImage: "gear")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        // Empty space where toggles were
                        Spacer()
                            .frame(height: 80)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Button(showAdvancedSettings ? "Hide Advanced Settings" : "Advanced Settings") {
                        withAnimation(DesignSystem.Animation.smooth) {
                            showAdvancedSettings.toggle()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Activity Logs") {
                        // Show logs
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .frame(width: 280)
            .padding(DesignSystem.Spacing.md)
            
            if showAdvancedSettings {
                Divider()
                
                // Right Panel - DNS Configuration
                VStack(spacing: 0) {
                    // DNS Configuration Header
                    ModernCard(cornerRadius: 0) {
                        HStack {
                            Label("DNS Configuration", systemImage: "network")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    ScrollView {
                        DNSEncryptionView()
                            .padding(DesignSystem.Spacing.md)
                    }
                }
                .frame(minWidth: 350)
                .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: showAdvancedSettings ? 680 : 300, maxWidth: showAdvancedSettings ? 1200 : 320, minHeight: 480, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
    
    private func calculateBlockRate() -> Int {
        guard settingsManager.totalCount > 0 else { return 0 }
        return Int((Double(settingsManager.blockedCount) / Double(settingsManager.totalCount)) * 100)
    }
    
    // Safe computed properties for view display
    private var blockedValue: String {
        return "\(settingsManager.blockedCount)"
    }
    
    private var totalValue: String {
        return "\(settingsManager.totalCount)"
    }
    
    private var rateValue: String {
        return "\(calculateBlockRate())%"
    }
}

// MARK: - Helper Components

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        ModernCard(shadow: DesignSystem.Shadows.subtle) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Text(safeValue)
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(color)
                Text(safeTitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var safeValue: String {
        return value.isEmpty ? "0" : value
    }
    
    private var safeTitle: String {
        return title.isEmpty ? "Unknown" : title
    }
}

struct ToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    let onChange: (() -> Void)?
    
    init(label: String, icon: String, isOn: Binding<Bool>, onChange: (() -> Void)? = nil) {
        self.label = label
        self.icon = icon
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.body)
            Spacer()
            Toggle(label, isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)
                .onChange(of: isOn) { _ in
                    onChange?()
                }
        }
    }
}

struct CompactDNSServerView: View {
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 12) {
            // DNS Provider Selection
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Provider")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Picker("DNS Provider", selection: $settingsManager.selectedDNSProvider) {
                    ForEach(SettingsManager.DNSProvider.allCases) { provider in
                        Text(provider.displayName)
                            .tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: settingsManager.selectedDNSProvider) { _ in
                    // BACKEND CALL: Update DNS provider configuration
                    Task {
                        await settingsManager.updateDNSConfiguration()
                    }
                }
            }
            
            // DNS Protocol Selection
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Protocol")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                Picker("Protocol", selection: $settingsManager.selectedProtocol) {
                    ForEach(SettingsManager.DNSProtocol.allCases) { dnsProtocol in
                        Text(dnsProtocol.rawValue)
                            .tag(dnsProtocol)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settingsManager.selectedProtocol) { _ in
                    // BACKEND CALL: Update DNS protocol configuration
                    Task {
                        await settingsManager.updateDNSConfiguration()
                    }
                }
            }
            
            // Custom Configuration or Current Configuration Display
            if settingsManager.selectedDNSProvider == .custom {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Custom Configuration")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    let currentConfig = settingsManager.customDNSConfig.getConfig(for: settingsManager.selectedProtocol)
                    
                    Group {
                        switch settingsManager.selectedProtocol {
                        case .doH:
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Server URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("https://dns.example.com/dns-query", text: Binding(
                                    get: { currentConfig.url },
                                    set: { newValue in
                                        var newConfig = currentConfig
                                        newConfig.url = newValue
                                        settingsManager.updateCustomDNSConfig(for: .doH, config: newConfig)
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                
                                Text("Host (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("dns.example.com", text: Binding(
                                    get: { currentConfig.host },
                                    set: { newValue in
                                        var newConfig = currentConfig
                                        newConfig.host = newValue
                                        settingsManager.updateCustomDNSConfig(for: .doH, config: newConfig)
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            }
                            
                        case .doT, .doQ:
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Host")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("dns.example.com", text: Binding(
                                    get: { currentConfig.host },
                                    set: { newValue in
                                        var newConfig = currentConfig
                                        newConfig.host = newValue
                                        settingsManager.updateCustomDNSConfig(for: settingsManager.selectedProtocol, config: newConfig)
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                
                                Text("Port")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("853", text: Binding(
                                    get: { String(currentConfig.port) },
                                    set: { newValue in
                                        var newConfig = currentConfig
                                        newConfig.port = Int(newValue) ?? 853
                                        settingsManager.updateCustomDNSConfig(for: settingsManager.selectedProtocol, config: newConfig)
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(6)
                    
                    // Protocol description
                    Text(settingsManager.selectedProtocol.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Configuration")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    let config = settingsManager.getCurrentDNSConfig()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Server:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(config.host.isEmpty ? "Not configured" : config.host)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        if settingsManager.selectedProtocol != .doH {
                            HStack {
                                Text("Port:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(config.port)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        
                        if settingsManager.selectedProtocol == .doH && !config.url.isEmpty {
                            HStack {
                                Text("URL:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(config.url)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(4)
                }
            }
            
            // Test Connection
            HStack {
                Button(action: {
                    // BACKEND CALL: Test DNS connection
                    Task {
                        await settingsManager.testDNSConnection()
                    }
                }) {
                    HStack(spacing: 6) {
                        if settingsManager.isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "checkmark.shield")
                                .font(.caption)
                        }
                        Text(settingsManager.isTestingConnection ? "Testing..." : "Test")
                            .font(.caption)
                    }
                }
                .disabled(settingsManager.isTestingConnection || settingsManager.getCurrentDNSConfig().host.isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                // Test Result
                if let result = settingsManager.lastTestResult {
                    HStack(spacing: 4) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                            .font(.caption)
                        
                        if result.success {
                            Text("\(Int(result.responseTime * 1000))ms")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Failed")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Error message if test failed
            if let result = settingsManager.lastTestResult,
               !result.success,
               let error = result.error {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 800, height: 600)
    }
}

