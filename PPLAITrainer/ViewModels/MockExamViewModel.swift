import Foundation
import Observation
import Combine
import os

private let logger = Logger(subsystem: "com.pplaitrainer", category: "MockExamViewModel")

@Observable
final class MockExamViewModel {
    private let databaseManager: DatabaseManaging
    private let mockExamEngine: MockExamEngine
    private let settingsManager: SettingsManager
    var gamificationService: GamificationService?
    
    var selectedLeg: ExamLeg? = nil
    var questions: [PresentedQuestion] = []
    var answers: [Int64: String] = [:]
    var flaggedQuestions: Set<Int> = []
    var currentIndex: Int = 0
    var highestVisitedIndex: Int = 0
    var startTime: Date? = nil
    var timeRemaining: TimeInterval = 0
    var questionTimeRemaining: TimeInterval = 75
    var isExamActive: Bool = false
    var examHistory: [MockExamResult] = []
    var currentScore: MockExamScore? = nil
    var isPracticeMode: Bool = false
    
    private var timer: AnyCancellable?
    
    var activeLeg: ExamLeg {
        settingsManager.activeLeg
    }
    
    var currentQuestion: PresentedQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }
    
    init(databaseManager: DatabaseManaging, mockExamEngine: MockExamEngine, settingsManager: SettingsManager) {
        self.databaseManager = databaseManager
        self.mockExamEngine = mockExamEngine
        self.settingsManager = settingsManager
    }
    
    func startExam(leg: ExamLeg, practiceMode: Bool = false) {
        selectedLeg = leg
        isPracticeMode = practiceMode
        Task { await startExamAsync(leg: leg) }
    }
    
    @MainActor
    private func startExamAsync(leg: ExamLeg) async {
        do {
            let rawQuestions = try mockExamEngine.generateExam(leg: leg)
            logger.info("Loaded \(rawQuestions.count) questions for \(leg.title)")
            
            questions = try rawQuestions.map { try PresentedQuestion.from($0, databaseManager: databaseManager) }
            
            startTime = Date()
            timeRemaining = mockExamEngine.timeLimit(leg: leg)
            isExamActive = true
            currentIndex = 0
            highestVisitedIndex = 0
            questionTimeRemaining = 75
            answers = [:]
            currentScore = nil
            
            if !isPracticeMode {
                startTimer()
            }
        } catch {
            logger.error("Failed to start exam: \(error.localizedDescription)")
            questions = []
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.submitExam()
                }
            }
    }
    
    func selectAnswer(_ answer: String) {
        guard let current = currentQuestion else { return }
        answers[current.question.id] = answer
    }
    
    func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            questionTimeRemaining = 75
            if currentIndex > highestVisitedIndex { highestVisitedIndex = currentIndex }
        }
    }
    
    func previousQuestion() {
        if currentIndex > 0 {
            currentIndex -= 1
            questionTimeRemaining = 75
        }
    }
    
    func submitExam() {
        timer?.cancel()
        timer = nil
        isExamActive = false
        Task { await scoreAndSaveExam() }
    }
    
    func abandonExam(save: Bool) {
        timer?.cancel()
        timer = nil
        isExamActive = false
        if save {
            Task { await scoreAndSaveExam() }
        } else {
            questions = []
            answers = [:]
            currentIndex = 0
        }
    }
    
    @MainActor
    private func scoreAndSaveExam() async {
        guard let startTime else { return }
        do {
            let leg = selectedLeg ?? activeLeg
            let score = try mockExamEngine.scoreExam(questions: questions.map(\.question), answers: answers, leg: leg)
            currentScore = score
            logger.info("Exam scored: \(score.correctAnswers)/\(score.totalQuestions) (\(Int(score.percentage))%)")
            
            let result = MockExamResult(
                id: nil, startedAt: startTime, completedAt: Date(),
                totalQuestions: score.totalQuestions, correctAnswers: score.correctAnswers,
                percentage: score.percentage, passed: score.passed,
                categoryBreakdown: try JSONEncoder().encode(score.subjectBreakdown),
                leg: leg.rawValue
            )
            try databaseManager.saveMockExamResult(result)
            
            if score.passed, let gamificationService {
                try? gamificationService.awardMockExamPassXP()
                try? gamificationService.checkAchievements(context: AchievementContext(mockExamPassed: true))
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            try databaseManager.recordStudyActivity(date: formatter.string(from: Date()), questionsAnswered: score.totalQuestions, correctAnswers: score.correctAnswers)
            
            await loadHistoryAsync()
        } catch {
            logger.error("Failed to score/save exam: \(error.localizedDescription)")
        }
    }
    
    func loadHistory() {
        Task { await loadHistoryAsync() }
    }
    
    @MainActor
    private func loadHistoryAsync() async {
        examHistory = (try? databaseManager.fetchMockExamResults(leg: activeLeg)) ?? []
    }
}
