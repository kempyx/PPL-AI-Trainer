import SwiftUI

struct MockExamResultView: View {
    let result: MockExamResult
    var reviewQuestions: [PresentedQuestion]? = nil
    var reviewAnswers: [Int64: String]? = nil
    
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var showReview = false
    @State private var weakAreaVM: QuizViewModel?
    
    private var leg: ExamLeg {
        ExamLeg(rawValue: result.leg) ?? .technicalLegal
    }
    
    private var subjectScores: [SubjectExamScore] {
        (try? JSONDecoder().decode([SubjectExamScore].self, from: result.categoryBreakdown)) ?? []
    }
    
    private var failedSubjects: [SubjectExamScore] {
        subjectScores.filter { !$0.passed }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text(result.passed ? "PASSED" : "FAILED")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(result.passed ? .green : .red)
                    Text("\(Int(result.percentage))%")
                        .font(.system(size: 60, weight: .bold).monospacedDigit())
                    Text("\(result.correctAnswers) / \(result.totalQuestions) correct")
                        .foregroundColor(.secondary)
                    Text("\(leg.emoji) \(leg.shortTitle)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                
                if !failedSubjects.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Focus Before Retake")
                            .font(.headline)
                        Text("You need 75% in every subject. Prioritize these weak areas first:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(failedSubjects) { subject in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(subject.name)
                                Spacer()
                                Text("\(subject.correctAnswers)/\(subject.totalQuestions)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
                
                VStack(alignment: .leading) {
                    Text("Subject Breakdown")
                        .font(.headline)
                        .padding(.bottom)
                    
                    if !subjectScores.isEmpty {
                        ForEach(subjectScores) { subject in
                            subjectRow(subject)
                        }
                    } else if let breakdown = try? JSONDecoder().decode([CategoryExamScore].self, from: result.categoryBreakdown) {
                        ForEach(breakdown, id: \.categoryId) { score in
                            HStack {
                                Text(score.categoryName)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(score.correctAnswers)/\(score.totalQuestions)")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                
                VStack(spacing: 12) {
                    if let reviewQuestions, reviewAnswers != nil, !reviewQuestions.isEmpty {
                        Button {
                            showReview = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("Review This Attempt")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityHint("Open all questions and your answers from this exam")
                    }
                    
                    if !result.passed {
                        Button {
                            startWeakAreaDrill()
                        } label: {
                            HStack {
                                Image(systemName: "target")
                                Text("Start Weak-Area Drill")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityHint("Launch a targeted practice session based on weak categories")
                    }
                    
                    Button("Back to Mock Exams") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Exam Result")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { weakAreaVM != nil },
            set: { if !$0 { weakAreaVM = nil } }
        )) {
            if let vm = weakAreaVM {
                QuizSessionView(viewModel: vm)
            }
        }
        .sheet(isPresented: $showReview) {
            if let reviewQuestions, let reviewAnswers {
                ExamReviewView(questions: reviewQuestions, answers: reviewAnswers)
            }
        }
    }
    
    @ViewBuilder
    private func subjectRow(_ subject: SubjectExamScore) -> some View {
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
    
    private func startWeakAreaDrill() {
        guard let dependencies else { return }
        let engine = SmartSessionEngine(databaseManager: dependencies.databaseManager)
        guard let questions = try? engine.generateSession(type: .weakAreaFocus, leg: leg), !questions.isEmpty else {
            return
        }
        weakAreaVM = dependencies.quizCoordinator.makeViewModel(mode: .preloaded(questions))
    }
}

#Preview {
    let breakdown = Data("[]".utf8)
    MockExamResultView(
        result: MockExamResult(
            id: 1,
            startedAt: Date().addingTimeInterval(-3600),
            completedAt: Date(),
            totalQuestions: 60,
            correctAnswers: 51,
            percentage: 85,
            passed: true,
            categoryBreakdown: breakdown,
            leg: ExamLeg.technicalLegal.rawValue
        )
    )
}
