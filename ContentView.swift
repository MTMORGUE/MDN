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

    // For the settings side menu
    @State private var showSettingsMenu = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Main notebook list + toolbar
            mainNotebookList

            // If settings menu is shown, overlay a dim background and the side menu
            if showSettingsMenu {
                // 1) Dim background covering the screen
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showSettingsMenu = false
                        }
                    }

                // 2) Slide-in side menu aligned with the top of the screen (thus flush w/ the nav bar)
                HStack(alignment: .top, spacing: 0) {
                    SettingsMenuView()
                        // Ensures the menu only grows as tall as its contents
                        .fixedSize(horizontal: false, vertical: true)
                        // Set an explicit width if desired
                        .frame(width: 250)
                        // Slide in from the left
                        .transition(.move(edge: .leading))

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $isRenameSheetPresented) {
            renameSheet
        }
    }

    // MARK: - Main Notebook List

    private var mainNotebookList: some View {
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
            // Apply our custom edit mode to the list
            .environment(\.editMode, $editMode)
            .toolbar {
                // Left side: Gear button (only if not in edit mode)
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .inactive {
                        Button {
                            withAnimation {
                                showSettingsMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }

                // Right side: Edit or "..." menu (depending on editMode)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode == .inactive {
                        // Show Edit button if not in edit mode
                        Button("Edit") {
                            editMode = .active
                        }
                    } else {
                        // In edit mode, show the "..." menu with Create, Delete, Rename
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
                        }
                    }
                }
            }
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

// MARK: - Settings Menu View

/// A minimal side menu that only grows to fit its content.
/// Customize as needed.
struct SettingsMenuView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .padding([.top, .horizontal])

            Divider()

            // Add your settings items here
            Text("Profile")
                .padding(.horizontal)
            Text("Preferences")
                .padding(.horizontal)
            Text("About")
                .padding(.horizontal)

            Spacer()
        }
        // No .ignoresSafeArea() here, so it won't fill full height.
        // We do want it flush with top, so no top padding.
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}
