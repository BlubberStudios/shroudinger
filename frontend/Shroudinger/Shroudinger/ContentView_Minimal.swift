import SwiftUI

struct ContentView_Minimal: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack {
            Text("Shroudinger")
                .font(.title)
            
            Text("App is running")
                .foregroundColor(.secondary)
            
            Button("Test Toggle") {
                settingsManager.servicesRunning.toggle()
            }
            
            Text("Services: \(settingsManager.servicesRunning ? "Running" : "Stopped")")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Minimal_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_Minimal()
            .environmentObject(SettingsManager())
    }
}