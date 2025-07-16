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
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }
            
            CommandGroup(after: .appInfo) {
                Button("Show Main Window") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title == "Shroudinger" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("m", modifiers: .command)
                
                Button("Toggle DNS Protection") {
                    Task {
                        if settingsManager.servicesRunning {
                            await settingsManager.stopServices()
                        } else {
                            await settingsManager.startServices()
                        }
                    }
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Button("DNS Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title == "Shroudinger" }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                    // Could add logic to navigate to DNS settings tab
                }
                .keyboardShortcut("d", modifiers: .command)
            }
        }
        
        MenuBarExtra {
            MenuBarView_Modern()
                .environmentObject(settingsManager)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}