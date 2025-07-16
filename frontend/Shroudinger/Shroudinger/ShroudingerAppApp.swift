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
                    for window in NSApp.windows {
                        if window.isVisible && window.canBecomeKey {
                            window.makeKeyAndOrderFront(nil)
                            break
                        }
                    }
                }
                .keyboardShortcut("m", modifiers: .command)
                
                Button("Toggle DNS Protection") {
                    settingsManager.servicesRunning.toggle()
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Button("DNS Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        if window.isVisible && window.canBecomeKey {
                            window.makeKeyAndOrderFront(nil)
                            break
                        }
                    }
                    print("DNS Settings keyboard shortcut triggered")
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