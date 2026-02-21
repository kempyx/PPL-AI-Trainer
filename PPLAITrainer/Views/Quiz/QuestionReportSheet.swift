import SwiftUI

struct QuestionReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var deps
    let question: Question
    
    @State private var selectedReason: ReportReason?
    @State private var additionalInfo = ""
    @State private var isSubmitting = false
    
    enum ReportReason: String, CaseIterable, Identifiable {
        case incorrectAnswer = "Incorrect Answer"
        case outdatedInfo = "Outdated Information"
        case typo = "Typo or Grammar"
        case unclear = "Unclear Question"
        case other = "Other"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("What's wrong with this question?") {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Additional Details (Optional)") {
                    TextEditor(text: $additionalInfo)
                        .frame(height: 100)
                }
                
                Section {
                    Button {
                        submitReport()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Report")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
            .navigationTitle("Report Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func submitReport() {
        guard let reason = selectedReason, let deps = deps else { return }
        isSubmitting = true
        
        Task {
            do {
                try deps.databaseManager.saveQuestionReport(
                    questionId: question.id,
                    reason: reason.rawValue,
                    details: additionalInfo.isEmpty ? nil : additionalInfo
                )
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

#Preview {
    QuestionReportSheet(question: Question(
        id: 1,
        code: "TEST",
        category: "Test",
        text: "Test question",
        correct: "A",
        incorrect0: "B",
        incorrect1: "C",
        incorrect2: "D",
        explanation: "Test",
        attachments: nil
    ))
}
