//
// ImportMarkdown.swift
//
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Markdown Feature
struct ImportMarkdownView: UIViewControllerRepresentable {
    var completion: (String?, String?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use fallback UTType for Markdown to avoid .markdown errors
        let markdownType = UTType("net.daringfireball.markdown") ?? .plainText
        // We allow .plainText + fallback Markdown UTType
        let supportedTypes: [UTType] = [.plainText, markdownType]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var completion: (String?, String?) -> Void

        init(completion: @escaping (String?, String?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                completion(nil, nil)
                return
            }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                // Extract the first heading as the title, or use the file name
                let title = extractTitle(from: content) ?? url.deletingPathExtension().lastPathComponent
                completion(content, title)
            } catch {
                print("Failed to read file: \(error)")
                completion(nil, nil)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil, nil)
        }

        private func extractTitle(from content: String) -> String? {
            // Extract the first line that starts with '#'
            for line in content.components(separatedBy: .newlines) {
                if line.starts(with: "#") {
                    return line.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
                }
            }
            return nil
        }
    }
}

/// Presents a document picker for Markdown files
/// and returns (content, title) via the completion.
func importMarkdownFile(completion: @escaping (String?, String?) -> Void) {
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
        completion(nil, nil)
        return
    }

    let importView = ImportMarkdownView(completion: completion)
    let hostingController = UIHostingController(rootView: importView)
    rootViewController.present(hostingController, animated: true, completion: nil)
}

// MARK: - Pick Any File Feature
struct ImportFileView: UIViewControllerRepresentable {
    var completion: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // For general file selection, use the .data UTType
        let supportedTypes: [UTType] = [.data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var completion: (URL?) -> Void

        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
}

/// Presents a document picker for any file type,
/// returning the selected file URL via the completion handler.
func pickFile(completion: @escaping (URL?) -> Void) {
    guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
        completion(nil)
        return
    }

    let importView = ImportFileView(completion: completion)
    let hostingController = UIHostingController(rootView: importView)
    rootViewController.present(hostingController, animated: true, completion: nil)
}
