import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Header
            ModernCard(shadow: DesignSystem.Shadows.subtle) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundColor(settingsManager.servicesRunning ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                        Text("Shroudinger")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        StatusIndicator(status: settingsManager.servicesRunning ? .connected : .disconnected)
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            // Quick Stats
            if settingsManager.servicesRunning {
                ModernCard {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text("Quick Stats")
                                .font(DesignSystem.Typography.title)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            StatItem(title: "Blocked", value: "\(settingsManager.blockedCount)", color: DesignSystem.Colors.error)
                            StatItem(title: "Total", value: "\(settingsManager.totalCount)", color: DesignSystem.Colors.info)
                            StatItem(title: "Rate", value: "\(calculateBlockRate())%", color: DesignSystem.Colors.warning)
                        }
                    }
                }
            }
            
            Divider()
            
            // Toggle Control
            ModernCard {
                HStack {
                    Text("DNS Protection")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Toggle("", isOn: $settingsManager.servicesRunning)
                        .toggleStyle(.switch)
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
            
            Divider()
            
            // Quick Actions
            VStack(spacing: DesignSystem.Spacing.xs) {
                Button("Open Settings") {
                    // Show main window
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Quit Shroudinger") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundColor(DesignSystem.Colors.error)
                .font(DesignSystem.Typography.body)
            }
        }
        .frame(width: 280)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
    
    private func calculateBlockRate() -> Int {
        guard settingsManager.totalCount > 0 else { return 0 }
        return Int((Double(settingsManager.blockedCount) / Double(settingsManager.totalCount)) * 100)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(color)
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(SettingsManager())
    }
}