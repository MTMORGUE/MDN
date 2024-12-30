import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NotebooksStore

    var body: some View {
        NavigationView {
            List {
                ForEach(store.notebooks.indices, id: \.self) { i in
                    NavigationLink(
                        destination: NotebookView(notebook: store.notebooks[i])
                    ) {
                        Text(store.notebooks[i].title)
                    }
                }
                .onDelete(perform: deleteNotebooks)
            }
            .navigationTitle("Notebooks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Create a new blank notebook
                        let newNb = Notebook(title: "New Notebook", pages: [])
                        store.notebooks.append(newNb)
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    func deleteNotebooks(at offsets: IndexSet) {
        store.notebooks.remove(atOffsets: offsets)
    }
}
