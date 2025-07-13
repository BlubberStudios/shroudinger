import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var isExtensionActive = false
    @State private var blockedQueries = 0
    @State private var totalQueries = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with compact status
            HStack(spacing: 16) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isExtensionActive ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shroudinger DNS Privacy")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isExtensionActive ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(isExtensionActive ? "Protection Active" : "Protection Inactive")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Main toggle prominently placed
                VStack(alignment: .trailing, spacing: 4) {
                    Toggle("DNS Protection", isOn: $isExtensionActive)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(1.1)
                    Text("DNS Protection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Statistics with better visual hierarchy
                    GroupBox {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("\(blockedQueries)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text("Blocked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(Color(.separatorColor))
                                .frame(width: 1, height: 40)
                            
                            VStack(spacing: 4) {
                                Text("\(totalQueries)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("Total Queries")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(Color(.separatorColor))
                                .frame(width: 1, height: 40)
                            
                            VStack(spacing: 4) {
                                Text("\((blockedQueries > 0 && totalQueries > 0) ? Int((Double(blockedQueries) / Double(totalQueries)) * 100) : 0)%")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                Text("Block Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Label("Statistics", systemImage: "chart.bar")
                            .font(.headline)
                    }
                    
                    // DNS Server Configuration
                    DNSServerView(settingsManager: settingsManager)
                    
                    // Settings grouped properly
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Label("Encrypted DNS", systemImage: "lock.shield")
                                Spacer()
                                Toggle("Encrypted DNS", isOn: $settingsManager.encryptedDNSEnabled)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                                    .onChange(of: settingsManager.encryptedDNSEnabled) { newValue in
                                        // BACKEND CALL: Update DNS encryption setting
                                        Task {
                                            await settingsManager.updateDNSConfiguration()
                                        }
                                    }
                            }
                            
                            Divider()
                            
                            HStack {
                                Label("Block Advertisements", systemImage: "eye.slash")
                                Spacer()
                                Toggle("Block Ads", isOn: $settingsManager.blockAdsEnabled)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                            }
                            
                            Divider()
                            
                            HStack {
                                Label("Block Trackers", systemImage: "hand.raised")
                                Spacer()
                                Toggle("Block Trackers", isOn: $settingsManager.blockTrackersEnabled)
                                    .toggleStyle(.switch)
                                    .labelsHidden()
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Label("Privacy Settings", systemImage: "gear")
                            .font(.headline)
                    }
                    
                    // Action buttons repositioned as utility buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            // Show settings
                        }) {
                            Label("Advanced Settings", systemImage: "gearshape")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        
                        Button(action: {
                            // Show logs
                        }) {
                            Label("Activity Logs", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 520, minHeight: 440)
        .background(Color(.windowBackgroundColor))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
