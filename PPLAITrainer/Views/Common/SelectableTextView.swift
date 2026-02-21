import SwiftUI
import UIKit

struct SelectableTextView: UIViewRepresentable {
    let text: String
    var font: UIFont
    var textColor: UIColor = .label
    var onSelectionChange: ((String?) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionChange: onSelectionChange)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.textColor = textColor
        context.coordinator.onSelectionChange = onSelectionChange
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: fitting.height)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var onSelectionChange: ((String?) -> Void)?

        init(onSelectionChange: ((String?) -> Void)?) {
            self.onSelectionChange = onSelectionChange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard let selectedRange = textView.selectedTextRange else {
                onSelectionChange?(nil)
                return
            }

            let raw = textView.text(in: selectedRange) ?? ""
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            onSelectionChange?(trimmed.isEmpty ? nil : trimmed)
        }
    }
}
