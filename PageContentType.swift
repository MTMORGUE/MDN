//
// PageContentType.swift
//
import Foundation

/// An enum representing different content blocks in a page.
///
/// Because it has associated values, we need a custom encode/decode approach.
/// Now also conforms to Hashable so we can do:
///   ForEach(blocks, id: \.self) { ... }
///   .onMove { ... }
enum PageContentType: Identifiable, Hashable, Codable {
    var id: UUID { UUID() }

    case text(String)
    case code(String, String)    // (language, code)
    case table([[String]])
    case checkbox(Bool, String)  // (isChecked, label)
    case file(URL)

    // MARK: - Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case lang
        case code
        case rows
        case checked
        case label
        case url
    }

    private enum CaseType: String, Codable {
        case text
        case code
        case table
        case checkbox
        case file
    }

    // MARK: - Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decode(CaseType.self, forKey: .type)

        switch rawType {
        case .text:
            let txt = try container.decode(String.self, forKey: .text)
            self = .text(txt)

        case .code:
            let lang = try container.decode(String.self, forKey: .lang)
            let source = try container.decode(String.self, forKey: .code)
            self = .code(lang, source)

        case .table:
            let rows = try container.decode([[String]].self, forKey: .rows)
            self = .table(rows)

        case .checkbox:
            let isChecked = try container.decode(Bool.self, forKey: .checked)
            let lbl = try container.decode(String.self, forKey: .label)
            self = .checkbox(isChecked, lbl)

        case .file:
            let urlString = try container.decode(String.self, forKey: .url)
            guard let parsed = URL(string: urlString) else {
                // fallback to text if invalid URL
                self = .text("Invalid URL: \(urlString)")
                return
            }
            self = .file(parsed)
        }
    }

    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let txt):
            try container.encode(CaseType.text, forKey: .type)
            try container.encode(txt, forKey: .text)

        case .code(let lang, let source):
            try container.encode(CaseType.code, forKey: .type)
            try container.encode(lang, forKey: .lang)
            try container.encode(source, forKey: .code)

        case .table(let rows):
            try container.encode(CaseType.table, forKey: .type)
            try container.encode(rows, forKey: .rows)

        case .checkbox(let isChecked, let lbl):
            try container.encode(CaseType.checkbox, forKey: .type)
            try container.encode(isChecked, forKey: .checked)
            try container.encode(lbl, forKey: .label)

        case .file(let url):
            try container.encode(CaseType.file, forKey: .type)
            try container.encode(url.absoluteString, forKey: .url)
        }
    }

    // MARK: - Hashable Conformance
    // Swift can often auto-synthesize Hashable for associated values
    // if each associated value is also Hashable:
    //   - String is Hashable
    //   - Bool is Hashable
    //   - URL is Hashable (Swift 5.5+)
    //   - [[String]] is also Hashable if each String is Hashable
    //
    // If you see an error about "Cannot automatically synthesize 'Hashable'..."
    // you may need to implement a custom `func hash(into hasher: inout Hasher) { ... }`
    // and `static func ==(...) -> Bool`.
    //
    // For many setups, this empty extension is enough:
    // (But we've already declared "Hashable" above, so no code needed here.)
}
