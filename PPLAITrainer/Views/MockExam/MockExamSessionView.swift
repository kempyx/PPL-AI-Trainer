import SwiftUI

struct MockExamSessionView: View {
    @State var viewModel: MockExamViewModel
    @State private var showAbandonAlert = false
    @State private var showResult = false
    @State private var showOverview = false
    @Environment(\.dismiss) private var dismiss
    
    private var answeredCount: Int {
        viewModel.questions.filter { viewModel.answers[$0.question.id] != nil }.count
    }
    
    var body: some View {
        VStack {
            // Header
            VStack(spacing: 4) {
                HStack {
                    Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(timeString(from: viewModel.timeRemaining))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(viewModel.timeRemaining < 300 ? .red : .primary)
                        .pulse(isActive: viewModel.timeRemaining < 60)
                }
                
                HStack {
                    Text("\(answeredCount) answered · \(viewModel.questions.count - answeredCount) remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.questionTimeRemaining))s")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(viewModel.questionTimeRemaining <= 10 ? .red : .orange)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if let current = viewModel.currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(current.question.text)
                            .font(.headline)
                            .textSelection(.enabled)
                            .padding()
                        
                        ForEach(0..<current.shuffledAnswers.count, id: \.self) { index in
                            Button {
                                viewModel.selectAnswer(current.shuffledAnswers[index])
                            } label: {
                                HStack {
                                    Text(current.shuffledAnswers[index])
                                        .foregroundColor(.primary)
                                        .textSelection(.enabled)
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    Button {
                        viewModel.previousQuestion()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(viewModel.currentIndex == 0 ? Color.gray.opacity(0.3) : Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.currentIndex == 0)
                    
                    Spacer()
                    
                    if viewModel.currentIndex == viewModel.questions.count - 1 {
                        Button("Submit") {
                            viewModel.submitExam()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            viewModel.nextQuestion()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mock Exam")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showOverview = true
                } label: {
                    Image(systemName: "square.grid.3x3")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if viewModel.flaggedQuestions.contains(viewModel.currentIndex) {
                        viewModel.flaggedQuestions.remove(viewModel.currentIndex)
                    } else {
                        viewModel.flaggedQuestions.insert(viewModel.currentIndex)
                    }
                } label: {
                    Image(systemName: viewModel.flaggedQuestions.contains(viewModel.currentIndex) ? "flag.fill" : "flag")
                        .foregroundColor(viewModel.flaggedQuestions.contains(viewModel.currentIndex) ? .orange : .primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Abandon") {
                    showAbandonAlert = true
                }
            }
        }
        .sheet(isPresented: $showOverview) {
            QuestionOverviewSheet(viewModel: viewModel, isPresented: $showOverview)
                .presentationDetents([.medium, .large])
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
            if newScore != nil { showResult = true }
        }
        .navigationDestination(isPresented: $showResult) {
            if let score = viewModel.currentScore {
                MockExamScoreResultView(score: score) {
                    showResult = false
                    viewModel.isExamActive = false
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

// MARK: - Question Overview Sheet

private struct QuestionOverviewSheet: View {
    let viewModel: MockExamViewModel
    @Binding var isPresented: Bool
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        legend(color: .blue, label: "Current")
                        legend(color: .green, label: "Answered")
                        legend(color: .orange, label: "Flagged")
                        legend(color: Color(.systemGray4), label: "Skipped")
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<viewModel.questions.count, id: \.self) { index in
                            Button {
                                viewModel.currentIndex = index
                                viewModel.questionTimeRemaining = 75
                                isPresented = false
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Text("\(index + 1)")
                                        .font(.callout.monospacedDigit())
                                        .frame(width: 44, height: 44)
                                        .background(backgroundColor(for: index))
                                        .foregroundStyle(foregroundColor(for: index))
                                        .cornerRadius(8)
                                    
                                    if viewModel.flaggedQuestions.contains(index) {
                                        Image(systemName: "flag.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
    
    private func backgroundColor(for index: Int) -> Color {
        if index == viewModel.currentIndex {
            return .blue
        } else if index > viewModel.highestVisitedIndex {
            return Color(.systemGray6)
        } else if viewModel.answers[viewModel.questions[index].question.id] != nil {
            return .green.opacity(0.3)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private func foregroundColor(for index: Int) -> Color {
        if index == viewModel.currentIndex {
            return .white
        } else if index > viewModel.highestVisitedIndex {
            return Color(.systemGray3)
        } else {
            return .primary
        }
    }
    
    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
        }
    }
}

// MARK: - Mock Exam Score Result View

private struct MockExamScoreResultView: View {
    let score: MockExamScore
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

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
                    Text("Subject Breakdown")
                        .font(.headline)
                        .padding(.bottom)

                    ForEach(score.subjectBreakdown) { subject in
                        HStack {
                            Image(systemName: subject.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(subject.passed ? .green : .red)
                            Text(subject.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(subject.correctAnswers)/\(subject.totalQuestions)")
                                .foregroundColor(subject.passed ? .blue : .red)
                                .bold()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if !score.passed {
                        Text("You need 75% (15/20) on every subject to pass.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()

                Button {
                    onDone()
                    dismiss()
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
