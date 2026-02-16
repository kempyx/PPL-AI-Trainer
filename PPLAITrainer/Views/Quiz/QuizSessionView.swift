import SwiftUI

struct QuizSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: QuizViewModel

    private var scorePercentage: Int {
        guard viewModel.questionsAnswered > 0 else { return 0 }
        return Int(round(Double(viewModel.correctCount) / Double(viewModel.questionsAnswered) * 100))
    }

    private var scoreColor: Color {
        if scorePercentage >= 75 { return .green }
        if scorePercentage >= 50 { return .orange }
        if scorePercentage > 0 { return .red }
        return .secondary
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                if let current = viewModel.currentQuestion {
                    VStack {
                        Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Score: \(viewModel.correctCount) / \(viewModel.questionsAnswered)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()

                    if !viewModel.hasSubmitted {
                        QuestionView(question: current, selectedAnswer: $viewModel.selectedAnswer)

                        Button("Submit") {
                            viewModel.submitAnswer()
                        }
                        .disabled(viewModel.selectedAnswer == nil)
                        .padding()
                    } else {
                        ResultView(viewModel: viewModel, question: current)
                    }
                } else if viewModel.isQuizComplete {
                    quizCompleteView
                } else {
                    Text("No questions available")
                        .foregroundColor(.gray)
                }
            }

            if viewModel.hasSubmitted && viewModel.settingsManager.aiEnabled {
                Button {
                    viewModel.showAISheet = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(.linearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: viewModel.hasSubmitted)
            }
        }
        .navigationTitle("Quiz")
        .sheet(isPresented: $viewModel.showAISheet) {
            AIResponseSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Quiz Complete View

    private var quizCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(scoreColor)

                Text("Quiz Complete")
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    Text("\(scorePercentage)%")
                        .font(.system(size: 52, weight: .bold).monospacedDigit())
                        .foregroundColor(scoreColor)

                    Text("\(viewModel.correctCount) / \(viewModel.questionsAnswered) correct")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}
