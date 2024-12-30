//
// NotebooksStore.swift
//
import SwiftUI
import Combine

class NotebooksStore: ObservableObject {
    @Published var notebooks: [Notebook] {
        didSet {
            saveToDisk()
        }
    }
    
    init(notebooks: [Notebook] = []) {
        self.notebooks = notebooks
        loadFromDisk()  // Attempt to load an existing file
    }
    
    private let saveFileName = "NotebooksData.json"
    
    // MARK: - Saving & Loading
    func saveToDisk() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(notebooks)
            let url = getDocumentsDirectory().appendingPathComponent(saveFileName)
            try data.write(to: url)
        } catch {
            print("Error saving notebooks to disk: \(error)")
        }
    }
    
    func loadFromDisk() {
        let url = getDocumentsDirectory().appendingPathComponent(saveFileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let loaded = try decoder.decode([Notebook].self, from: data)
            self.notebooks = loaded
        } catch {
            print("Error loading notebooks from disk: \(error)")
        }
    }
    
    // Helper to get the user documents directory (for iOS).
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Updating notebooks in memory
    func updateNotebook(_ updated: Notebook) {
        guard let idx = notebooks.firstIndex(where: { $0.id == updated.id }) else { return }
        notebooks[idx] = updated
    }
    
    func updatePage(in notebookID: UUID, page: Page) {
        guard let nbIndex = notebooks.firstIndex(where: { $0.id == notebookID }) else { return }
        guard let pgIndex = notebooks[nbIndex].pages.firstIndex(where: { $0.id == page.id }) else { return }
        notebooks[nbIndex].pages[pgIndex] = page
    }
}
