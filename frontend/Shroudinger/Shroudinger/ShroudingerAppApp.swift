import SwiftUI

@main
struct ShroudingerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        
        MenuBarExtra("Shroudinger", systemImage: "shield.fill") {
            Button("Show Main Window") {
                // Show main window
            }
            .keyboardShortcut("m", modifiers: [.command])
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }
}