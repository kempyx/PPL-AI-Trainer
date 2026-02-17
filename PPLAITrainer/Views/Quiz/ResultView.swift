import SwiftUI

struct ResultView: View {
    @State var viewModel: QuizViewModel
    @Environment(\.dependencies) private var dependencies
    let question: PresentedQuestion
    @State private var isBookmarked = false
    @State private var showNoteEditor = false
    @State private var note: Note?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
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
                    VStack(alignment: .leading) {
                        Text("Explanation")
                            .font(.headline)
                        Text(explanation)
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
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
                
                Button("Next Question") {
                    viewModel.nextQuestion()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(question: question.question, existingNote: note) { savedNote in
                note = savedNote
            }
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
    
    private func loadBundleUIImage(filename: String) -> UIImage? {
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension
        guard let path = Bundle.main.path(forResource: name, ofType: ext),
              let uiImage = UIImage(contentsOfFile: path) else { return nil }
        return uiImage
    }
}
