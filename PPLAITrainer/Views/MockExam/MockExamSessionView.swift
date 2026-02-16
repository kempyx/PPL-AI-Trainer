import SwiftUI

struct MockExamSessionView: View {
    @State var viewModel: MockExamViewModel
    @State private var showAbandonAlert = false
    @State private var showResult = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                    .font(.caption)
                
                Spacer()
                
                Text(timeString(from: viewModel.timeRemaining))
                    .font(.caption)
                    .foregroundColor(viewModel.timeRemaining < 300 ? .red : .primary)
            }
            .padding()
            
            if let current = viewModel.currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(current.question.text)
                            .font(.headline)
                            .padding()
                        
                        ForEach(0..<current.shuffledAnswers.count, id: \.self) { index in
                            Button {
                                viewModel.selectAnswer(current.shuffledAnswers[index])
                            } label: {
                                HStack {
                                    Text(current.shuffledAnswers[index])
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.answers[current.question.id] == current.shuffledAnswers[index] {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(viewModel.answers[current.question.id] == current.shuffledAnswers[index] ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button("Previous") {
                        viewModel.previousQuestion()
                    }
                    .disabled(viewModel.currentIndex == 0)
                    
                    Spacer()
                    
                    if viewModel.currentIndex == viewModel.questions.count - 1 {
                        Button("Submit") {
                            viewModel.submitExam()
                        }
                    } else {
                        Button("Next") {
                            viewModel.nextQuestion()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mock Exam")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Abandon") {
                    showAbandonAlert = true
                }
            }
        }
        .alert("Abandon Exam?", isPresented: $showAbandonAlert) {
            Button("Save & Exit") {
                viewModel.abandonExam(save: true)
                dismiss()
            }
            Button("Discard", role: .destructive) {
                viewModel.abandonExam(save: false)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to save your progress or discard this attempt?")
        }
        .onChange(of: viewModel.currentScore) { _, newScore in
            if newScore != nil {
                showResult = true
            }
        }
        .navigationDestination(isPresented: $showResult) {
            if let score = viewModel.currentScore {
                MockExamScoreResultView(score: score) {
                    dismiss()
                }
            }
        }
    }
    
    private func timeString(from seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Mock Exam Score Result View

private struct MockExamScoreResultView: View {
    let score: MockExamScore
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    Text(score.passed ? "PASSED" : "FAILED")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(score.passed ? .green : .red)

                    Text("\(score.percentage.isNaN ? 0 : Int(score.percentage))%")
                        .font(.system(size: 60))
                        .bold()

                    Text("\(score.correctAnswers) / \(score.totalQuestions) correct")
                        .foregroundColor(.gray)
                }
                .padding()

                VStack(alignment: .leading) {
                    Text("Category Breakdown")
                        .font(.headline)
                        .padding(.bottom)

                    ForEach(score.categoryBreakdown, id: \.categoryId) { category in
                        HStack {
                            Text(category.categoryName)
                                .font(.subheadline)
                            Spacer()
                            Text("\(category.correctAnswers) / \(category.totalQuestions)")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding()

                Button {
                    onDone()
                } label: {
                    Text("Back to Mock Exams")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Exam Result")
        .navigationBarBackButtonHidden(true)
    }
}
