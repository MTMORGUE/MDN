import SwiftUI

@main
struct MDNotebookApp: App {
    // Same key: "isDarkMode"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    @StateObject private var store = NotebooksStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                // If isDarkMode == true, force .dark, otherwise .light
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
