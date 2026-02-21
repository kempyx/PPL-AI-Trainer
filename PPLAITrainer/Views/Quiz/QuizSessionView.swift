import SwiftUI

struct QuizSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: QuizViewModel
    @State private var showSummary = false

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
            VStack(spacing: 0) {
                if let current = viewModel.currentQuestion {
                    // Segmented Progress Bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(0..<viewModel.questions.count, id: \.self) { index in
                                Rectangle()
                                    .fill(segmentColor(for: index))
                                    .frame(height: 4)
                            }
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Stats Row
                    HStack {
                        Text("Question \(viewModel.currentIndex + 1)/\(viewModel.questions.count)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // XP Display
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(viewModel.gamificationService.sessionXP)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.yellow.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    if !viewModel.hasSubmitted {
                        QuestionView(question: current, selectedAnswer: $viewModel.selectedAnswer)
                            .id("question-\(viewModel.currentIndex)")
                    } else {
                        ResultView(viewModel: viewModel, question: current)
                            .id("result-\(viewModel.currentIndex)")
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    Spacer()
                } else if viewModel.isQuizComplete {
                    quizCompleteView
                        .onAppear {
                            viewModel.clearSavedSession()
                        }
                } else {
                    ContentUnavailableView("No Questions", systemImage: "questionmark.circle", description: Text("Answer some questions first to unlock this session type"))
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.currentQuestion != nil, !viewModel.hasSubmitted {
                    Button {
                        viewModel.submitAnswer()
                    } label: {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedAnswer == nil ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.selectedAnswer == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(.regularMaterial)
                }
            }

            if viewModel.hasSubmitted && viewModel.settingsManager.aiEnabled {
                Button {
                    viewModel.aiConversation?.showAISheet = true
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
                .accessibilityLabel("Ask AI about this question")
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(duration: 0.3), value: viewModel.hasSubmitted)
            }
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if viewModel.currentIndex > 0 {
                        viewModel.previousQuestion()
                    } else {
                        viewModel.saveSessionState(categoryId: nil, categoryName: nil)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(viewModel.currentIndex > 0 ? "Previous" : "Back")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.aiConversation?.showAISheet ?? false },
            set: { if !$0 { viewModel.aiConversation?.showAISheet = false } }
        )) {
            if let aiVM = viewModel.aiConversation {
                AIConversationSheet(viewModel: aiVM)
                    .presentationDetents([.large])
            }
        }
        .overlay {
            if let achievement = viewModel.gamificationService.recentlyUnlockedAchievements.first {
                BadgeUnlockModal(achievement: achievement) {
                    viewModel.gamificationService.recentlyUnlockedAchievements.removeFirst()
                }
            }
        }
        .overlay {
            if viewModel.gamificationService.didLevelUp {
                ConfettiView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            viewModel.saveSessionState(categoryId: nil, categoryName: nil)
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
                showSummary = true
            } label: {
                Text("View Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal)

            Spacer()
        }
        .sheet(isPresented: $showSummary) {
            PostSessionSummaryView(summary: buildSessionSummary())
        }
    }
    
    private func segmentColor(for index: Int) -> Color {
        if index < viewModel.answerHistory.count {
            return viewModel.answerHistory[index] ? .green : .red
        } else if index == viewModel.currentIndex {
            return .blue
        } else {
            return Color(.systemGray5)
        }
    }
    
    private func buildSessionSummary() -> SessionSummary {
        let accuracy = viewModel.questionsAnswered > 0 ? Double(viewModel.correctCount) / Double(viewModel.questionsAnswered) : 0
        
        return SessionSummary(
            questionsAnswered: viewModel.questionsAnswered,
            correctAnswers: viewModel.correctCount,
            accuracy: accuracy,
            xpEarned: viewModel.gamificationService.sessionXP,
            xpBreakdown: [],
            currentStreak: viewModel.gamificationService.currentStreak,
            categoryDeltas: [],
            suggestedAction: .continuePractice(remaining: 0)
        )
    }
}
