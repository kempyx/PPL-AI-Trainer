import SwiftUI

struct ExamReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [PresentedQuestion]
    let answers: [Int64: String]
    
    private var groupedQuestions: [(category: String, questions: [(question: PresentedQuestion, isCorrect: Bool)])] {
        var grouped: [String: [(PresentedQuestion, Bool)]] = [:]
        
        for question in questions {
            let categoryName = question.question.category
            let studentAnswer = answers[question.question.id] ?? ""
            let isCorrect = studentAnswer == question.question.correct
            
            if grouped[categoryName] == nil {
                grouped[categoryName] = []
            }
            grouped[categoryName]?.append((question, isCorrect))
        }
        
        return grouped.map { (category: $0.key, questions: $0.value) }
            .sorted { first, second in
                let firstCorrect = first.questions.filter { $0.1 }.count
                let secondCorrect = second.questions.filter { $0.1 }.count
                return firstCorrect < secondCorrect
            }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedQuestions, id: \.category) { group in
                    Section {
                        ForEach(Array(group.questions.enumerated()), id: \.offset) { index, item in
                            QuestionReviewRow(
                                question: item.question,
                                studentAnswer: answers[item.question.question.id] ?? "",
                                isCorrect: item.isCorrect
                            )
                        }
                    } header: {
                        HStack {
                            Text(group.category)
                            Spacer()
                            let correct = group.questions.filter { $0.1 }.count
                            Text("\(correct)/\(group.questions.count)")
                                .foregroundColor(correct == group.questions.count ? .green : .orange)
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
                    
                    if !question.question.explanation.isEmpty {
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
                            Text(question.question.explanation)
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
