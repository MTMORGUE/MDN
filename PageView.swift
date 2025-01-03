import SwiftUI

struct PageView: View {
    @EnvironmentObject var store: NotebooksStore

    let notebookID: UUID
    @State var page: Page

    // Toggles read-only vs. edit mode
    @State private var isEditing = false
    // 0 = rendered edit, 1 = raw markdown
    @State private var editModeSelection = 0

    // Local editing buffers
    @State private var blocks: [PageContentType] = []
    @State private var rawMarkdown = ""

    // For focusing code blocks
    @FocusState private var focusedBlockID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            if !isEditing {
                // -------------------
                // READ-ONLY MODE
                // -------------------
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(page.content.indices, id: \.self) { i in
                            viewBlock(page.content[i])
                        }
                    }
                    .padding()
                }
            } else {
                // -------------------
                // EDIT MODE
                // -------------------
                Picker("Edit Mode", selection: $editModeSelection) {
                    Text("Rendered Edit").tag(0)
                    Text("Raw Markdown").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if editModeSelection == 0 {
                    // RENDERED EDIT
                    HStack {
                        Spacer()
                        Menu {
                            Button("H1") { blocks.append(.text("# Heading 1")) }
                            Button("H2") { blocks.append(.text("## Heading 2")) }
                            Button("Bulleted List") { blocks.append(.text("* Red\n* Green\n* Blue")) }
                            Button("Numbered List") { blocks.append(.text("1. First\n2. Second\n3. Third")) }
                            Button("Code Block") { blocks.append(.code("swift", "print(\"Hello, world!\")")) }
                            Button("Emphasis") { blocks.append(.text("*emphasized text*")) }
                            Button("Link") { blocks.append(.text("[Link text](http://example.com)")) }
                            Button("Image") { blocks.append(.text("![Alt text](path/to/img.jpg \"Optional title\")")) }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Insert")
                                Image(systemName: "arrowtriangle.down.fill")
                            }
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGroupedBackground))

                    List {
                        ForEach(blocks.indices, id: \.self) { index in
                            editableBlockView(block: $blocks[index])
                        }
                        .onMove(perform: moveBlocks)
                    }
                    .listStyle(.inset)
                    .environment(\.editMode, .constant(.active))

                } else {
                    // RAW MARKDOWN EDIT
                    TextEditor(text: $rawMarkdown)
                        .border(Color.gray, width: 1)
                        .padding()
                }
            }
        }
        .navigationTitle(page.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    // -------------
                    // EDIT TOOLBAR
                    // -------------
                    Menu("...") {
                        Button("Create") {
                            blocks.append(.text("New Block"))
                        }
                        Button("Delete") {
                            if !blocks.isEmpty {
                                blocks.removeLast()
                            }
                        }
                        Button("Rename") {
                            // Placeholder for renaming the page, if desired
                        }
                        // SAVE: finalize changes, remain on the same page in read-only mode
                        Button("Save") {
                            finalizeEdits()
                            isEditing = false
                            store.updatePage(in: notebookID, page: page)
                        }
                    }
                } else {
                    // -------------
                    // READ-ONLY TOOLBAR
                    // -------------
                    Button("Edit") {
                        // Load current content into local edit buffers
                        blocks = page.content
                        rawMarkdown = blocksToMarkdown(blocks)
                        isEditing = true
                    }
                }
            }
        }
        // Removed any .onDisappear code that automatically saves & might navigate
        .onChange(of: editModeSelection) { newVal in
            guard isEditing else { return }
            if newVal == 1 {
                // If switching to raw markdown
                rawMarkdown = blocksToMarkdown(blocks)
            } else {
                // If switching back to rendered edit
                blocks = parseMarkdown(rawMarkdown)
            }
        }
    }

    // MARK: - Read-Only Rendering
    @ViewBuilder
    func viewBlock(_ block: PageContentType) -> some View {
        switch block {
        case .text(let content):
            CustomMarkdownView(markdown: content)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

        case .code(let lang, let code):
            HighlightedCodeView(language: lang, code: code)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

        case .table(let rows):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(rows, id: \.self) { row in
                    Text(row.joined(separator: " | "))
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

        case .checkbox(let checked, let label):
            let symbol = checked ? "☑︎" : "☐"
            HStack {
                Text(symbol)
                Text(label)
            }
            .padding()

        case .file(let url):
            HStack {
                Text(url.lastPathComponent)
                Spacer()
                Button("Open") {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }

    // MARK: - Editable Rendering
    @ViewBuilder
    func editableBlockView(block: Binding<PageContentType>) -> some View {
        switch block.wrappedValue {
        case .text(let txt):
            VStack(alignment: .leading) {
                Text("Text Block").font(.headline)
                TextField("Enter text", text: Binding(
                    get: { txt },
                    set: { block.wrappedValue = .text($0) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.vertical, 4)

        case .code(var lang, let code):
            VStack(alignment: .leading) {
                Text("Code Block").font(.headline)
                Picker("Language", selection: Binding(
                    get: { lang },
                    set: { newLang in
                        lang = newLang
                        block.wrappedValue = .code(newLang, code)
                    }
                )) {
                    ForEach(supportedLanguages, id: \.self) { language in
                        Text(language.capitalized).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                TextEditor(text: Binding(
                    get: { code },
                    set: { newCode in
                        block.wrappedValue = .code(lang, newCode)
                    }
                ))
                .frame(height: 200)
                .border(Color.gray)
                .focused($focusedBlockID, equals: block.wrappedValue.id)
                .onTapGesture {
                    focusedBlockID = block.wrappedValue.id
                }

                HighlightedCodeView(language: lang, code: code)
                    .frame(height: 200)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

        case .table(let rows):
            VStack(alignment: .leading) {
                Text("Table Editor").font(.headline)
                ForEach(rows.indices, id: \.self) { r in
                    HStack {
                        ForEach(rows[r].indices, id: \.self) { c in
                            TextField("Cell", text: Binding(
                                get: { rows[r][c] },
                                set: { newVal in
                                    var rowCopy = rows[r]
                                    rowCopy[c] = newVal
                                    var updated = rows
                                    updated[r] = rowCopy
                                    block.wrappedValue = .table(updated)
                                }
                            ))
                            .border(Color.gray)
                            .frame(minWidth: 40)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

        case .checkbox(let checked, let label):
            HStack {
                Button {
                    block.wrappedValue = .checkbox(!checked, label)
                } label: {
                    Image(systemName: checked ? "checkmark.square.fill" : "square")
                        .imageScale(.large)
                }
                TextField("Label", text: Binding(
                    get: { label },
                    set: { block.wrappedValue = .checkbox(checked, $0) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

        case .file(let url):
            HStack {
                Text(url.lastPathComponent)
                Spacer()
                Button("Open") {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }

    // MARK: - Reordering
    private func moveBlocks(from offsets: IndexSet, to newOffset: Int) {
        blocks.move(fromOffsets: offsets, toOffset: newOffset)
    }

    // MARK: - Finalizing Edits
    private func finalizeEdits() {
        // If in raw markdown mode, parse the text first
        if editModeSelection == 1 {
            blocks = parseMarkdown(rawMarkdown)
        }
        // Update the page with final blocks
        page.content = blocks
    }

    // MARK: - Conversion: Blocks <-> Markdown
    func blocksToMarkdown(_ blocks: [PageContentType]) -> String {
        var lines: [String] = []
        for block in blocks {
            switch block {
            case .text(let txt):
                lines.append(txt)
                lines.append("")
            case .code(let lang, let code):
                lines.append("```\(lang)")
                lines.append(code)
                lines.append("```")
                lines.append("")
            case .table(let rows):
                for row in rows {
                    let line = "| " + row.joined(separator: " | ") + " |"
                    lines.append(line)
                }
                lines.append("")
            case .checkbox(let checked, let label):
                let mark = checked ? "x" : " "
                lines.append("- [\(mark)] \(label)")
                lines.append("")
            case .file(let url):
                lines.append("[\(url.lastPathComponent)](\(url.absoluteString))")
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    func parseMarkdown(_ raw: String) -> [PageContentType] {
        var result: [PageContentType] = []
        let lines = raw.components(separatedBy: .newlines)
        var i = 0

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3))
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                let codeText = codeLines.joined(separator: "\n")
                result.append(.code(lang, codeText))
            } else if line.trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                // Table
                var tableRows: [[String]] = []
                while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    let row = lines[i]
                        .split(separator: "|")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    tableRows.append(Array(row))
                    i += 1
                }
                result.append(.table(tableRows))
                continue
            } else if line.hasPrefix("- [") {
                // Checkbox
                let isChecked = line.contains("[x]")
                if let bracket = line.range(of: "]") {
                    let after = line[bracket.upperBound...].trimmingCharacters(in: .whitespaces)
                    result.append(.checkbox(isChecked, String(after)))
                }
            } else if line.hasPrefix("[") && line.contains("](") {
                // File link
                if let closeB = line.firstIndex(of: "]"),
                   let openP = line.firstIndex(of: "("),
                   let closeP = line.lastIndex(of: ")"),
                   closeB < openP && openP < closeP {
                    let label = String(line[line.index(after: line.startIndex)..<closeB])
                    let urlString = String(line[line.index(after: openP)..<closeP])
                    if let realURL = URL(string: urlString) {
                        result.append(.file(realURL))
                    } else {
                        result.append(.text(label))
                    }
                } else {
                    result.append(.text(line))
                }
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // skip
            } else {
                result.append(.text(line))
            }
            i += 1
        }
        return result
    }
}

// Example language list:
let supportedLanguages: [String] = [
    "plaintext", "bash", "c", "c++", "c#", "css", "dart", "diff", "go", "html",
    "java", "javascript", "json", "kotlin", "markdown", "objective-c", "perl",
    "php", "python", "ruby", "rust", "shell", "sql", "swift", "typescript", "xml", "yaml"
]
