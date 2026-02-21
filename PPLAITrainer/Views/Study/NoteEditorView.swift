import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies
    
    let question: Question
    let existingNote: Note?
    let onSave: (Note?) -> Void
    
    @State private var noteText: String
    
    init(question: Question, existingNote: Note?, onSave: @escaping (Note?) -> Void) {
        self.question = question
        self.existingNote = existingNote
        self.onSave = onSave
        _noteText = State(initialValue: existingNote?.text ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $noteText)
                    .padding(8)
                    .cardStyle()
                    .padding()
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if existingNote != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            deleteNote()
                        }
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let deps = dependencies else { return }
        
        do {
            let note = Note(
                questionId: question.id,
                text: trimmed,
                updatedAt: Date()
            )
            try deps.databaseManager.saveNote(note)
            onSave(note)
            dismiss()
        } catch {}
    }
    
    private func deleteNote() {
        guard let note = existingNote, let deps = dependencies else { return }
        try? deps.databaseManager.deleteNote(questionId: note.questionId)
        onSave(nil)
        dismiss()
    }
}

#Preview {
    let sampleQuestion = Question(
        id: 1,
        category: 551,
        code: "Q1",
        text: "Sample question?",
        correct: "A",
        incorrect0: "B",
        incorrect1: "C",
        incorrect2: "D",
        explanation: nil,
        reference: nil,
        attachments: nil,
        mockonly: 0
    )
    NoteEditorView(
        question: sampleQuestion,
        existingNote: nil,
        onSave: { _ in }
    )
    .environment(\.dependencies, Dependencies.preview)
}
