import SwiftUI
import WebKit

struct AIMarkdownMathView: View {
    let content: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var measuredHeight: CGFloat = 24

    private var normalizedContent: String {
        AIMathMarkdownNormalizer.normalize(content)
    }

    var body: some View {
        AIMarkdownMathWebView(
            markdown: normalizedContent,
            isDarkMode: colorScheme == .dark,
            measuredHeight: $measuredHeight
        )
        .frame(height: max(measuredHeight, 24))
    }
}

private struct AIMarkdownMathWebView: UIViewRepresentable {
    let markdown: String
    let isDarkMode: Bool
    @Binding var measuredHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: Coordinator.heightMessageName)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        webView.loadHTMLString(Self.htmlTemplate, baseURL: Self.localAssetsBaseURL())
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.render(markdown: markdown, isDarkMode: isDarkMode, in: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.heightMessageName)
    }

    private static func localAssetsBaseURL() -> URL {
        let bundles = [Bundle.main, Bundle(for: Coordinator.self)]
        let subdirectories = ["AIRenderer", nil]

        for bundle in bundles {
            for subdirectory in subdirectories {
                if let markedURL = bundle.url(forResource: "marked.min", withExtension: "js", subdirectory: subdirectory) {
                    return markedURL.deletingLastPathComponent()
                }
            }
        }

        // Xcode may flatten copied resource paths into the app bundle root in some build configurations.
        return Bundle.main.bundleURL
    }

    static let htmlTemplate = """
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root { color-scheme: light dark; }
    html, body {
      margin: 0;
      padding: 0;
      background: transparent;
      font: -apple-system-body;
      line-height: 1.45;
      overflow: hidden;
    }
    body {
      color: #1f2937;
      font-size: 16px;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }
    body.dark {
      color: #f3f4f6;
    }
    #content > :first-child { margin-top: 0; }
    #content > :last-child { margin-bottom: 0; }
    pre {
      white-space: pre-wrap;
      background: rgba(127, 127, 127, 0.12);
      border-radius: 8px;
      padding: 10px;
    }
    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    }
    blockquote {
      margin: 0.5em 0;
      padding-left: 0.75em;
      border-left: 3px solid rgba(127, 127, 127, 0.35);
    }
    mjx-container[jax="SVG"][display="true"] {
      overflow-x: auto;
      overflow-y: hidden;
      padding: 0.15em 0;
      margin: 0.65em 0;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 0.75em 0;
    }
    th, td {
      border: 1px solid rgba(127, 127, 127, 0.35);
      padding: 6px 8px;
      text-align: left;
    }
  </style>
  <script>
    window.MathJax = {
      tex: {
        inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
        displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']],
        processEscapes: true,
        processEnvironments: true
      },
      svg: {
        fontCache: 'none'
      },
      startup: {
        typeset: false
      }
    };
  </script>
  <script defer src="marked.min.js"></script>
  <script defer src="tex-svg.js"></script>
</head>
<body>
  <div id="content"></div>
  <script>
    const contentNode = document.getElementById('content');

    function decodeBase64Unicode(base64) {
      const binary = atob(base64);
      const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
      return new TextDecoder().decode(bytes);
    }

    function escapeHtml(raw) {
      return raw
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }

    function postHeight() {
      const height = Math.max(
        document.documentElement.scrollHeight,
        document.body.scrollHeight
      );
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.contentHeight) {
        window.webkit.messageHandlers.contentHeight.postMessage(height);
      }
    }

    function applyMarkdown(markdown) {
      if (!window.marked || typeof window.marked.parse !== 'function') {
        contentNode.innerHTML = '<pre>' + escapeHtml(markdown) + '</pre>';
        return;
      }

      const renderer = new marked.Renderer();
      renderer.html = function(token) {
        const raw = typeof token === 'string' ? token : (token && token.text) ? token.text : '';
        return '<pre>' + escapeHtml(raw) + '</pre>';
      };

      marked.use({ renderer: renderer });
      const html = marked.parse(markdown, {
        gfm: true,
        breaks: true,
        mangle: false,
        headerIds: false
      });
      contentNode.innerHTML = html;
    }

    async function applyMath() {
      if (!window.MathJax || typeof window.MathJax.typesetPromise !== 'function') {
        return;
      }

      if (window.MathJax.startup && window.MathJax.startup.promise) {
        try {
          await window.MathJax.startup.promise;
        } catch (_) {}
      }

      if (typeof window.MathJax.typesetClear === 'function') {
        window.MathJax.typesetClear([contentNode]);
      }

      await window.MathJax.typesetPromise([contentNode]);
    }

    async function renderMarkdownFromBase64(base64, isDarkMode) {
      document.body.classList.toggle('dark', !!isDarkMode);
      const markdown = decodeBase64Unicode(base64);
      applyMarkdown(markdown);
      try {
        await applyMath();
      } catch (_) {}
      postHeight();
      setTimeout(postHeight, 50);
      setTimeout(postHeight, 200);
    }

    window.renderMarkdownFromBase64 = renderMarkdownFromBase64;

    new ResizeObserver(() => postHeight()).observe(document.body);
    document.addEventListener('click', event => {
      const link = event.target.closest('a');
      if (link) {
        event.preventDefault();
      }
    });
  </script>
</body>
</html>
"""

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let heightMessageName = "contentHeight"

        var parent: AIMarkdownMathWebView

        private var hasLoadedTemplate = false
        private var pendingRender: (markdown: String, isDarkMode: Bool)?
        private var lastRenderedMarkdown: String?
        private var lastRenderedDarkMode: Bool?

        init(parent: AIMarkdownMathWebView) {
            self.parent = parent
        }

        func render(markdown: String, isDarkMode: Bool, in webView: WKWebView) {
            guard hasLoadedTemplate else {
                pendingRender = (markdown, isDarkMode)
                return
            }

            if lastRenderedMarkdown == markdown && lastRenderedDarkMode == isDarkMode {
                return
            }

            lastRenderedMarkdown = markdown
            lastRenderedDarkMode = isDarkMode

            guard let data = markdown.data(using: .utf8) else { return }
            let base64 = data.base64EncodedString()
            let js = "window.renderMarkdownFromBase64('\(base64)', \(isDarkMode ? "true" : "false"));"

            webView.evaluateJavaScript(js) { _, _ in }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasLoadedTemplate = true

            if let pendingRender {
                render(markdown: pendingRender.markdown, isDarkMode: pendingRender.isDarkMode, in: webView)
                self.pendingRender = nil
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.heightMessageName else { return }
            guard let number = message.body as? NSNumber else { return }

            let nextHeight = max(CGFloat(truncating: number), 24)
            guard nextHeight.isFinite else { return }

            DispatchQueue.main.async {
                if abs(self.parent.measuredHeight - nextHeight) > 1 {
                    self.parent.measuredHeight = nextHeight
                }
            }
        }
    }
}

