// CustomMarkdownView.swift
import SwiftUI
import MarkdownUI

struct CustomMarkdownView: View {
    let markdown: String

    var body: some View {
        Markdown(markdown)
            .padding()
    }
}
