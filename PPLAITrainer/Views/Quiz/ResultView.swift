import SwiftUI

struct ResultView: View {
    @State var viewModel: QuizViewModel
    @Environment(\.dependencies) private var dependencies
    let question: PresentedQuestion
    @State private var isBookmarked = false
    @State private var showNoteEditor = false
    @State private var note: Note?
    @State private var showReportSheet = false
    
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
                    Button {
                        showNoteEditor = true
                    } label: {
                        Image(systemName: note != nil ? "note.text" : "note.text.badge.plus")
                    }
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                }
                
                Text(question.question.text)
                    .font(.body.weight(.semibold))
                    .textSelection(.enabled)
                
                ForEach(0..<question.shuffledAnswers.count, id: \.self) { index in
                    HStack {
                        Text(question.shuffledAnswers[index])
                            .textSelection(.enabled)
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
                    let isCorrect = viewModel.selectedAnswer == question.correctAnswerIndex
                    DisclosureGroup(
                        isExpanded: .constant(!isCorrect),
                        content: {
                            Text(makeAttributedString(from: explanation))
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(AppCornerRadius.small)
                        },
                        label: {
                            Text("Explanation")
                                .font(.headline)
                        }
                    )
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
                        Text(mnemonic)
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                if !viewModel.settingsManager.aiEnabled && viewModel.selectedAnswer != question.correctAnswerIndex {
                    aiTeaser
                }
                
                Button("Next Question") {
                    viewModel.nextQuestion()
                }
                .buttonStyle(PrimaryButtonStyle())
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
        .onAppear {
            if let deps = dependencies {
                isBookmarked = (try? deps.databaseManager.isBookmarked(questionId: question.question.id)) ?? false
                note = try? deps.databaseManager.fetchNote(questionId: question.question.id)
            }
        }
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
                SettingsView(viewModel: SettingsViewModel(keychainStore: deps.keychainStore, settingsManager: deps.settingsManager))
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
    
    private func makeAttributedString(from text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let attributedRange = AttributedString(text[range]).range
                    if let url = match.url, let attrRange = attributedRange {
                        attributedString[attrRange].link = url
                    }
                }
            }
        }
        return attributedString
    }
    
    private func loadBundleUIImage(filename: String) -> UIImage? {
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension
        guard let path = Bundle.main.path(forResource: name, ofType: ext),
              let uiImage = UIImage(contentsOfFile: path) else { return nil }
        return uiImage
    }
}
