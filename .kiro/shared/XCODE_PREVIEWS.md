# Xcode Previews Tool

Use this to capture and analyze SwiftUI preview screenshots.

## Usage

```bash
/Users/kemp.calalo/Documents/ios/XcodePreviews/scripts/preview <path-to-swift-file>
```

## Example

```bash
/Users/kemp.calalo/Documents/ios/XcodePreviews/scripts/preview PPLAITrainer/Views/Dashboard/DashboardView.swift
```

The script will:
1. Build the preview using the Xcode project
2. Capture a screenshot to `/tmp/preview_*.png`
3. Return the path to the screenshot

## Options

- `--output <path>` - Custom output path
- `--simulator <name>` - Simulator to use (default: iPhone 17 Pro)
- `--verbose` - Show detailed build output
- `--keep` - Keep temporary files

## After Capture

Read the screenshot file to analyze the UI visually.
