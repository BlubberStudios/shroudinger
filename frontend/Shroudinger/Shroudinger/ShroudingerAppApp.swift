import SwiftUI

@main
struct ShroudingerAppApp: App {
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 500)
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
        }
        .menuBarExtraStyle(.window)
    }
}