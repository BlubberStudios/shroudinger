import SwiftUI

@main
struct ShroudingerAppApp: App {
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView_Safe()
                .environmentObject(settingsManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 500)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Shroudinger") {
                    // About dialog
                }
            }
        }
        
        MenuBarExtra {
            MenuBarView()
                .environmentObject(settingsManager)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}