import SwiftUI

struct NotebookView: View {
    @EnvironmentObject var store: NotebooksStore

    let notebook: Notebook

    @State private var updatedNotebook: Notebook
    @State private var selectedPageIDs = Set<UUID>() // For multi-select
    @State private var editMode: EditMode = .inactive

    // For rename sheet
    @State private var isRenameSheetPresented = false
    @State private var renameTitle = ""
    @State private var renamePageID: UUID?

    init(notebook: Notebook) {
        self.notebook = notebook
        // Make a local copy to allow editing
        _updatedNotebook = State(initialValue: notebook)
    }

    var body: some View {
        List(selection: $selectedPageIDs) {
            ForEach(updatedNotebook.pages) { page in
                NavigationLink(
                    destination: PageView(
                        notebookID: updatedNotebook.id,
                        page: page
                    )
                ) {
                    Text(page.title)
                }
                .tag(page.id) // Important for multi-selection
            }
            .onDelete(perform: deletePages)
        }
        .navigationTitle(updatedNotebook.title)
        // Apply custom edit mode
        .environment(\.editMode, $editMode)
        .toolbar {
            // 1) Left side: (optional) – none shown here

            // 2) Right side: “Edit” when inactive, or “...” when active
            ToolbarItem(placement: .navigationBarTrailing) {
                if editMode == .inactive {
                    // Normal mode: Show "Edit" button
                    Button("Edit") {
                        editMode = .active
                    }
                } else {
                    // Edit mode: Show "..." menu with Create, Delete, Rename, Done
                    Menu("...") {
                        Button("Create") {
                            addPage()
                        }
                        Button("Delete") {
                            deleteSelectedPages()
                        }
                        Button("Rename") {
                            renameSelectedPage()
                        }
                        // **Done** item to exit edit mode
                        Button("Done") {
                            editMode = .inactive
                            selectedPageIDs.removeAll()
                        }
                    }
                }
            }
        }
        // 3) Rename page sheet
        .sheet(isPresented: $isRenameSheetPresented) {
            VStack(spacing: 20) {
                Text("Rename Page").font(.headline)
                TextField("New title", text: $renameTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                HStack {
                    Button("Cancel") {
                        isRenameSheetPresented = false
                    }
                    Spacer()
                    Button("Save") {
                        if let pgID = renamePageID,
                           let idx = updatedNotebook.pages.firstIndex(where: { $0.id == pgID }) {
                            updatedNotebook.pages[idx].title = renameTitle
                        }
                        isRenameSheetPresented = false
                    }
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
        .onDisappear {
            // Save back to store
            store.updateNotebook(updatedNotebook)
        }
    }

    // MARK: - Actions

    func deletePages(at offsets: IndexSet) {
        updatedNotebook.pages.remove(atOffsets: offsets)
    }

    func addPage() {
        let newPage = Page(title: "New Page", content: [.text("Empty content...")])
        updatedNotebook.pages.append(newPage)
    }

    func deleteSelectedPages() {
        updatedNotebook.pages.removeAll { selectedPageIDs.contains($0.id) }
        selectedPageIDs.removeAll()
    }

    func renameSelectedPage() {
        guard let firstID = selectedPageIDs.first,
              let pg = updatedNotebook.pages.first(where: { $0.id == firstID }) else {
            return
        }
        renamePageID = pg.id
        renameTitle = pg.title
        isRenameSheetPresented = true
    }
}
