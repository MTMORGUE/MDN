//
// Notebook.swift
//
import Foundation

struct Notebook: Identifiable, Codable {
    let id: UUID
    var title: String
    var pages: [Page]

    init(id: UUID = UUID(), title: String, pages: [Page]) {
        self.id = id
        self.title = title
        self.pages = pages
    }
}
