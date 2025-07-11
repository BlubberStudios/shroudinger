import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var isExtensionActive = false
    @State private var blockedQueries = 0
    @State private var totalQueries = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isExtensionActive ? .green : .gray)
                    
                    Text("Shroudinger DNS Privacy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isExtensionActive ? "Protection Active" : "Protection Inactive")
                        .font(.title2)
                        .foregroundColor(isExtensionActive ? .green : .red)
                }
                .padding()
                
                // Statistics
                HStack(spacing: 40) {
                    VStack {
                        Text("\(blockedQueries)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("Blocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(totalQueries)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Total Queries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\((blockedQueries > 0 && totalQueries > 0) ? Int((Double(blockedQueries) / Double(totalQueries)) * 100) : 0)%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Blocked Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
                
                // Controls
                VStack(spacing: 15) {
                    HStack {
                        Text("DNS Protection")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $isExtensionActive)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    HStack {
                        Text("Encrypted DNS")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $settingsManager.encryptedDNSEnabled)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    HStack {
                        Text("Block Ads")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $settingsManager.blockAdsEnabled)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    
                    HStack {
                        Text("Block Trackers")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $settingsManager.blockTrackersEnabled)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        // Show settings
                    }) {
                        Text("Settings")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        // Show logs
                    }) {
                        Text("View Logs")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Shroudinger DNS Privacy")
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
