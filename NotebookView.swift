//
// NotebookView.swift
//
import SwiftUI

struct NotebookView: View {
    @EnvironmentObject var store: NotebooksStore
    
    let notebook: Notebook
    @State private var updatedNotebook: Notebook

    init(notebook: Notebook) {
        self.notebook = notebook
        // Make a local copy
        self._updatedNotebook = State(initialValue: notebook)
    }

    var body: some View {
        List {
            ForEach(updatedNotebook.pages.indices, id: \.self) { pageIndex in
                NavigationLink(
                    destination: PageView(
                        notebookID: updatedNotebook.id,
                        page: updatedNotebook.pages[pageIndex]
                    )
                ) {
                    Text(updatedNotebook.pages[pageIndex].title)
                }
            }
            .onDelete(perform: deletePages)
        }
        .navigationTitle(updatedNotebook.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Page") {
                    let newPage = Page(title: "New Page", content: [.text("Empty content...")])
                    updatedNotebook.pages.append(newPage)
                }
            }
        }
        .onDisappear {
            // Save changes back to store
            store.updateNotebook(updatedNotebook)
        }
    }

    func deletePages(at offsets: IndexSet) {
        updatedNotebook.pages.remove(atOffsets: offsets)
    }
}
