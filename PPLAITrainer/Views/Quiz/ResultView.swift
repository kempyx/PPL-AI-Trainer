import SwiftUI
import UIKit

struct ResultView: View {
    @State var viewModel: QuizViewModel
    @Environment(\.dependencies) private var dependencies
    let question: PresentedQuestion
    @Binding var selectedExplainText: String?
    @State private var isBookmarked = false
    @State private var showNoteEditor = false
    @State private var note: Note?
    @State private var showReportSheet = false
    @State private var visualPromptText = ""
    @State private var showVisualPromptSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        showReportSheet = true
                    } label: {
                        Image(systemName: "flag")
                    }
                    .accessibilityLabel("Report question")
                    Button {
                        showNoteEditor = true
                    } label: {
                        Image(systemName: note != nil ? "note.text" : "note.text.badge.plus")
                    }
                    .accessibilityLabel(note != nil ? "Edit note" : "Add note")
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
                }
                
                SelectableTextView(
                    text: question.question.text,
                    font: .preferredFont(forTextStyle: .headline),
                    onSelectionChange: { selected in
                        selectedExplainText = selected
                        viewModel.updateSelectedExplainText(selected)
                    }
                )
                
                ForEach(0..<question.shuffledAnswers.count, id: \.self) { index in
                    HStack {
                        SelectableTextView(
                            text: question.shuffledAnswers[index],
                            font: .preferredFont(forTextStyle: .body),
                            onSelectionChange: { selected in
                                selectedExplainText = selected
                                viewModel.updateSelectedExplainText(selected)
                            }
                        )
                        Spacer()
                        if index == question.correctAnswerIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if index == viewModel.selectedAnswer {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(index == question.correctAnswerIndex ? Color.green.opacity(0.1) : (index == viewModel.selectedAnswer ? Color.red.opacity(0.1) : Color.clear))
                    .cornerRadius(8)
                    .shake(trigger: index == viewModel.selectedAnswer && index != question.correctAnswerIndex ? viewModel.shakeIncorrect : 0)
                    .overlay {
                        if index == question.correctAnswerIndex && viewModel.showCorrectFlash {
                            Color.green.opacity(0.3)
                                .cornerRadius(8)
                                .transition(.opacity)
                        } else if index == viewModel.selectedAnswer && index != question.correctAnswerIndex && viewModel.showIncorrectFlash {
                            Color.red.opacity(0.3)
                                .cornerRadius(8)
                                .transition(.opacity)
                        }
                    }
                }
                
                if let explanation = question.question.explanation, !explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Official Explanation", systemImage: "book.pages")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(explanationSections(from: explanation).enumerated()), id: \.offset) { _, section in
                                Text(makeAttributedString(from: section))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.12), Color.indigo.opacity(0.07)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                } else if viewModel.selectedAnswer != question.correctAnswerIndex {
                    Text("No explanation available.")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                ForEach(question.explanationAttachments, id: \.id) { attachment in
                    if let uiImage = loadBundleUIImage(filename: attachment.filename) {
                        ZoomableImageView(uiImage: uiImage)
                    }
                }

                if let mnemonic = viewModel.aiMnemonic {
                    VStack(alignment: .leading) {
                        Text("Mnemonic")
                            .font(.headline)
                        AIMarkdownMathView(content: mnemonic)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                if isAIAvailable {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Co-Pilot")
                                    .font(.headline)
                                Text("Pick a mode and get the explanation in the style you want.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        let aiColumns = [
                            GridItem(.flexible(minimum: 120), spacing: 10),
                            GridItem(.flexible(minimum: 120), spacing: 10)
                        ]

                        LazyVGrid(columns: aiColumns, spacing: 10) {
                            ForEach([
                                QuizViewModel.AIRequestType.explain,
                                .simplify,
                                .analogy,
                                .commonMistakes
                            ], id: \.rawValue) { type in
                                let tool = aiToolPresentation(for: type)
                                Button {
                                    viewModel.requestInlineAI(type: type)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: tool.icon)
                                            .font(.caption.weight(.bold))
                                        Text(tool.title)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                }
                                .buttonStyle(AIActionChipStyle(colors: tool.colors))
                                .accessibilityLabel(type.buttonLabel)
                                .accessibilityHint("Generate an AI explanation")
                            }
                        }

                        if viewModel.isLoadingInlineAI {
                            LoadingAnimationView(
                                requestCount: 0,
                                title: "Crafting your explanation",
                                presentation: .panel
                            )
                        }

                        if let response = viewModel.aiInlineResponse, !response.isEmpty {
                            AIMarkdownMathView(content: response)
                                .padding()
                                .background(Color.blue.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                    .padding(14)
                    .background(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.11), Color.blue.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }

                if isAIAvailable {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Visual Study Prompt")
                            .font(.headline)

                        Button {
                            visualPromptText = viewModel.generateVisualPrompt()
                            showVisualPromptSheet = true
                        } label: {
                            Label("Create Image Prompt", systemImage: "photo.on.rectangle.angled")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(AIActionChipStyle(colors: [.blue, .indigo]))
                    }
                }

                if !isAIAvailable && viewModel.selectedAnswer != question.correctAnswerIndex {
                    aiTeaser
                }
                
            }
            .padding()
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(question: question.question, existingNote: note) { savedNote in
                note = savedNote
            }
        }
        .sheet(isPresented: $showReportSheet) {
            QuestionReportSheet(question: question.question)
        }
        .sheet(isPresented: $showVisualPromptSheet) {
            NavigationStack {
                ScrollView {
                    Text(visualPromptText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle("Visual Prompt")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Copy") {
                            UIPasteboard.general.string = visualPromptText
                        }
                    }
                }
            }
        }
        .onDisappear {
            viewModel.updateSelectedExplainText(nil)
        }
        .onAppear {
            if let deps = dependencies {
                isBookmarked = (try? deps.databaseManager.isBookmarked(questionId: question.question.id)) ?? false
                note = try? deps.databaseManager.fetchNote(questionId: question.question.id)
            }
        }
    }
    
    private var isAIAvailable: Bool {
        dependencies?.isSelectedAIProviderConfigured == true
    }

    private func toggleBookmark() {
        guard let deps = dependencies else { return }
        do {
            if isBookmarked {
                try deps.databaseManager.removeBookmark(questionId: question.question.id)
            } else {
                try deps.databaseManager.addBookmark(questionId: question.question.id)
            }
            isBookmarked.toggle()
        } catch {}
    }
    
    private var aiTeaser: some View {
        NavigationLink {
            if let deps = dependencies {
                SettingsView(viewModel: SettingsViewModel(
                    keychainStore: deps.keychainStore,
                    settingsManager: deps.settingsManager,
                    availableDatasets: deps.availableDatasets,
                    activeDatasetId: deps.activeDataset.id,
                    activeProfileId: deps.activeProfileId,
                    switchDataset: deps.switchDataset
                ))
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get AI Explanations")
                        .font(.subheadline.weight(.semibold))
                    Text("Set up in Settings to get instant help")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppCornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    private func aiToolPresentation(for type: QuizViewModel.AIRequestType) -> (title: String, icon: String, colors: [Color]) {
        switch type {
        case .explain:
            return ("Explain", "lightbulb.fill", [.orange, .yellow])
        case .simplify:
            return ("Simplify", "textformat.abc", [.mint, .green])
        case .analogy:
            return ("Analogy", "point.3.connected.trianglepath.dotted", [.teal, .blue])
        case .commonMistakes:
            return ("Mistakes", "exclamationmark.triangle.fill", [.orange, .red])
        }
    }

    private func explanationSections(from explanation: String) -> [String] {
        let trimmed = explanation
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return trimmed.isEmpty ? [explanation] : trimmed
    }

    private func makeAttributedString(from text: String) -> AttributedString {
        let mutable = NSMutableAttributedString(string: text)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let fullRange = NSRange(location: 0, length: (text as NSString).length)
            detector.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                guard let match, let url = match.url else { return }
                mutable.addAttribute(.link, value: url, range: match.range)
            }
        }
        return (try? AttributedString(mutable, including: \.uiKit)) ?? AttributedString(text)
    }
    
    private func loadBundleUIImage(filename: String) -> UIImage? {
        if let image = dependencies?.questionAssetProvider.uiImage(filename: filename) {
            return image
        }

        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension
        guard let path = Bundle.main.path(forResource: name, ofType: ext),
              let uiImage = UIImage(contentsOfFile: path) else { return nil }
        return uiImage
    }
}

private struct AIActionChipStyle: ButtonStyle {
    let colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [colors.first?.opacity(0.92) ?? .blue, colors.last ?? .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: (colors.last ?? .blue).opacity(0.25), radius: 8, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    let deps = Dependencies.preview
    let sampleQuestion = Question(
        id: 1,
        category: 551,
        code: "Q1",
        text: "Sample question?",
        correct: "A",
        incorrect0: "B",
        incorrect1: "C",
        incorrect2: "D",
        explanation: "Sample explanation",
        reference: nil,
        attachments: nil,
        mockonly: 0
    )
    let presented = PresentedQuestion(
        question: sampleQuestion,
        shuffledAnswers: ["A", "B", "C", "D"],
        correctAnswerIndex: 0,
        questionAttachments: [],
        explanationAttachments: [],
        categoryName: "Air Law"
    )
    ResultView(
        viewModel: deps.makeQuizViewModel(),
        question: presented,
        selectedExplainText: .constant(nil)
    )
    .environment(\.dependencies, deps)
}
