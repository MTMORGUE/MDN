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
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/styles/github-dark.min.css">
          <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min.js"></script>
          <script>
            document.addEventListener('DOMContentLoaded', () => {
              hljs.highlightAll();
            });

            function copyToClipboard(code) {
              navigator.clipboard.writeText(code).then(
                () => alert("Copied to clipboard!"),
                () => alert("Failed to copy!")
              );
            }
          </script>
          <style>
            body {
              margin: 0;
              font-family: 'SF Mono', 'Courier New', monospace;
              background-color: #1e1e1e;
              color: white;
            }
            .code-container {
              border: 1px solid #333;
              border-radius: 6px;
              overflow: hidden;
            }
            .code-header {
              display: flex;
              justify-content: space-between;
              align-items: center;
              background: #2d2d2d;
              padding: 8px 12px;
              color: #ddd;
              font-size: 12px;
              font-weight: bold;
              border-bottom: 1px solid #333;
            }
            .code-header button {
              background: none;
              border: none;
              color: #ddd;
              cursor: pointer;
              font-size: 12px;
              padding: 4px 8px;
              border-radius: 4px;
              transition: background 0.2s;
            }
            .code-header button:hover {
              background: #444;
            }
            pre {
              margin: 0;
              padding: 12px;
              background: #1e1e1e;
            }
          </style>
        </head>
        <body>
          <div class="code-container">
            <div class="code-header">
              <span>\(language.uppercased())</span>
              <button onclick="copyToClipboard(`\(escapedCode.replacingOccurrences(of: "`", with: "\\`"))`)">Copy</button>
            </div>
            <pre><code class="\(language)">\(escapedCode)</code></pre>
          </div>
        </body>
        </html>
        """
    }
}
