import SwiftUI

struct ContentView_Safe: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedSection: SidebarSection? = .overview
    
    enum SidebarSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case dnsSettings = "DNS Settings"
        case testingLogs = "Testing Logs"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "shield.fill"
            case .dnsSettings: return "network"
            case .testingLogs: return "wrench.and.screwdriver"
            }
        }
        
        // Dynamic cases based on testing logs setting
        static func availableCases(showTesting: Bool) -> [SidebarSection] {
            if showTesting {
                return [.overview, .dnsSettings, .testingLogs]
            } else {
                return [.overview, .dnsSettings]
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.automatic)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
    
    private var sidebarView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Simple header without complex computed properties
            ModernCard(isInteractive: true) {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "shield.fill")
                            .font(.title2)
                            .foregroundColor(settingsManager.servicesRunning ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                        
                        Text("Shroudinger")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .fixedSize()
                        
                        Spacer()
                        
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
                    
                    HStack {
                        StatusIndicator(status: settingsManager.servicesRunning ? .connected : .disconnected)
                        Spacer()
                    }
                }
            }
            
            // Debug info (remove in production)
            if settingsManager.testingLogsEnabled {
                Text("🧪 Testing Mode: ON")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.bottom, 4)
            }
            
            // Navigation List
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(SidebarSection.availableCases(showTesting: settingsManager.testingLogsEnabled)) { section in
                    Button(action: {
                        selectedSection = section
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: section.icon)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(selectedSection == section ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                                .frame(width: 20)
                            
                            Text(section.rawValue)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(selectedSection == section ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            // Debug indicator for testing logs
                            if section == .testingLogs {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                .fill(selectedSection == section ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.layoutPadding)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
    }
    
    private var detailView: some View {
        Group {
            switch selectedSection {
            case .overview:
                simpleOverviewView
            case .dnsSettings:
                simpleDNSView
            case .testingLogs:
                TestingLogsView()
            case .none:
                simpleOverviewView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
    
    private var simpleOverviewView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("System Status", systemImage: "shield.fill")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        HStack {
                            StatusIndicator(status: settingsManager.servicesRunning ? .connected : .disconnected)
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                Text(settingsManager.servicesRunning ? "DNS Protection Active" : "DNS Protection Inactive")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text(settingsManager.servicesRunning ? "Your DNS queries are encrypted and filtered" : "Click the toggle to enable protection")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
                
                if settingsManager.servicesRunning {
                    ModernCard {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Label("Protection Statistics", systemImage: "chart.bar.fill")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Spacer()
                            }
                            
                            HStack(spacing: DesignSystem.Spacing.md) {
                                SimpleStatCard(title: "Blocked", value: settingsManager.blockedCount, color: DesignSystem.Colors.error)
                                SimpleStatCard(title: "Total", value: settingsManager.totalCount, color: DesignSystem.Colors.info)
                                SimpleStatCard(title: "Block Rate", value: calculateSafeBlockRate(), color: DesignSystem.Colors.success)
                            }
                        }
                    }
                }
                
                // Development Tools
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("Development Tools", systemImage: "wrench.and.screwdriver")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            // Testing Logs Toggle
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                    Text("Testing Logs")
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    Text("Show middleware activity logs (testing only)")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $settingsManager.testingLogsEnabled)
                                    .toggleStyle(.switch)
                                    .onChange(of: settingsManager.testingLogsEnabled) { newValue in
                                        print("🧪 Testing logs enabled changed to: \(newValue)")
                                        settingsManager.saveSettings()
                                    }
                            }
                            
                            // Testing Logs Visibility Toggle (if enabled)
                            if settingsManager.testingLogsEnabled {
                                HStack {
                                    Image(systemName: "eye")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                        Text("Show in Overview")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text("Display recent logs in main view")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $settingsManager.testingLogsVisible)
                                        .toggleStyle(.switch)
                                        .onChange(of: settingsManager.testingLogsVisible) { _ in
                                            settingsManager.saveSettings()
                                        }
                                }
                            }
                        }
                    }
                }
                
                // Testing Logs Preview (if enabled and visible)
                if settingsManager.testingLogsEnabled && settingsManager.testingLogsVisible {
                    testingLogsPreview
                }
            }
        }
        .padding(DesignSystem.Spacing.sectionMargin)
        .navigationTitle("Overview")
    }
    
    private var simpleDNSView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // DNS Provider Selection
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("DNS Provider", systemImage: "server.rack")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        Picker("DNS Provider", selection: $settingsManager.selectedDNSProvider) {
                            ForEach(SettingsManager.DNSProvider.allCases) { provider in
                                Text(provider.displayName)
                                    .tag(provider)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // DNS Protocol Selection
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("Encryption Protocol", systemImage: "lock.shield")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        Picker("Protocol", selection: $settingsManager.selectedProtocol) {
                            ForEach(SettingsManager.DNSProtocol.allCases) { dnsProtocol in
                                Text(dnsProtocol.rawValue)
                                    .tag(dnsProtocol)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(settingsManager.selectedProtocol.description)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Custom DNS Configuration (if custom provider selected)
                if settingsManager.selectedDNSProvider == .custom {
                    ModernCard {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Label("Custom Configuration", systemImage: "gear")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Spacer()
                            }
                            
                            let currentConfig = settingsManager.customDNSConfig.getConfig(for: settingsManager.selectedProtocol)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                if settingsManager.selectedProtocol == .doH {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Server URL")
                                            .font(DesignSystem.Typography.captionMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        TextField("https://dns.example.com/dns-query", text: Binding(
                                            get: { currentConfig.url },
                                            set: { newValue in
                                                var newConfig = currentConfig
                                                newConfig.url = newValue
                                                settingsManager.updateCustomDNSConfig(for: .doH, config: newConfig)
                                            }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Server Host")
                                            .font(DesignSystem.Typography.captionMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        TextField("dns.example.com", text: Binding(
                                            get: { currentConfig.host },
                                            set: { newValue in
                                                var newConfig = currentConfig
                                                newConfig.host = newValue
                                                settingsManager.updateCustomDNSConfig(for: settingsManager.selectedProtocol, config: newConfig)
                                            }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                        
                                        Text("Port")
                                            .font(DesignSystem.Typography.captionMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        TextField("853", text: Binding(
                                            get: { String(currentConfig.port) },
                                            set: { newValue in
                                                var newConfig = currentConfig
                                                newConfig.port = Int(newValue) ?? 853
                                                settingsManager.updateCustomDNSConfig(for: settingsManager.selectedProtocol, config: newConfig)
                                            }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Current Configuration Display
                    ModernCard {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Label("Current Configuration", systemImage: "checkmark.shield")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Spacer()
                            }
                            
                            let config = settingsManager.getCurrentDNSConfig()
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                HStack {
                                    Text("Server:")
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text(config.host.isEmpty ? "Not configured" : config.host)
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    Spacer()
                                }
                                
                                if settingsManager.selectedProtocol != .doH {
                                    HStack {
                                        Text("Port:")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        Text("\(config.port)")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Spacer()
                                    }
                                }
                                
                                if settingsManager.selectedProtocol == .doH && !config.url.isEmpty {
                                    HStack {
                                        Text("URL:")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        Text(config.url)
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Connection Test
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("Connection Test", systemImage: "network.badge.shield.half.filled")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        HStack {
                            Button(action: {
                                Task {
                                    await settingsManager.testDNSConnection()
                                }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    if settingsManager.isTestingConnection {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle())
                                    } else {
                                        Image(systemName: "checkmark.shield")
                                    }
                                    Text(settingsManager.isTestingConnection ? "Testing..." : "Test Connection")
                                }
                            }
                            .disabled(settingsManager.isTestingConnection || settingsManager.getCurrentDNSConfig().host.isEmpty)
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Spacer()
                            
                            if let result = settingsManager.lastTestResult {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(result.success ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                                    
                                    if result.success {
                                        Text("\(Int(result.responseTime * 1000))ms")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    } else {
                                        Text("Failed")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.error)
                                    }
                                }
                            }
                        }
                        
                        if let result = settingsManager.lastTestResult,
                           !result.success,
                           let error = result.error {
                            Text(error)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.error)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sectionMargin)
        .navigationTitle("DNS Settings")
    }
    
    
    // Safe calculation that won't cause infinite loops
    private func calculateSafeBlockRate() -> Int {
        guard settingsManager.totalCount > 0 else { return 0 }
        let rate = (Double(settingsManager.blockedCount) / Double(settingsManager.totalCount)) * 100
        return Int(rate.rounded())
    }
    
    private var testingLogsPreview: some View {
        ModernCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Label("Recent Middleware Activity", systemImage: "list.bullet.rectangle")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button("View All") {
                        selectedSection = .testingLogs
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // Compact logs view
                CompactTestingLogsView()
                    .frame(maxHeight: 200)
            }
        }
    }
}

// Simplified stat card that avoids complex computed properties
struct SimpleStatCard: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        ModernCard(shadow: DesignSystem.Shadows.subtle) {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                Text("\(value)")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(color)
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ContentView_Safe_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Safe()
            .environmentObject(SettingsManager())
            .frame(width: 800, height: 600)
    }
}