private enum AIMathMarkdownNormalizer {
    static func normalize(_ input: String) -> String {
        var output = input.replacingOccurrences(of: "\r\n", with: "\n")

        output = replaceAsDisplayMath(
            in: output,
            pattern: "```(?:latex|tex|math)\\s*([\\s\\S]*?)```",
            bodyCaptureIndex: 1,
            options: [.caseInsensitive]
        )

        output = replaceAsDisplayMath(
            in: output,
            pattern: "\\\\begin\\{(equation\\*?|align\\*?|gather\\*?|multline\\*?)\\}([\\s\\S]*?)\\\\end\\{\\1\\}",
            bodyCaptureIndex: 2
        )

        output = replaceDelimitedMath(
            in: output,
            openDelimiter: "\\\\[",
            closeDelimiter: "\\\\]",
            wrapWithDisplayMath: true
        )

        output = replaceDelimitedMath(
            in: output,
            openDelimiter: "\\\\(",
            closeDelimiter: "\\\\)",
            wrapWithDisplayMath: false
        )

        output = repairUnbalancedBracesInDollarMath(in: output)

        return output
    }

    private static func repairUnbalancedBracesInDollarMath(in source: String) -> String {
        var output = source
        output = replaceDelimitedMathBody(in: output, delimiter: "$$")
        output = replaceDelimitedMathBody(in: output, delimiter: "$")
        return output
    }

