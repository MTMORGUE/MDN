import SwiftUI
import WebKit

// MARK: - Highlighted Code View
struct HighlightedCodeView: UIViewRepresentable {
    let language: String
    let code: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(language: language, code: code)
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
    
    private func generateHTML(language: String, code: String) -> String {
        let escapedCode = code
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <link rel="stylesheet" href="highlight/styles/github-dark.css">
          <script src="highlight/highlight.min.js"></script>
          <script>
            document.addEventListener('DOMContentLoaded', (event) => {
              document.querySelectorAll('pre code').forEach((block) => {
                hljs.highlightElement(block);
              });
            });
          </script>
        </head>
        <body>
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif; padding: 10px; background: #f7f7f7; border-bottom: 1px solid #ddd;">
            <span style="font-size: 12px; font-weight: bold;">\(language.uppercased())</span>
            <button style="float: right; font-size: 12px; padding: 2px 6px; background-color: #007aff; color: white; border: none; border-radius: 4px; cursor: pointer;" onclick="navigator.clipboard.writeText(document.querySelector('pre code').innerText)">
              Copy
            </button>
          </div>
          <pre><code class="\(language)">\(escapedCode)</code></pre>
        </body>
        </html>
        """
    }
}

// MARK: - Highlight Themes (CSS)
struct HighlightThemes {
    static let supportedThemes = [
        "github-dark": "GitHub Dark Theme",
        "monokai": "Monokai",
        "dracula": "Dracula",
        "nord": "Nord"
    ]

    static func cssLink(for theme: String) -> String {
        return "highlight/styles/\(theme).css"
    }
}
