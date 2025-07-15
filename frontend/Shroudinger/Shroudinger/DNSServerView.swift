import SwiftUI

struct DNSServerView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var showingCustomConfig = false
    
    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                // DNS Provider Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("DNS Provider", systemImage: "server.rack")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Picker("DNS Provider", selection: $settingsManager.selectedDNSProvider) {
                        ForEach(SettingsManager.DNSProvider.allCases) { provider in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.displayName)
                                    .font(.body)
                                Text(provider.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: settingsManager.selectedDNSProvider) { newValue in
                        // BACKEND CALL: Update DNS provider configuration
                        Task {
                            await settingsManager.updateDNSConfiguration()
                        }
                    }
                }
                
                Divider()
                
                // DNS Protocol Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Encryption Protocol", systemImage: "lock.shield")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Picker("Protocol", selection: $settingsManager.selectedProtocol) {
                        ForEach(SettingsManager.DNSProtocol.allCases) { dnsProtocol in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dnsProtocol.displayName)
                                    .font(.body)
                                Text(dnsProtocol.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(dnsProtocol)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: settingsManager.selectedProtocol) { newValue in
                        // BACKEND CALL: Update DNS protocol configuration
                        Task {
                            await settingsManager.updateDNSConfiguration()
                        }
                    }
                }
                
                Divider()
                
                // Current Configuration Display
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Current Configuration", systemImage: "gear")
                            .font(.headline)
                        Spacer()
                        
                        if settingsManager.selectedDNSProvider == .custom {
                            Button("Configure") {
                                showingCustomConfig = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    let config = settingsManager.getCurrentDNSConfig()
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Server")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(config.host.isEmpty ? "Not configured" : config.host)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        if settingsManager.selectedProtocol != .doH {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Port")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(config.port)")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if settingsManager.selectedProtocol == .doH && !config.url.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(config.url)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                
                // Test Connection Section
                VStack(spacing: 8) {
                    HStack {
                        Button(action: {
                            // BACKEND CALL: Test DNS connection
                            Task {
                                await settingsManager.testDNSConnection()
                            }
                        }) {
                            HStack {
                                if settingsManager.isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Image(systemName: "checkmark.shield")
                                }
                                Text(settingsManager.isTestingConnection ? "Testing..." : "Test Encryption")
                            }
                        }
                        .disabled(settingsManager.isTestingConnection || settingsManager.getCurrentDNSConfig().host.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        
                        Spacer()
                        
                        // Test Result Indicator
                        if let result = settingsManager.lastTestResult {
                            HStack(spacing: 6) {
                                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result.success ? .green : .red)
                                
                                if result.success {
                                    Text("\(Int(result.responseTime * 1000))ms")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Failed")
                                        .font(.caption)
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
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.vertical, 8)
        } label: {
            Label("DNS Server Configuration", systemImage: "network")
                .font(.headline)
        }
        .sheet(isPresented: $showingCustomConfig) {
            CustomDNSConfigView(settingsManager: settingsManager)
        }
    }
}

struct CustomDNSConfigView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempConfig: SettingsManager.CustomDNSConfig
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self._tempConfig = State(initialValue: settingsManager.customDNSConfig)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Configure your custom DNS servers for each encryption protocol. Leave fields empty for protocols you don't want to use.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // DoH Configuration
                Section("DNS over HTTPS (DoH)") {
                    LabeledContent("Server URL") {
                        TextField("https://dns.example.com/dns-query", text: Binding(
                            get: { tempConfig.doHConfig.url },
                            set: { tempConfig.doHConfig.url = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    LabeledContent("Host") {
                        TextField("dns.example.com", text: Binding(
                            get: { tempConfig.doHConfig.host },
                            set: { tempConfig.doHConfig.host = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    LabeledContent("Port") {
                        TextField("443", value: Binding(
                            get: { tempConfig.doHConfig.port },
                            set: { tempConfig.doHConfig.port = $0 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                }
                
                // DoT Configuration
                Section("DNS over TLS (DoT)") {
                    LabeledContent("Host") {
                        TextField("dns.example.com", text: Binding(
                            get: { tempConfig.doTConfig.host },
                            set: { tempConfig.doTConfig.host = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    LabeledContent("Port") {
                        TextField("853", value: Binding(
                            get: { tempConfig.doTConfig.port },
                            set: { tempConfig.doTConfig.port = $0 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                }
                
                // DoQ Configuration
                Section("DNS over QUIC (DoQ)") {
                    LabeledContent("Host") {
                        TextField("dns.example.com", text: Binding(
                            get: { tempConfig.doQConfig.host },
                            set: { tempConfig.doQConfig.host = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                    
                    LabeledContent("Port") {
                        TextField("853", value: Binding(
                            get: { tempConfig.doQConfig.port },
                            set: { tempConfig.doQConfig.port = $0 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .navigationTitle("Custom DNS Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // BACKEND CALL: Save custom DNS configuration
                        settingsManager.customDNSConfig = tempConfig
                        settingsManager.saveSettings()
                        
                        Task {
                            await settingsManager.updateDNSConfiguration()
                        }
                        
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct DNSServerView_Previews: PreviewProvider {
    static var previews: some View {
        DNSServerView(settingsManager: SettingsManager())
            .frame(width: 500)
    }
}