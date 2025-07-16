import SwiftUI

struct MenuBarView_Modern: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Section
            menuSection {
                statusItem
                
                if settingsManager.servicesRunning {
                    quickStatsItem
                }
            }
            
            menuSeparator
            
            // Control Section
            menuSection {
                toggleProtectionItem
                
                if settingsManager.servicesRunning {
                    testConnectionItem
                }
            }
            
            menuSeparator
            
            // Settings Section
            menuSection {
                showMainWindowItem
                showDNSSettingsItem
            }
            
            menuSeparator
            
            // Info Section
            menuSection {
                aboutItem
            }
            
            menuSeparator
            
            // Quit Section
            menuSection {
                quitItem
            }
        }
        .frame(width: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Menu Sections
    
    private func menuSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var menuSeparator: some View {
        Divider()
            .background(Color(NSColor.separatorColor))
            .padding(.horizontal, 8)
    }
    
    // MARK: - Menu Items
    
    private var statusItem: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.fill")
                .font(.title2)
                .foregroundColor(settingsManager.servicesRunning ? .green : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Shroudinger")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(settingsManager.servicesRunning ? .green : .secondary)
                        .frame(width: 8, height: 8)
                    
                    Text(settingsManager.servicesRunning ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
    
    private var quickStatsItem: some View {
        HStack(spacing: 0) {
            statColumn(title: "Blocked", value: "\(settingsManager.blockedCount)", color: .red)
            statColumn(title: "Total", value: "\(settingsManager.totalCount)", color: .blue)
            statColumn(title: "Rate", value: "\(calculateBlockRate())%", color: .green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
    
    private func statColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var toggleProtectionItem: some View {
        Button(action: {
            Task {
                if settingsManager.servicesRunning {
                    await settingsManager.stopServices()
                } else {
                    await settingsManager.startServices()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: settingsManager.servicesRunning ? "stop.circle" : "play.circle")
                    .font(.title2)
                    .foregroundColor(settingsManager.servicesRunning ? .red : .green)
                    .frame(width: 24)
                
                Text(settingsManager.servicesRunning ? "Stop Protection" : "Start Protection")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("⌘P")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    private var testConnectionItem: some View {
        Button(action: {
            Task {
                await settingsManager.testDNSConnection()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Test DNS Connection")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if settingsManager.isTestingConnection {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let result = settingsManager.lastTestResult {
                    HStack(spacing: 4) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                            .font(.caption)
                        
                        if result.success {
                            Text("\(Int(result.responseTime * 1000))ms")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(MenuItemButtonStyle())
        .disabled(settingsManager.isTestingConnection)
    }
    
    private var showMainWindowItem: some View {
        Button(action: {
            NSApp.activate(ignoringOtherApps: true)
            // Find and show main window
            if let window = NSApp.windows.first(where: { $0.title == "Shroudinger" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "macwindow")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Show Main Window")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("⌘M")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    private var showDNSSettingsItem: some View {
        Button(action: {
            NSApp.activate(ignoringOtherApps: true)
            // Show main window and navigate to DNS settings
            if let window = NSApp.windows.first(where: { $0.title == "Shroudinger" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Text("DNS Settings")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("⌘D")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    private var aboutItem: some View {
        Button(action: {
            // Show about dialog
            NSApp.orderFrontStandardAboutPanel(nil)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("About Shroudinger")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    private var quitItem: some View {
        Button(action: {
            NSApp.terminate(nil)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "power")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                Text("Quit Shroudinger")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("⌘Q")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    // MARK: - Helpers
    
    private func calculateBlockRate() -> Int {
        guard settingsManager.totalCount > 0 else { return 0 }
        return Int((Double(settingsManager.blockedCount) / Double(settingsManager.totalCount)) * 100)
    }
}

// MARK: - Custom Button Style

struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct MenuBarView_Modern_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView_Modern()
            .environmentObject(SettingsManager())
            .frame(width: 280)
            .background(Color(NSColor.windowBackgroundColor))
    }
}