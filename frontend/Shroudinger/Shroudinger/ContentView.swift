import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showAdvancedSettings = false
    @State private var selectedSection: SidebarSection? = .overview
    
    enum SidebarSection: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case dnsSettings = "DNS Settings"
        case logs = "Activity Logs"
        case testingLogs = "Testing Logs"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "shield.fill"
            case .dnsSettings: return "network"
            case .logs: return "list.bullet.rectangle"
            case .testingLogs: return "wrench.and.screwdriver"
            }
        }
        
        // Dynamic cases based on testing logs setting
        static func availableCases(showTesting: Bool) -> [SidebarSection] {
            if showTesting {
                return [.overview, .dnsSettings, .logs, .testingLogs]
            } else {
                return [.overview, .dnsSettings, .logs]
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebarView
            
            Divider()
            
            // Detail View
            detailView
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .tint(Color.clear)
    }
    
    private var sidebarView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header with compact status
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
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(width: 20)
                            
                            Text(section.rawValue)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            // Debug indicator for testing logs
                            if section == .testingLogs {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(selectedSection == section ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accentColor(Color.clear)
                }
            }
            
            Spacer()
            
            // Quick Stats if running
            if settingsManager.servicesRunning {
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text("Quick Stats")
                                .font(DesignSystem.Typography.title)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            StatCardView(title: "Blocked", value: blockedValue, color: DesignSystem.Colors.error)
                            StatCardView(title: "Total", value: totalValue, color: DesignSystem.Colors.info)
                            StatCardView(title: "Rate", value: rateValue, color: DesignSystem.Colors.warning)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.layoutPadding)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
    }
    
    private var detailView: some View {
        Group {
            switch selectedSection {
            case .overview:
                overviewView
            case .dnsSettings:
                DNSEncryptionView()
            case .logs:
                activityLogsView
            case .testingLogs:
                TestingLogsView()
            case .none:
                overviewView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundPrimary)
        .contentShape(Rectangle())
    }
    
    private var overviewView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // System Status
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
                
                // Quick Stats if running
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
                                StatCardView(title: "Blocked", value: blockedValue, color: DesignSystem.Colors.error)
                                StatCardView(title: "Total", value: totalValue, color: DesignSystem.Colors.info)
                                StatCardView(title: "Block Rate", value: rateValue, color: DesignSystem.Colors.success)
                            }
                        }
                    }
                }
                
                // Development Tools (moved up for better visibility) - REBUILD TEST
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
                
                // Privacy Information
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("Privacy Features", systemImage: "eye.slash.fill")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            FeatureRow(icon: "lock.shield", title: "DNS Encryption", description: "All DNS queries are encrypted using DoT/DoH/DoQ")
                            FeatureRow(icon: "eye.slash", title: "No Logging", description: "DNS queries are processed in-memory only")
                            FeatureRow(icon: "shield.checkered", title: "Ad Blocking", description: "Malicious and advertising domains are blocked")
                            FeatureRow(icon: "speedometer", title: "High Performance", description: "Sub-millisecond response times with smart caching")
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
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                // Compact logs view
                CompactTestingLogsView()
                    .frame(maxHeight: 200)
            }
        }
    }
    
    private var activityLogsView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Privacy Notice
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("Privacy Notice", systemImage: "eye.slash.fill")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Spacer()
                        }
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(DesignSystem.Colors.success)
                                    .font(DesignSystem.Typography.title)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                    Text("Activity Logging is Disabled")
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    Text("DNS queries are processed in-memory only and never logged to disk for maximum privacy protection.")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                
                // What We Track
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("What We Track", systemImage: "chart.line.uptrend.xyaxis")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            FeatureRow(icon: "number.circle", title: "Query Counts", description: "Total number of DNS queries (not the domains)")
                            FeatureRow(icon: "shield.lefthalf.filled", title: "Block Statistics", description: "Number of blocked queries for threat analysis")
                            FeatureRow(icon: "clock", title: "Response Times", description: "DNS resolution performance metrics")
                            FeatureRow(icon: "checkmark.shield", title: "Service Status", description: "Whether protection services are running")
                        }
                    }
                }
                
                // What We Don't Track
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Label("What We Don't Track", systemImage: "eye.slash")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.error)
                            Spacer()
                        }
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            FeatureRow(icon: "globe.slash", title: "Domain Names", description: "We never log which domains you visit")
                            FeatureRow(icon: "person.slash", title: "Personal Data", description: "No IP addresses, timestamps, or user tracking")
                            FeatureRow(icon: "externaldrive.badge.xmark", title: "Persistent Storage", description: "No DNS data is ever written to disk")
                            FeatureRow(icon: "antenna.radiowaves.left.and.right.slash", title: "Analytics", description: "No telemetry or usage analytics collected")
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.sectionMargin)
        .navigationTitle("Activity Logs")
    }
    
    // Legacy layout method (keeping for reference)
    private var legacyLayoutView: some View {
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
        .frame(
            minWidth: showAdvancedSettings ? 680 : 300, 
            idealWidth: showAdvancedSettings ? 900 : 360,
            maxWidth: showAdvancedSettings ? 1400 : 400, 
            minHeight: 480, 
            idealHeight: 600,
            maxHeight: .infinity
        )
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
                .disabled(settingsManager.isTestingConnection || {
                    let config = settingsManager.getCurrentDNSConfig()
                    if settingsManager.selectedProtocol == .doH {
                        return config.url.isEmpty
                    } else {
                        return config.host.isEmpty
                    }
                }())
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SettingsManager())
            .frame(width: 800, height: 600)
    }
}

