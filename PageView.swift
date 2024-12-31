import SwiftUI

struct PageView: View {
    @EnvironmentObject var store: NotebooksStore

    let notebookID: UUID
    @State var page: Page

    @State private var isEditing = false
    @State private var editModeSelection = 0
    @State private var blocks: [PageContentType] = []
    @State private var rawMarkdown = ""

    @FocusState private var focusedBlockID: UUID? // Focus tracking for code blocks

    var body: some View {
        VStack(spacing: 0) {
            if !isEditing {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(page.content.indices, id: \.self) { i in
                            viewBlock(page.content[i])
                        }
                    }
                    .padding()
                }
            } else {
                Picker("Edit Mode", selection: $editModeSelection) {
                    Text("Rendered Edit").tag(0)
                    Text("Raw Markdown").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)

                if editModeSelection == 0 {
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
                    Button("Done") {
                        finalizeEdits()
                        isEditing = false
                        store.updatePage(in: notebookID, page: page)
                    }
                } else {
                    Button("Edit") {
                        blocks = page.content
                        rawMarkdown = blocksToMarkdown(blocks)
                        isEditing = true
                    }
                }
            }
        }
        .onDisappear {
            guard isEditing else { return }
            finalizeEdits()
            isEditing = false
            store.updatePage(in: notebookID, page: page)
        }
        .onChange(of: editModeSelection) { newVal in
            guard isEditing else { return }
            if newVal == 1 {
                rawMarkdown = blocksToMarkdown(blocks)
            } else {
                blocks = parseMarkdown(rawMarkdown)
            }
        }
    }

    // MARK: - Viewing Blocks (Read-Only)
    @ViewBuilder
    func viewBlock(_ block: PageContentType) -> some View {
        switch block {
        case .text(let content):
            Text(content)
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

    // MARK: - Editable Blocks (Rendered Edit Mode)
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
                .focused($focusedBlockID, equals: block.wrappedValue.id) // Keeps focus on this block
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

    // MARK: - Finalizing/Converting
    private func finalizeEdits() {
        if editModeSelection == 1 {
            blocks = parseMarkdown(rawMarkdown)
        }
        page.content = blocks
    }

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
                let isChecked = line.contains("[x]")
                if let bracket = line.range(of: "]") {
                    let after = line[bracket.upperBound...].trimmingCharacters(in: .whitespaces)
                    result.append(.checkbox(isChecked, after))
                }
            } else if line.hasPrefix("[") && line.contains("](") {
                if let closeB = line.firstIndex(of: "]"),
                   let openP = line.firstIndex(of: "("),
                   let closeP = line.lastIndex(of: ")"),
                   closeB < openP && openP < closeP
                {
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
            } else {
                result.append(.text(line))
            }
            i += 1
        }
        return result
    }
}

// MARK: - Supported Languages
let supportedLanguages: [String] = [
    "plaintext", "bash", "c", "c++", "c#", "css", "dart", "diff", "go", "html",
    "java", "javascript", "json", "kotlin", "markdown", "objective-c", "perl",
    "php", "python", "ruby", "rust", "shell", "sql", "swift", "typescript", "xml", "yaml"
]
