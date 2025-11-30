import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    @State private var contentHeight: CGFloat = 100
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        
        // Disable scroll interaction in WebView to allow parent ScrollView to handle it
        if let scrollView = webView.enclosingScrollView {
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            scrollView.verticalScrollElasticity = .none
            scrollView.horizontalScrollElasticity = .none
        }
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
        
        // Get content height after loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, error in
                if let height = result as? CGFloat {
                    context.coordinator.contentHeight = height
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var contentHeight: CGFloat = 100
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { result, error in
                if let height = result as? CGFloat {
                    self.contentHeight = max(height, 100)
                }
            }
        }
    }
    
    private func generateHTML(from markdown: String) -> String {
        // Escape the markdown for JavaScript
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/vs2015.min.css">
            <script src="https://cdnjs.cloudflare.com/ajax/libs/marked/11.1.1/marked.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    color: #1a1a1a;
                    background: transparent;
                    padding: 16px;
                    overflow: hidden;
                }
                
                html {
                    overflow: hidden;
                    pointer-events: none;
                }
                
                /* Re-enable pointer events for interactive elements */
                a, button, .copy-button {
                    pointer-events: auto;
                }
                
                p {
                    margin-bottom: 12px;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 20px;
                    margin-bottom: 12px;
                    font-weight: 600;
                    line-height: 1.3;
                }
                
                h1 { font-size: 28px; }
                h2 { font-size: 24px; }
                h3 { font-size: 20px; }
                
                code {
                    background: rgba(0, 0, 0, 0.05);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Monaco, Menlo, Consolas, monospace;
                    font-size: 13px;
                    color: #d73a49;
                }
                
                pre {
                    margin: 16px 0;
                    border-radius: 8px;
                    overflow: hidden;
                    background: #1e1e1e !important;
                }
                
                pre code {
                    display: block;
                    padding: 16px;
                    overflow-x: visible;
                    overflow-y: visible;
                    background: transparent;
                    font-size: 13px;
                    line-height: 1.5;
                    color: #abb2bf;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                }
                
                .code-block-wrapper {
                    position: relative;
                    margin: 16px 0;
                }
                
                .code-header {
                    background: #2d2d2d;
                    padding: 8px 12px;
                    border-top-left-radius: 8px;
                    border-top-right-radius: 8px;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid #404040;
                }
                
                .code-language {
                    font-size: 11px;
                    font-weight: 600;
                    text-transform: uppercase;
                    color: #888;
                    letter-spacing: 0.5px;
                }
                
                .copy-button {
                    background: rgba(255, 255, 255, 0.1);
                    border: none;
                    color: #888;
                    padding: 4px 10px;
                    border-radius: 4px;
                    font-size: 11px;
                    cursor: pointer;
                    transition: all 0.2s;
                }
                
                .copy-button:hover {
                    background: rgba(255, 255, 255, 0.15);
                    color: #fff;
                }
                
                .copy-button.copied {
                    color: #4ade80;
                }
                
                ul, ol {
                    margin-left: 24px;
                    margin-bottom: 12px;
                }
                
                li {
                    margin-bottom: 6px;
                }
                
                strong {
                    font-weight: 600;
                }
                
                em {
                    font-style: italic;
                }
                
                blockquote {
                    border-left: 3px solid #404040;
                    padding-left: 16px;
                    margin: 12px 0;
                    color: #a1a1aa;
                }
                
                a {
                    color: #60a5fa;
                    text-decoration: none;
                }
                
                a:hover {
                    text-decoration: underline;
                }
                
                /* Enhanced VS Code Dark+ theme colors - More vibrant! */
                .hljs {
                    background: #1e1e1e !important;
                    color: #d4d4d4 !important;
                }
                
                /* Keywords - Blue */
                .hljs-keyword,
                .hljs-selector-tag,
                .hljs-literal,
                .hljs-section,
                .hljs-link { 
                    color: #569cd6 !important; 
                    font-weight: bold;
                }
                
                /* Strings - Orange */
                .hljs-string,
                .hljs-meta-string { 
                    color: #ce9178 !important; 
                }
                
                /* Numbers - Light Green */
                .hljs-number,
                .hljs-regexp,
                .hljs-literal { 
                    color: #b5cea8 !important; 
                }
                
                /* Comments - Green */
                .hljs-comment,
                .hljs-quote { 
                    color: #6a9955 !important; 
                    font-style: italic; 
                }
                
                /* Functions - Yellow */
                .hljs-function,
                .hljs-title,
                .hljs-title.function,
                .hljs-title.class { 
                    color: #dcdcaa !important; 
                    font-weight: bold;
                }
                
                /* Variables & Properties - Light Blue */
                .hljs-variable,
                .hljs-params,
                .hljs-attr,
                .hljs-property,
                .hljs-attribute { 
                    color: #9cdcfe !important; 
                }
                
                /* Built-ins & Types - Cyan */
                .hljs-built_in,
                .hljs-type,
                .hljs-class,
                .hljs-name { 
                    color: #4ec9b0 !important; 
                }
                
                /* Operators */
                .hljs-operator { 
                    color: #d4d4d4 !important; 
                }
                
                /* Meta & Annotations - Gray */
                .hljs-meta,
                .hljs-meta-keyword { 
                    color: #808080 !important; 
                }
                
                /* Symbols - Pink */
                .hljs-symbol,
                .hljs-bullet,
                .hljs-code { 
                    color: #c586c0 !important; 
                }
                
                /* Additions - Green */
                .hljs-addition { 
                    color: #b5cea8 !important; 
                }
                
                /* Deletions - Red */
                .hljs-deletion { 
                    color: #d16969 !important; 
                }
            </style>
        </head>
        <body>
            <div id="content"></div>
            <script>
                // Configure marked
                marked.setOptions({
                    highlight: function(code, lang) {
                        if (lang && hljs.getLanguage(lang)) {
                            try {
                                return hljs.highlight(code, { language: lang }).value;
                            } catch (err) {}
                        }
                        return hljs.highlightAuto(code).value;
                    },
                    breaks: true,
                    gfm: true
                });
                
                // Custom renderer to add copy buttons
                const renderer = new marked.Renderer();
                const originalCode = renderer.code.bind(renderer);
                
                renderer.code = function(code, language) {
                    const lang = language || 'plaintext';
                    const highlighted = originalCode(code, language);
                    const escapedCode = code.replace(/'/g, "\\\\'");
                    
                    return '<div class="code-block-wrapper">' +
                        '<div class="code-header">' +
                        '<span class="code-language">' + lang + '</span>' +
                        '<button class="copy-button" onclick="copyCode(this, \\'' + escapedCode + '\\')">' +
                        'Copy' +
                        '</button>' +
                        '</div>' +
                        highlighted +
                        '</div>';
                };
                
                marked.use({ renderer });
                
                // Copy function
                function copyCode(button, code) {
                    navigator.clipboard.writeText(code).then(() => {
                        button.textContent = 'Copied!';
                        button.classList.add('copied');
                        setTimeout(() => {
                            button.textContent = 'Copy';
                            button.classList.remove('copied');
                        }, 2000);
                    });
                }
                
                // Render markdown
                const markdown = "\(escapedMarkdown)";
                document.getElementById('content').innerHTML = marked.parse(markdown);
            </script>
        </body>
        </html>
        """
    }
}
