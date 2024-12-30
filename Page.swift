//
// Page.swift
//
import Foundation

struct Page: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: [PageContentType]

    init(id: UUID = UUID(), title: String, content: [PageContentType]) {
        self.id = id
        self.title = title
        self.content = content
    }
}
