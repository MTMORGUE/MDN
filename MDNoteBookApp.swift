//
// NotebookApp.swift
//
import SwiftUI

@main
struct MDNotebookApp: App {
    @StateObject private var store = NotebooksStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
