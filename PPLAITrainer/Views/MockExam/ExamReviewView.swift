import SwiftUI

struct ExamReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [PresentedQuestion]
    let answers: [Int64: String]

    private struct ReviewItem: Identifiable {
        let id: Int64
        let question: PresentedQuestion
        let isCorrect: Bool
    }

    private struct ReviewGroup: Identifiable {
        let category: String
        let questions: [ReviewItem]

        var id: String { category }
        var correctCount: Int { questions.filter { $0.isCorrect }.count }
    }
    
    private var groupedQuestions: [ReviewGroup] {
        var grouped: [String: [ReviewItem]] = [:]
        
        for question in questions {
            let categoryName = question.categoryName
            let studentAnswer = answers[question.question.id] ?? ""
            let isCorrect = studentAnswer == question.question.correct
            let item = ReviewItem(id: question.question.id, question: question, isCorrect: isCorrect)
            
            if grouped[categoryName] == nil {
                grouped[categoryName] = []
            }
            grouped[categoryName]?.append(item)
        }
        
        return grouped.map { ReviewGroup(category: $0.key, questions: $0.value) }
            .sorted { first, second in
                first.correctCount < second.correctCount
            }
    }

    private func sectionHeader(for group: ReviewGroup) -> some View {
        HStack {
            Text(group.category)
            Spacer()
            Text("\(group.correctCount)/\(group.questions.count)")
                .foregroundColor(group.correctCount == group.questions.count ? .green : .orange)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedQuestions) { group in
                    Section(header: sectionHeader(for: group)) {
                        ForEach(group.questions) { item in
                            QuestionReviewRow(
                                question: item.question,
                                studentAnswer: answers[item.question.question.id] ?? "",
                                isCorrect: item.isCorrect
                            )
                        }
                    }
                }
            }
            .navigationTitle("Review Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct QuestionReviewRow: View {
    let question: PresentedQuestion
    let studentAnswer: String
    let isCorrect: Bool
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.question.text)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !isCorrect {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Your answer:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(studentAnswer)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Text("Correct answer:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(question.question.correct)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    if let explanation = question.question.explanation, !explanation.isEmpty {
                        Button {
                            withAnimation { isExpanded.toggle() }
                        } label: {
                            HStack {
                                Text(isExpanded ? "Hide Explanation" : "Show Explanation")
                                    .font(.caption)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if isExpanded {
                            Text(explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExamReviewView(
        questions: [],
        answers: [:]
    )
}
