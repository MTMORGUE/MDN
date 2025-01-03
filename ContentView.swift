import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NotebooksStore

    // Track current multi-selection of notebooks
    @State private var selectedNotebookIDs = Set<UUID>()
    // Manage our own EditMode
    @State private var editMode: EditMode = .inactive

    // For rename sheet
    @State private var isRenameSheetPresented = false
    @State private var renameTitle = ""
    @State private var renameNotebookID: UUID?

    // Show/hide the side menu
    @State private var showSettingsMenu = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1) Main Notebook List in a NavigationView
            NavigationView {
                List(selection: $selectedNotebookIDs) {
                    ForEach(store.notebooks) { notebook in
                        NavigationLink(destination: NotebookView(notebook: notebook)) {
                            Text(notebook.title)
                        }
                    }
                    .onDelete(perform: deleteNotebooks)
                }
                .navigationTitle("Notebooks")
                // Apply the custom edit mode to the list
                .environment(\.editMode, $editMode)
                .toolbar {
                    // Left side: Gear button to open side menu
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                showSettingsMenu = true
                            }
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }

                    // Right side: Edit or "..." menu
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if editMode == .inactive {
                            // Show Edit button if not in edit mode
                            Button("Edit") {
                                editMode = .active
                            }
                        } else {
                            // In edit mode, show the "..." menu with Create, Delete, Rename, Done
                            Menu("...") {
                                Button("Create") {
                                    createNotebook()
                                }
                                Button("Delete") {
                                    deleteSelectedNotebooks()
                                }
                                Button("Rename") {
                                    renameSelectedNotebook()
                                }
                                // Done button so user can exit edit mode
                                Button("Done") {
                                    editMode = .inactive
                                    selectedNotebookIDs.removeAll()
                                }
                            }
                        }
                    }
                }
            }

            // 2) If showSettingsMenu, dim background and show side menu
            if showSettingsMenu {
                // Dim overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Close the menu on tap
                        withAnimation {
                            showSettingsMenu = false
                        }
                    }

                // Side menu
                HStack(spacing: 0) {
                    // Replace SettingsView with your own or merged SettingsView
                    SettingsView {
                        // Provide a closure to close the menu
                        withAnimation {
                            showSettingsMenu = false
                        }
                    }
                    .frame(width: 250)
                    .transition(.move(edge: .leading))

                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        // Present the rename sheet if needed
        .sheet(isPresented: $isRenameSheetPresented) {
            renameSheet
        }
    }

    // MARK: - Rename Sheet
    private var renameSheet: some View {
        VStack(spacing: 20) {
            Text("Rename Notebook").font(.headline)
            TextField("New title", text: $renameTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    isRenameSheetPresented = false
                }
                Spacer()
                Button("Save") {
                    if let nbID = renameNotebookID,
                       let idx = store.notebooks.firstIndex(where: { $0.id == nbID }) {
                        store.notebooks[idx].title = renameTitle
                    }
                    isRenameSheetPresented = false
                }
            }
            .padding()
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    /// Swipe-to-delete handler
    func deleteNotebooks(at offsets: IndexSet) {
        store.notebooks.remove(atOffsets: offsets)
    }

    /// Create a new blank notebook
    func createNotebook() {
        let newNb = Notebook(title: "New Notebook", pages: [])
        store.notebooks.append(newNb)
    }

    /// Delete all currently selected notebooks in multi-select mode
    func deleteSelectedNotebooks() {
        store.notebooks.removeAll { selectedNotebookIDs.contains($0.id) }
        selectedNotebookIDs.removeAll()
    }

    /// Rename the first selected notebook
    func renameSelectedNotebook() {
        guard let firstID = selectedNotebookIDs.first,
              let nb = store.notebooks.first(where: { $0.id == firstID }) else {
            return
        }
        renameNotebookID = nb.id
        renameTitle = nb.title
        isRenameSheetPresented = true
    }
}
