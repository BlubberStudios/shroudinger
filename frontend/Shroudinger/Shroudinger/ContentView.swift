import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var isExtensionActive = false
    @State private var blockedQueries = 0
    @State private var totalQueries = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Main Controls
            VStack(spacing: 16) {
                // Header with compact status
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(isExtensionActive ? .green : .secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shroudinger")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isExtensionActive ? .green : .red)
                                .frame(width: 6, height: 6)
                            Text(isExtensionActive ? "Active" : "Inactive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Main toggle prominently placed
                    Toggle("DNS Protection", isOn: $isExtensionActive)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // Statistics - Horizontal Layout
                HStack(spacing: 12) {
                    StatCardView(title: "Blocked", value: "\(blockedQueries)", color: .red)
                    StatCardView(title: "Total", value: "\(totalQueries)", color: .blue)
                    StatCardView(title: "Rate", value: "\((blockedQueries > 0 && totalQueries > 0) ? Int((Double(blockedQueries) / Double(totalQueries)) * 100) : 0)%", color: .orange)
                }
                
                // Privacy Settings - Compact
                VStack(spacing: 8) {
                    HStack {
                        Label("Privacy Settings", systemImage: "gear")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        ToggleRow(label: "Encrypted DNS", icon: "lock.shield", isOn: $settingsManager.encryptedDNSEnabled) {
                            // BACKEND CALL: Update DNS encryption setting
                            Task {
                                await settingsManager.updateDNSConfiguration()
                            }
                        }
                        
                        ToggleRow(label: "Block Ads", icon: "eye.slash", isOn: $settingsManager.blockAdsEnabled)
                        
                        ToggleRow(label: "Block Trackers", icon: "hand.raised", isOn: $settingsManager.blockTrackersEnabled)
                    }
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 8) {
                    Button("Advanced Settings") {
                        // Show settings
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Button("Activity Logs") {
                        // Show logs
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
            .frame(width: 280)
            .padding(16)
            
            Divider()
            
            // Right Panel - DNS Configuration
            VStack(spacing: 0) {
                // DNS Configuration Header
                HStack {
                    Label("DNS Configuration", systemImage: "network")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.controlBackgroundColor))
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 16) {
                        CompactDNSServerView(settingsManager: settingsManager)
                    }
                    .padding(16)
                }
            }
            .frame(minWidth: 350)
        }
        .frame(minWidth: 680, maxWidth: 1200, minHeight: 480, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Helper Components

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
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
                CustomConfigInputView(settingsManager: settingsManager)
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

struct CustomConfigInputView: View {
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
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
    }
}
