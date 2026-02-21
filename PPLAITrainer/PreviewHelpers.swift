import SwiftUI

extension Dependencies {
    static let preview = Dependencies(
        databaseManager: MockDatabaseManager(),
        srsEngine: SRSEngine(),
        mockExamEngine: MockExamEngine(databaseManager: MockDatabaseManager()),
        keychainStore: KeychainStore(),
        settingsManager: SettingsManager(),
        networkMonitor: NetworkMonitor(),
        aiService: MockAIService(),
        gamificationService: GamificationService(databaseManager: MockDatabaseManager(), settingsManager: SettingsManager()),
        hapticService: HapticService(settingsManager: SettingsManager()),
        soundService: SoundService(settingsManager: SettingsManager()),
        notificationService: NotificationService(settingsManager: SettingsManager())
    )
}

class MockDatabaseManager: DatabaseManaging {
    func fetchAllTopLevelCategories() throws -> [Category] { [] }
    func fetchSubcategories(parentId: Int64) throws -> [Category] { [] }
    func fetchQuestions(categoryId: Int64, excludeMockOnly: Bool) throws -> [Question] { [] }
    func fetchQuestions(parentCategoryId: Int64, excludeMockOnly: Bool) throws -> [Question] { [] }
    func fetchQuestion(id: Int64) throws -> Question? { nil }
    func fetchAttachments(ids: [Int64]) throws -> [Attachment] { [] }
    func fetchQuestionCount(categoryId: Int64, excludeMockOnly: Bool) throws -> Int { 0 }
    func fetchMockExamCategories() throws -> [Category] { [] }
    func fetchRandomQuestions(categoryId: Int64, limit: Int, mockOnlyAllowed: Bool) throws -> [Question] { [] }
    func fetchRandomQuestionsFromCategories(categoryIds: [Int64], limit: Int) throws -> [Question] { [] }
    func recordAnswer(_ record: AnswerRecord) throws {}
    func fetchAnswerHistory(questionId: Int64) throws -> [AnswerRecord] { [] }
    func fetchWrongAnswerQuestionIds() throws -> [Int64] { [] }
    func hasIncorrectAnswers() throws -> Bool { false }
    func fetchCategoryStats(categoryId: Int64) throws -> CategoryStat { CategoryStat(categoryId: categoryId, categoryName: "Test", totalQuestions: 0, answeredQuestions: 0, correctAnswers: 0) }
    func fetchAggregatedCategoryStats(parentId: Int64) throws -> CategoryStat { CategoryStat(categoryId: parentId, categoryName: "Test", totalQuestions: 0, answeredQuestions: 0, correctAnswers: 0) }
    func fetchSubcategoryCount(parentId: Int64) throws -> Int { 0 }
    func fetchAllCategoryStats() throws -> [CategoryStat] { [] }
    func fetchCategoryGroups() throws -> [CategoryGroup] { [] }
    func fetchOrCreateSRSCard(questionId: Int64) throws -> SRSCard { SRSCard(questionId: questionId, box: 0, easeFactor: 2.5, interval: 1, repetitions: 0, nextReviewDate: Date()) }
    func updateSRSCard(_ card: SRSCard) throws {}
    func fetchDueCards(limit: Int?) throws -> [SRSCard] { [] }
    func fetchNextReviewDate() throws -> Date? { nil }
    func fetchSRSStats(categoryId: Int64?) throws -> SRSStats { SRSStats(newCount: 0, learningCount: 0, reviewCount: 0, masteredCount: 0) }
    func fetchAggregatedSRSStats(parentId: Int64) throws -> SRSStats { SRSStats(newCount: 0, learningCount: 0, reviewCount: 0, masteredCount: 0) }
    func fetchSRSMaturity(questionId: Int64) throws -> SRSMaturity { .new }
    func saveMnemonic(_ mnemonic: Mnemonic) throws {}
    func fetchMnemonic(questionId: Int64) throws -> Mnemonic? { nil }
    func saveMockExamResult(_ result: MockExamResult) throws {}
    func fetchMockExamResults() throws -> [MockExamResult] { [] }
    func fetchMockExamResults(leg: ExamLeg) throws -> [MockExamResult] { [] }
    func fetchMockExamResult(id: Int64) throws -> MockExamResult? { nil }
    func recordStudyActivity(date: String, questionsAnswered: Int, correctAnswers: Int) throws {}
    func fetchStudyDays(from: String, to: String) throws -> [StudyDay] { [] }
    func fetchCurrentStreak() throws -> Int { 0 }
    func fetchLongestStreak() throws -> Int { 0 }
    func fetchStudyStats() throws -> StudyStats { StudyStats(answeredToday: 0, answeredThisWeek: 0, answeredAllTime: 0, correctPercentage: 0) }
    func logXP(_ event: XPEvent) throws {}
    func fetchTotalXP() throws -> Int { 0 }
    func fetchXPToday() throws -> Int { 0 }
    func fetchXPThisWeek() throws -> Int { 0 }
    func unlockAchievement(_ achievement: Achievement) throws {}
    func fetchAchievements() throws -> [Achievement] { [] }
    func fetchUnseenAchievements() throws -> [Achievement] { [] }
    func markAchievementSeen(_ id: String) throws {}
    func isAchievementUnlocked(_ id: String) throws -> Bool { false }
    func addBookmark(questionId: Int64) throws {}
    func removeBookmark(questionId: Int64) throws {}
    func isBookmarked(questionId: Int64) throws -> Bool { false }
    func fetchBookmarkedQuestionIds() throws -> [Int64] { [] }
    func fetchBookmarkedQuestions() throws -> [Question] { [] }
    func saveNote(_ note: Note) throws {}
    func fetchNote(questionId: Int64) throws -> Note? { nil }
    func deleteNote(questionId: Int64) throws {}
    func saveQuizSession(_ session: QuizSessionState) throws {}
    func loadQuizSession() throws -> QuizSessionState? { nil }
    func clearQuizSession() throws {}
    func saveAIResponse(_ cache: AIResponseCache) throws {}
    func fetchAIResponse(questionId: Int64, responseType: String) throws -> AIResponseCache? { nil }
    func searchQuestions(query: String, limit: Int) throws -> [Question] { [] }
    func saveQuestionReport(questionId: Int64, reason: String, details: String?) throws {}
    func fetchMnemonicCount() throws -> Int { 0 }
    func fetchConsecutiveCorrectStreak(limit: Int) throws -> Int { 0 }
    func fetchTimesWrong(questionId: Int64) throws -> Int { 0 }
    func fetchSRSCardsAtBoxOrAbove(box: Int, categoryId: Int64) throws -> Int { 0 }
    func fetchTotalSRSCardsForCategory(categoryId: Int64) throws -> Int { 0 }
    func resetAllProgress() throws {}
}

class MockAIService: AIServiceProtocol {
    func sendChat(messages: [ChatMessage]) async throws -> String { "Mock response" }
}
