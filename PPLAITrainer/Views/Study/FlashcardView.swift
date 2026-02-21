import SwiftUI

struct FlashcardView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: FlashcardViewModel?
    let sessionType: SessionType
    var leg: ExamLeg = .technicalLegal
    
    var body: some View {
        Group {
            if let viewModel {
                if viewModel.sessionComplete {
                    sessionCompleteView(viewModel: viewModel)
                } else if viewModel.showRoundSummary {
                    roundSummaryView(viewModel: viewModel)
                } else if let question = viewModel.currentQuestion {
                    cardStack(viewModel: viewModel, question: question)
                } else {
                    ContentUnavailableView("No Flashcards", systemImage: "rectangle.portrait.on.rectangle.portrait.slash", description: Text("No questions available"))
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let vm = viewModel {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.reverseMode.toggle()
                    } label: {
                        Image(systemName: "arrow.2.squarepath")
                    }
                    .accessibilityLabel("Toggle card orientation")
                }
            }
            if let vm = viewModel, vm.isRevealed, vm.settingsManager.aiEnabled {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.aiConversation?.showAISheet = true
                    } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.aiConversation?.showAISheet ?? false },
            set: { if !$0 { viewModel?.aiConversation?.showAISheet = false } }
        )) {
            if let aiVM = viewModel?.aiConversation {
                AIConversationSheet(viewModel: aiVM)
            }
        }
        .onAppear {
            if viewModel == nil, let deps = dependencies {
                let vm = FlashcardViewModel(
                    databaseManager: deps.databaseManager,
                    hapticService: deps.hapticService,
                    aiService: deps.aiService,
                    settingsManager: deps.settingsManager
                )
                vm.loadQuestions(sessionType: sessionType, leg: leg)
                viewModel = vm
            }
        }
    }
    
    // MARK: - Card Stack
    
    private func cardStack(viewModel: FlashcardViewModel, question: Question) -> some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .tint(.accentColor)
                HStack {
                    Text("Round \(viewModel.round)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.currentIndex + 1) / \(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
            
            // Card
            ZStack {
                // Next card peek
                if viewModel.currentIndex + 1 < viewModel.questions.count {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .shadow(radius: 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .padding(.horizontal, 28)
                        .offset(y: 8)
                }
                
                flashcard(viewModel: viewModel, question: question)
                    .offset(viewModel.dragOffset)
                    .rotationEffect(.degrees(Double(viewModel.dragOffset.width) / 20))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.dragOffset = value.translation
                                let hit = abs(value.translation.width) > 100
                                if hit != viewModel.hitThreshold {
                                    viewModel.hitThreshold = hit
                                    if hit {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                    }
                                }
                            }
                            .onEnded { value in
                                if value.translation.width > 100 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        viewModel.dragOffset = CGSize(width: 500, height: 0)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        viewModel.dragOffset = .zero
                                        viewModel.hitThreshold = false
                                        viewModel.swipeRight()
                                    }
                                } else if value.translation.width < -100 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        viewModel.dragOffset = CGSize(width: -500, height: 0)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        viewModel.dragOffset = .zero
                                        viewModel.hitThreshold = false
                                        viewModel.swipeLeft()
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewModel.dragOffset = .zero
                                        viewModel.hitThreshold = false
                                    }
                                }
                            }
                    )
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 20) {
                Button {
                    viewModel.swipeLeft()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.red)
                        Text("Don't Know")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark as don't know")
                
                Spacer()
                
                Button {
                    viewModel.swipeRight()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("Know It")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark as know it")
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 16)
            .opacity(viewModel.isFlipped ? 1 : 0)
        }
    }
    
    // MARK: - Flashcard
    
    private func flashcard(viewModel: FlashcardViewModel, question: Question) -> some View {
        let swipeProgress = viewModel.dragOffset.width / 150
        let tintColor: Color = swipeProgress > 0 ? .green : .red
        let tintOpacity = min(abs(swipeProgress), 1.0) * 0.15
        
        let frontText = viewModel.reverseMode ? question.correct : question.text
        let showChoices = viewModel.reverseMode ? !viewModel.isRevealed : viewModel.isRevealed
        
        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(tintColor.opacity(tintOpacity))
                )
                .shadow(radius: 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(frontText)
                        .font(.headline)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if showChoices {
                        Divider()
                        
                        // Choices
                        let choices = viewModel.choicesForCurrent()
                        ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                            HStack(spacing: 10) {
                                let letter = ["A", "B", "C", "D"][index]
                                if viewModel.isRevealed && choice == question.correct {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text(letter)
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color(.systemGray5)))
                                }
                                
                                Text(choice)
                                    .font(.subheadline)
                                    .textSelection(.enabled)
                                    .foregroundStyle(viewModel.isRevealed && choice == question.correct ? .green : .primary)
                                    .fontWeight(viewModel.isRevealed && choice == question.correct ? .semibold : .regular)
                            }
                        }
                    }
                    
                    // Explanation (revealed)
                    if viewModel.isRevealed, let explanation = question.explanation {
                        Divider()
                        Text(explanation)
                            .font(.callout)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Tap to reveal
                    if !viewModel.isRevealed {
                        Text("Tap to reveal")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .scrollDisabled(!viewModel.isRevealed)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.isRevealed else { return }
            withAnimation(.spring(response: 0.4)) {
                viewModel.reveal()
            }
        }
    }
    
    // MARK: - Round Summary
    
    private func roundSummaryView(viewModel: FlashcardViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(viewModel.reviewPile.isEmpty ? "🎉" : "📊")
                .font(.system(size: 60))
            
            Text("Round \(viewModel.round) Complete")
                .font(.title2.weight(.bold))
            
            HStack(spacing: 32) {
                VStack {
                    Text("\(viewModel.knownCount)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.green)
                    Text("Know it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(viewModel.reviewPile.count)")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.red)
                    Text("Review")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !viewModel.reviewPile.isEmpty {
                Text("\(viewModel.reviewPile.count) cards to review")
                    .foregroundStyle(.secondary)
                
                Button {
                    viewModel.startNextRound()
                } label: {
                    Text("Review \(viewModel.reviewPile.count) Cards")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            
            Button {
                viewModel.finishSession()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Session Complete
    
    @Environment(\.dismiss) private var dismiss
    
    private func sessionCompleteView(viewModel: FlashcardViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("🏁")
                .font(.system(size: 60))
            
            Text("Session Complete")
                .font(.title2.weight(.bold))
            
            VStack(spacing: 12) {
                if viewModel.totalRevealed > 0 {
                    statRow(label: "Cards reviewed", value: "\(viewModel.totalRevealed)")
                    statRow(label: "Correct", value: "\(viewModel.totalCorrect)/\(viewModel.totalRevealed)")
                }
                statRow(label: "Rounds", value: "\(viewModel.round)")
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
