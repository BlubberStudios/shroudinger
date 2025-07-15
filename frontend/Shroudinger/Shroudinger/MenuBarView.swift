import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(settingsManager.servicesRunning ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shroudinger")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(settingsManager.servicesRunning ? .green : .red)
                            .frame(width: 6, height: 6)
                        Text(settingsManager.servicesRunning ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // Quick Stats
            if settingsManager.servicesRunning {
                VStack(spacing: 8) {
                    HStack {
                        Text("Quick Stats")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        StatItem(title: "Blocked", value: "\(settingsManager.blockedCount)", color: .red)
                        StatItem(title: "Total", value: "\(settingsManager.totalCount)", color: .blue)
                        StatItem(title: "Rate", value: "\(calculateBlockRate())%", color: .orange)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Divider()
            
            // Toggle Control
            HStack {
                Text("DNS Protection")
                    .font(.subheadline)
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
            .padding(.horizontal, 16)
            
            Divider()
            
            // Quick Actions
            VStack(spacing: 8) {
                Button("Open Settings") {
                    // Show main window
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
                
                Button("Quit Shroudinger") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(Color(.controlBackgroundColor))
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
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
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