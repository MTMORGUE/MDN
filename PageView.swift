import SwiftUI
import MarkdownUI
import Splash

/// Suppose you have:
/// class NotebooksStore: ObservableObject {
///   @Published var notebooks: [Notebook]
///   func updatePage(in notebookID: UUID, page: Page) { ... }
/// }

struct PageView: View {
    @EnvironmentObject var store: NotebooksStore

    let notebookID: UUID
    @State var page: Page

    // Are we editing or just viewing?
    @State private var isEditing = false

    // 0 => Rendered Edit, 1 => Raw Markdown
    @State private var editModeSelection = 0

    // Local blocks array for Rendered editing
    @State private var blocks: [PageContentType] = []

    // Raw markdown
    @State private var rawMarkdown = ""

    var body: some View {
        VStack(spacing: 0) {
            if !isEditing {
                // ---------- VIEW MODE ----------
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(page.content.indices, id: \.self) { i in
                            viewBlock(page.content[i])
                        }
                    }
                    .padding()
                }
            } else {
                // ---------- EDIT MODE ----------
                Picker("Edit Mode", selection: $editModeSelection) {
                    Text("Rendered Edit").tag(0)
                    Text("Raw Markdown").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)

                if editModeSelection == 0 {
                    // ---------- RENDERED EDIT + DRAG + INSERT ----------
                    HStack {
                        Spacer()
                        Menu {
                            Button("H1") {
                                blocks.append(.text("# Heading 1"))
                            }
                            Button("H2") {
                                blocks.append(.text("## Heading 2"))
                            }
                            Button("Bulleted List") {
                                blocks.append(.text("* Red\n* Green\n* Blue"))
                            }
                            Button("Numbered List") {
                                blocks.append(.text("1. First\n2. Second\n3. Third"))
                            }
                            Button("Code Block") {
                                blocks.append(.code("swift", "print(\"Hello, world!\")"))
                            }
                            Button("Emphasis") {
                                blocks.append(.text("*emphasized text*"))
                            }
                            Button("Link") {
                                blocks.append(.text("[Link text](http://example.com)"))
                            }
                            Button("Image") {
                                blocks.append(.text("![Alt text](path/to/img.jpg \"Optional title\")"))
                            }
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
                        ForEach(blocks, id: \.self) { block in
                            editableBlockView(block)
                        }
                        .onMove(perform: moveBlocks)
                    }
                    .listStyle(.inset)
                    .environment(\.editMode, .constant(.active))

                } else {
                    // ---------- RAW MARKDOWN EDIT ----------
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
                // Rendered => Raw
                rawMarkdown = blocksToMarkdown(blocks)
            } else {
                // Raw => Rendered
                blocks = parseMarkdown(rawMarkdown)
            }
        }
    }
}

// MARK: - Viewing Blocks (Read-Only)
extension PageView {
    @ViewBuilder
    func viewBlock(_ block: PageContentType) -> some View {
        switch block {
        case .text(let content):
            Markdown(content)
                .markdownTheme(.gitHub)

        case .code(let lang, let code):
            // GPT-like snippet with syntax highlighting if language == "swift"
            SplashCodeSnippetView(language: lang, code: code)

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
}

// MARK: - Editable Blocks (Rendered Edit Mode)
extension PageView {
    @ViewBuilder
    func editableBlockView(_ block: PageContentType) -> some View {
        switch block {
        case .text(let txt):
            VStack(alignment: .leading) {
                Text("Text Block").font(.headline)
                TextField("Enter text", text: Binding(
                    get: { txt },
                    set: { newVal in replaceBlock(old: block, new: .text(newVal)) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.vertical, 4)

        case .code(let lang, let code):
            VStack(alignment: .leading) {
                Text("Code Block").font(.headline)
                TextField("Language", text: Binding(
                    get: { lang },
                    set: { newVal in replaceBlock(old: block, new: .code(newVal, code)) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())

                TextEditor(text: Binding(
                    get: { code },
                    set: { newVal in replaceBlock(old: block, new: .code(lang, newVal)) }
                ))
                .frame(height: 100)
                .border(Color.gray)
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
                                    replaceBlock(old: block, new: .table(updated))
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
                    replaceBlock(old: block, new: .checkbox(!checked, label))
                } label: {
                    Image(systemName: checked ? "checkmark.square.fill" : "square")
                        .imageScale(.large)
                }
                TextField("Label", text: Binding(
                    get: { label },
                    set: { newVal in replaceBlock(old: block, new: .checkbox(checked, newVal)) }
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

    private func replaceBlock(old: PageContentType, new: PageContentType) {
        guard let idx = blocks.firstIndex(of: old) else { return }
        blocks[idx] = new
    }
}

// MARK: - Reordering
extension PageView {
    private func moveBlocks(from offsets: IndexSet, to newOffset: Int) {
        blocks.move(fromOffsets: offsets, toOffset: newOffset)
    }
}

// MARK: - Finalizing/Converting
extension PageView {
    private func finalizeEdits() {
        if editModeSelection == 1 {
            // Raw => parse
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
            }
            else if line.trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                // gather table lines
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
            }
            else if line.hasPrefix("- [") {
                let isChecked = line.contains("[x]")
                if let bracket = line.range(of: "]") {
                    let after = line[bracket.upperBound...].trimmingCharacters(in: .whitespaces)
                    result.append(.checkbox(isChecked, after))
                }
            }
            else if line.hasPrefix("[") && line.contains("](") {
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
            }
            else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // skip blank lines
            }
            else {
                // fallback => text
                result.append(.text(line))
            }
            i += 1
        }
        return result
    }
}

// MARK: - Splash Syntax Code Snippet
/// Replaces the simple snippet with a syntax-highlighted snippet if language == "swift"
struct SplashCodeSnippetView: View {
    let language: String
    let code: String

    var body: some View {
        VStack(spacing: 0) {
            // GPT-like top bar
            HStack {
                Text(language.uppercased())
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy").font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 28)
            .background(Color.gray.opacity(0.9))

            // Scrollable code area
            ScrollView(.horizontal, showsIndicators: true) {
                // If it's Swift, use Splash to highlight. Otherwise, show plain text.
                if language.lowercased() == "swift" {
                    SplashSyntaxText(code: code)
                        .padding()
                } else {
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}

// MARK: - SplashSyntaxText
/// A SwiftUI wrapper that uses Splash to highlight Swift code.
struct SplashSyntaxText: UIViewRepresentable {
    let code: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Construct a valid Theme using Splash's Font type
        let theme = Theme(
            font: Font(size: 14), // Splash's Font initializer
            plainTextColor: .label,
            tokenColors: [
                .keyword: .systemBlue,
                .string: .systemRed,
                .type: .systemGreen,
                .comment: .systemGray
            ]
        )

        let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme))
        
        // Correct usage of the `highlight` method
        let highlighted = highlighter.highlight(code)
        uiView.attributedText = highlighted
    }
}
