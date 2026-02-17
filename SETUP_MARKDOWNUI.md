# Adding MarkdownUI Package to Xcode

## Steps to add the MarkdownUI Swift Package:

1. Open `PPLAITrainer.xcodeproj` in Xcode
2. Select the project in the navigator (top-level "PPLAITrainer")
3. Select the "PPLAITrainer" target
4. Go to the "General" tab
5. Scroll down to "Frameworks, Libraries, and Embedded Content"
6. Click the "+" button
7. Click "Add Package Dependency..."
8. In the search field, enter: `https://github.com/gonzalezreal/swift-markdown-ui`
9. Click "Add Package"
10. Select "MarkdownUI" from the list
11. Click "Add Package"

## Package Details:
- **URL**: https://github.com/gonzalezreal/swift-markdown-ui
- **Version**: 2.4.1 (or latest)
- **License**: MIT (free to use)

## What it provides:
- Full GitHub Flavored Markdown support
- Headers, lists, code blocks, tables, blockquotes
- Customizable styling
- Native SwiftUI integration

The code has already been updated to use MarkdownUI in:
- `AIConversationSheet.swift` - AI chat responses
- `SettingsManager.swift` - System prompt updated to encourage markdown