    private static func replaceDelimitedMathBody(in source: String, delimiter: String) -> String {
        var output = source
        var searchStart = output.startIndex

        while searchStart < output.endIndex,
              let openRange = output.range(of: delimiter, range: searchStart..<output.endIndex) {
            let bodyStart = openRange.upperBound
            guard let closeRange = output.range(of: delimiter, range: bodyStart..<output.endIndex) else {
                break
            }

            let body = String(output[bodyStart..<closeRange.lowerBound])
            let repairedBody = repairedBraceBalance(in: body)

            if repairedBody != body {
                output.replaceSubrange(bodyStart..<closeRange.lowerBound, with: repairedBody)
                let repairedBodyLength = repairedBody.distance(from: repairedBody.startIndex, to: repairedBody.endIndex)
                let closeDelimiterStart = output.index(bodyStart, offsetBy: repairedBodyLength)
                searchStart = output.index(closeDelimiterStart, offsetBy: delimiter.count, limitedBy: output.endIndex) ?? output.endIndex
            } else {
                searchStart = closeRange.upperBound
            }
        }

        return output
    }

    private static func repairedBraceBalance(in body: String) -> String {
        var result = ""
        result.reserveCapacity(body.count)

        var openBraceCount = 0
        var trailingBackslashCount = 0

        for character in body {
            if character == "\\" {
                trailingBackslashCount += 1
                result.append(character)
                continue
            }

            let isEscaped = trailingBackslashCount % 2 == 1
            trailingBackslashCount = 0

            if isEscaped {
                result.append(character)
                continue
            }

            if character == "{" {
                openBraceCount += 1
                result.append(character)
            } else if character == "}" {
                if openBraceCount > 0 {
                    openBraceCount -= 1
                    result.append(character)
                }
            } else {
                result.append(character)
            }
        }

        if openBraceCount > 0 {
            result.append(String(repeating: "}", count: openBraceCount))
        }

        return result
    }

    private static func replaceDelimitedMath(
        in source: String,
        openDelimiter: String,
        closeDelimiter: String,
        wrapWithDisplayMath: Bool
    ) -> String {
        let pattern = "\(openDelimiter)([\\s\\S]*?)\(closeDelimiter)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return source
        }

        let sourceNSString = source as NSString
        let fullRange = NSRange(location: 0, length: sourceNSString.length)
        let matches = regex.matches(in: source, range: fullRange).reversed()
        var output = source

        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let body = sourceNSString.substring(with: match.range(at: 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let replaceRange = Range(match.range(at: 0), in: output) else { continue }

            let replacement: String
            if body.isEmpty {
                replacement = ""
            } else if wrapWithDisplayMath {
                replacement = "\n$$\n\(body)\n$$\n"
            } else {
                replacement = "$\(body)$"
            }
            output.replaceSubrange(replaceRange, with: replacement)
        }

        return output
    }

    private static func replaceAsDisplayMath(
        in source: String,
        pattern: String,
        bodyCaptureIndex: Int,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return source
        }

        let sourceNSString = source as NSString
        let fullRange = NSRange(location: 0, length: sourceNSString.length)
        let matches = regex.matches(in: source, range: fullRange).reversed()
        var output = source

        for match in matches {
            guard match.numberOfRanges > bodyCaptureIndex else { continue }
            let body = sourceNSString.substring(with: match.range(at: bodyCaptureIndex))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let replaceRange = Range(match.range(at: 0), in: output) else { continue }
            let replacement = body.isEmpty ? "" : "\n$$\n\(body)\n$$\n"
            output.replaceSubrange(replaceRange, with: replacement)
        }

        return output
    }
}
