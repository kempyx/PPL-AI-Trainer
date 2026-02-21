import GRDB
import Foundation
import os

private let logger = Logger(subsystem: "com.primendro.PPLAITrainer", category: "Database")

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

protocol DatabaseManaging {
    func fetchAllTopLevelCategories() throws -> [Category]
    func fetchSubcategories(parentId: Int64) throws -> [Category]
    func fetchQuestions(categoryId: Int64, excludeMockOnly: Bool) throws -> [Question]
    func fetchQuestions(parentCategoryId: Int64, excludeMockOnly: Bool) throws -> [Question]
    func fetchQuestion(id: Int64) throws -> Question?
    func fetchAttachments(ids: [Int64]) throws -> [Attachment]
    func fetchQuestionCount(categoryId: Int64, excludeMockOnly: Bool) throws -> Int
    func fetchMockExamCategories() throws -> [Category]
    func fetchRandomQuestions(categoryId: Int64, limit: Int, mockOnlyAllowed: Bool) throws -> [Question]
    func fetchRandomQuestionsFromCategories(categoryIds: [Int64], limit: Int) throws -> [Question]

    func recordAnswer(_ record: AnswerRecord) throws
    func fetchAnswerHistory(questionId: Int64) throws -> [AnswerRecord]
    func fetchWrongAnswerQuestionIds() throws -> [Int64]
    func hasIncorrectAnswers() throws -> Bool
    func fetchCategoryStats(categoryId: Int64) throws -> CategoryStat
    func fetchAggregatedCategoryStats(parentId: Int64) throws -> CategoryStat
    func fetchSubcategoryCount(parentId: Int64) throws -> Int
    func fetchAllCategoryStats() throws -> [CategoryStat]
    func fetchCategoryGroups() throws -> [CategoryGroup]

    func fetchOrCreateSRSCard(questionId: Int64) throws -> SRSCard
    func updateSRSCard(_ card: SRSCard) throws
    func fetchDueCards(limit: Int?) throws -> [SRSCard]
    func fetchNextReviewDate() throws -> Date?
    func fetchSRSStats(categoryId: Int64?) throws -> SRSStats
    func fetchAggregatedSRSStats(parentId: Int64) throws -> SRSStats
    func fetchSRSMaturity(questionId: Int64) throws -> SRSMaturity

    func saveMnemonic(_ mnemonic: Mnemonic) throws
    func fetchMnemonic(questionId: Int64) throws -> Mnemonic?

    func saveMockExamResult(_ result: MockExamResult) throws
    func fetchMockExamResults() throws -> [MockExamResult]
    func fetchMockExamResults(leg: ExamLeg) throws -> [MockExamResult]
    func fetchMockExamResult(id: Int64) throws -> MockExamResult?

    func recordStudyActivity(date: String, questionsAnswered: Int, correctAnswers: Int) throws
    func fetchStudyDays(from: String, to: String) throws -> [StudyDay]
    func fetchCurrentStreak() throws -> Int
    func fetchLongestStreak() throws -> Int
    func fetchStudyStats() throws -> StudyStats
    
    // XP methods
    func logXP(_ event: XPEvent) throws
    func fetchTotalXP() throws -> Int
    func fetchXPToday() throws -> Int
    func fetchXPThisWeek() throws -> Int
    
    // Achievement methods
    func unlockAchievement(_ achievement: Achievement) throws
    func fetchAchievements() throws -> [Achievement]
    func fetchUnseenAchievements() throws -> [Achievement]
    func markAchievementSeen(_ id: String) throws
    func isAchievementUnlocked(_ id: String) throws -> Bool
    
    // Bookmark methods
    func addBookmark(questionId: Int64) throws
    func removeBookmark(questionId: Int64) throws
    func isBookmarked(questionId: Int64) throws -> Bool
    func fetchBookmarkedQuestionIds() throws -> [Int64]
    func fetchBookmarkedQuestions() throws -> [Question]
    
    // Note methods
    func saveNote(_ note: Note) throws
    func fetchNote(questionId: Int64) throws -> Note?
    func deleteNote(questionId: Int64) throws
    
    // Quiz session persistence
    func saveQuizSession(_ session: QuizSessionState) throws
    func loadQuizSession() throws -> QuizSessionState?
    func clearQuizSession() throws
    
    // AI response caching
    func saveAIResponse(_ cache: AIResponseCache) throws
    func fetchAIResponse(questionId: Int64, responseType: String) throws -> AIResponseCache?
    
    // Search
    func searchQuestions(query: String, limit: Int) throws -> [Question]
    
    // Question reports
    func saveQuestionReport(questionId: Int64, reason: String, details: String?) throws
    
    // Gamification helpers
    func fetchMnemonicCount() throws -> Int
    func fetchConsecutiveCorrectStreak(limit: Int) throws -> Int
    func fetchTimesWrong(questionId: Int64) throws -> Int
    func fetchSRSCardsAtBoxOrAbove(box: Int, categoryId: Int64) throws -> Int
    func fetchTotalSRSCardsForCategory(categoryId: Int64) throws -> Int
    func resetAllProgress() throws
}

final class DatabaseManager: DatabaseManaging {
    private let dbQueue: DatabaseQueue

    init() throws {
        let fileManager = FileManager.default
        let documentsPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dbPath = documentsPath.appendingPathComponent("153-en.sqlite")

        if !fileManager.fileExists(atPath: dbPath.path) {
            guard let bundlePath = Bundle.main.path(forResource: "153-en", ofType: "sqlite") else {
                logger.error("Bundled database not found in app bundle")
                throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bundled database not found"])
            }
            try fileManager.copyItem(atPath: bundlePath, toPath: dbPath.path)
            logger.info("Database copied to \(dbPath.path)")
        } else {
            logger.info("Database already exists at \(dbPath.path)")
        }

        dbQueue = try DatabaseQueue(path: dbPath.path)
        try runMigrations()

        let count = try dbQueue.read { db in try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM questions") ?? 0 }
        logger.info("Database ready — \(count) questions loaded")
    }

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1-core") { db in
            try db.create(table: "answer_records") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("questionId", .integer).notNull().indexed()
                t.column("chosenAnswer", .text).notNull()
                t.column("isCorrect", .boolean).notNull()
                t.column("timestamp", .datetime).notNull()
            }

            try db.create(table: "mnemonics") { t in
                t.column("questionId", .integer).primaryKey()
                t.column("text", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v2-srs") { db in
            try db.create(table: "srs_cards") { t in
                t.column("questionId", .integer).primaryKey()
                t.column("box", .integer).notNull()
                t.column("easeFactor", .double).notNull()
                t.column("interval", .integer).notNull()
                t.column("repetitions", .integer).notNull()
                t.column("nextReviewDate", .datetime).notNull().indexed()
            }
        }

        migrator.registerMigration("v3-mock-exams") { db in
            try db.create(table: "mock_exam_results") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("startedAt", .datetime).notNull()
                t.column("completedAt", .datetime).notNull()
                t.column("totalQuestions", .integer).notNull()
                t.column("correctAnswers", .integer).notNull()
                t.column("percentage", .double).notNull()
                t.column("passed", .boolean).notNull()
                t.column("categoryBreakdown", .blob).notNull()
            }
        }

        migrator.registerMigration("v4-study-days") { db in
            try db.create(table: "study_days") { t in
                t.column("date", .text).primaryKey()
                t.column("questionsAnswered", .integer).notNull()
                t.column("correctAnswers", .integer).notNull()
            }
        }

        migrator.registerMigration("v5-gamification") { db in
            try db.create(table: "xp_events") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("amount", .integer).notNull()
                t.column("source", .text).notNull()
                t.column("timestamp", .datetime).notNull().indexed()
            }
            try db.create(table: "achievements") { t in
                t.column("id", .text).primaryKey()
                t.column("unlockedAt", .datetime).notNull()
                t.column("seen", .boolean).notNull().defaults(to: false)
            }
            try db.create(table: "bookmarks") { t in
                t.column("questionId", .integer).primaryKey()
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(table: "notes") { t in
                t.column("questionId", .integer).primaryKey()
                t.column("text", .text).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        
        migrator.registerMigration("v6-mock-exam-leg") { db in
            try db.alter(table: "mock_exam_results") { t in
                t.add(column: "leg", .integer).notNull().defaults(to: 1)
            }
        }
        
        migrator.registerMigration("v7-quiz-sessions") { db in
            try db.create(table: "quiz_sessions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("categoryId", .integer)
                t.column("categoryName", .text)
                t.column("currentIndex", .integer).notNull()
                t.column("questionIds", .text).notNull()
                t.column("answers", .text).notNull()
                t.column("timestamp", .datetime).notNull()
            }
        }
        
        migrator.registerMigration("v8-ai-cache") { db in
            try db.create(table: "ai_response_cache") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("questionId", .integer).notNull().indexed()
                t.column("responseType", .text).notNull()
                t.column("response", .text).notNull()
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(index: "idx_ai_cache_question_type", on: "ai_response_cache", columns: ["questionId", "responseType"], unique: true)
        }
        
        migrator.registerMigration("v9-question-reports") { db in
            try db.create(table: "question_reports") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("questionId", .integer).notNull().indexed()
                t.column("reason", .text).notNull()
                t.column("details", .text)
                t.column("createdAt", .datetime).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }

    func fetchAllTopLevelCategories() throws -> [Category] {
        try dbQueue.read { db in
            try Category.filter(Column("parent") == nil || Column("parent") == 0).order(Column("sortorder")).fetchAll(db)
        }
    }

    func fetchSubcategories(parentId: Int64) throws -> [Category] {
        try dbQueue.read { db in
            try Category.filter(Column("parent") == parentId).order(Column("sortorder")).fetchAll(db)
        }
    }

    func fetchQuestions(categoryId: Int64, excludeMockOnly: Bool) throws -> [Question] {
        try dbQueue.read { db in
            var request = Question.filter(Column("category") == categoryId)
            if excludeMockOnly {
                request = request.filter(Column("mockonly") == 0)
            }
            return try request.fetchAll(db)
        }
    }

    func fetchQuestions(parentCategoryId: Int64, excludeMockOnly: Bool) throws -> [Question] {
        try dbQueue.read { db in
            let subcategories = try Category.filter(Column("parent") == parentCategoryId).fetchAll(db)
            let categoryIds = subcategories.map(\.id)
            var request = Question.filter(categoryIds.contains(Column("category")))
            if excludeMockOnly {
                request = request.filter(Column("mockonly") == 0)
            }
            return try request.fetchAll(db)
        }
    }

    func fetchQuestion(id: Int64) throws -> Question? {
        try dbQueue.read { db in
            try Question.fetchOne(db, key: id)
        }
    }

    func fetchAttachments(ids: [Int64]) throws -> [Attachment] {
        try dbQueue.read { db in
            try Attachment.filter(ids.contains(Column("id"))).fetchAll(db)
        }
    }

    func fetchQuestionCount(categoryId: Int64, excludeMockOnly: Bool) throws -> Int {
        try dbQueue.read { db in
            var request = Question.filter(Column("category") == categoryId)
            if excludeMockOnly {
                request = request.filter(Column("mockonly") == 0)
            }
            return try request.fetchCount(db)
        }
    }

    func fetchMockExamCategories() throws -> [Category] {
        try dbQueue.read { db in
            try Category.filter(Column("quantityinmock") > 0).order(Column("sortorder")).fetchAll(db)
        }
    }

    func fetchRandomQuestions(categoryId: Int64, limit: Int, mockOnlyAllowed: Bool) throws -> [Question] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM questions WHERE category = ? "
            if !mockOnlyAllowed {
                sql += "AND mockonly = 0 "
            }
            sql += "ORDER BY RANDOM() LIMIT ?"
            return try Question.fetchAll(db, sql: sql, arguments: [categoryId, limit])
        }
    }

    func fetchRandomQuestionsFromCategories(categoryIds: [Int64], limit: Int) throws -> [Question] {
        guard !categoryIds.isEmpty else { return [] }
        return try dbQueue.read { db in
            let placeholders = categoryIds.map { _ in "?" }.joined(separator: ",")
            let sql = "SELECT * FROM questions WHERE category IN (\(placeholders)) ORDER BY RANDOM() LIMIT ?"
            var args: [DatabaseValueConvertible] = categoryIds
            args.append(limit)
            return try Question.fetchAll(db, sql: sql, arguments: StatementArguments(args))
        }
    }

    func recordAnswer(_ record: AnswerRecord) throws {
        try dbQueue.write { db in
            var mutableRecord = record
            try mutableRecord.insert(db)
        }
    }

    func fetchAnswerHistory(questionId: Int64) throws -> [AnswerRecord] {
        try dbQueue.read { db in
            try AnswerRecord.filter(Column("questionId") == questionId).order(Column("timestamp").desc).fetchAll(db)
        }
    }

    func fetchWrongAnswerQuestionIds() throws -> [Int64] {
        try dbQueue.read { db in
            try Int64.fetchAll(db, sql: """
                SELECT questionId FROM answer_records
                WHERE id IN (
                    SELECT MAX(id) FROM answer_records GROUP BY questionId
                ) AND isCorrect = 0
            """)
        }
    }

    func hasIncorrectAnswers() throws -> Bool {
        try dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM answer_records
                WHERE id IN (
                    SELECT MAX(id) FROM answer_records GROUP BY questionId
                ) AND isCorrect = 0
            """) ?? 0
            return count > 0
        }
    }

    func fetchCategoryStats(categoryId: Int64) throws -> CategoryStat {
        try dbQueue.read { db in
            let category = try Category.fetchOne(db, key: categoryId)
            let categoryName = category?.name ?? ""
            let totalQuestions = try Question.filter(Column("category") == categoryId).fetchCount(db)

            let answeredQuestions = try Int.fetchOne(db, sql: """
                SELECT COUNT(DISTINCT questionId) FROM answer_records
                WHERE questionId IN (SELECT id FROM questions WHERE category = ?)
            """, arguments: [categoryId]) ?? 0

            let correctAnswers = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM answer_records
                WHERE questionId IN (SELECT id FROM questions WHERE category = ?)
                AND id IN (SELECT MAX(id) FROM answer_records GROUP BY questionId)
                AND isCorrect = 1
            """, arguments: [categoryId]) ?? 0

            return CategoryStat(categoryId: categoryId, categoryName: categoryName, totalQuestions: totalQuestions, answeredQuestions: answeredQuestions, correctAnswers: correctAnswers)
        }
    }

    func fetchAggregatedCategoryStats(parentId: Int64) throws -> CategoryStat {
        try dbQueue.read { db in
            let parent = try Category.fetchOne(db, key: parentId)
            let parentName = parent?.name ?? ""

            let totalQuestions = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM questions
                WHERE category IN (SELECT id FROM categories WHERE parent = ?)
            """, arguments: [parentId]) ?? 0

            let answeredQuestions = try Int.fetchOne(db, sql: """
                SELECT COUNT(DISTINCT questionId) FROM answer_records
                WHERE questionId IN (
                    SELECT id FROM questions WHERE category IN (SELECT id FROM categories WHERE parent = ?)
                )
            """, arguments: [parentId]) ?? 0

            let correctAnswers = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM answer_records
                WHERE questionId IN (
                    SELECT id FROM questions WHERE category IN (SELECT id FROM categories WHERE parent = ?)
                )
                AND id IN (SELECT MAX(id) FROM answer_records GROUP BY questionId)
                AND isCorrect = 1
            """, arguments: [parentId]) ?? 0

            return CategoryStat(categoryId: parentId, categoryName: parentName, totalQuestions: totalQuestions, answeredQuestions: answeredQuestions, correctAnswers: correctAnswers)
        }
    }

    func fetchSubcategoryCount(parentId: Int64) throws -> Int {
        try dbQueue.read { db in
            try Category.filter(Column("parent") == parentId).fetchCount(db)
        }
    }

    func fetchAllCategoryStats() throws -> [CategoryStat] {
        let categories = try fetchAllTopLevelCategories()
        return try categories.map { try fetchCategoryStats(categoryId: $0.id) }
    }

    func fetchCategoryGroups() throws -> [CategoryGroup] {
        try dbQueue.read { db in
            try CategoryGroup.fetchAll(db)
        }
    }

    func fetchOrCreateSRSCard(questionId: Int64) throws -> SRSCard {
        try dbQueue.write { db in
            if let card = try SRSCard.fetchOne(db, key: questionId) {
                return card
            }
            var newCard = SRSCard(questionId: questionId, box: 0, easeFactor: 2.5, interval: 1, repetitions: 0, nextReviewDate: Date())
            try newCard.insert(db)
            return newCard
        }
    }

    func updateSRSCard(_ card: SRSCard) throws {
        try dbQueue.write { db in
            try card.update(db)
        }
    }

    func fetchDueCards(limit: Int?) throws -> [SRSCard] {
        try dbQueue.read { db in
            var request = SRSCard.filter(Column("nextReviewDate") <= Date()).order(Column("nextReviewDate"))
            if let limit = limit {
                request = request.limit(limit)
            }
            return try request.fetchAll(db)
        }
    }

    func fetchNextReviewDate() throws -> Date? {
        try dbQueue.read { db in
            try SRSCard.filter(Column("nextReviewDate") > Date()).order(Column("nextReviewDate")).fetchOne(db)?.nextReviewDate
        }
    }

    func fetchSRSStats(categoryId: Int64?) throws -> SRSStats {
        try dbQueue.read { db in
            var sql = "SELECT box FROM srs_cards"
            var args: [DatabaseValueConvertible] = []

            if let categoryId = categoryId {
                sql += " WHERE questionId IN (SELECT id FROM questions WHERE category = ?)"
                args.append(categoryId)
            }

            let boxes = try Int.fetchAll(db, sql: sql, arguments: StatementArguments(args))

            let newCount = boxes.filter { $0 == 0 }.count
            let learningCount = boxes.filter { $0 == 1 }.count
            let reviewCount = boxes.filter { $0 == 2 || $0 == 3 }.count
            let masteredCount = boxes.filter { $0 >= 4 }.count

            return SRSStats(newCount: newCount, learningCount: learningCount, reviewCount: reviewCount, masteredCount: masteredCount)
        }
    }

    func fetchAggregatedSRSStats(parentId: Int64) throws -> SRSStats {
        try dbQueue.read { db in
            let boxes = try Int.fetchAll(db, sql: """
                SELECT box FROM srs_cards
                WHERE questionId IN (
                    SELECT id FROM questions WHERE category IN (
                        SELECT id FROM categories WHERE parent = ?
                    )
                )
            """, arguments: [parentId])

            let newCount = boxes.filter { $0 == 0 }.count
            let learningCount = boxes.filter { $0 == 1 }.count
            let reviewCount = boxes.filter { $0 == 2 || $0 == 3 }.count
            let masteredCount = boxes.filter { $0 >= 4 }.count

            return SRSStats(newCount: newCount, learningCount: learningCount, reviewCount: reviewCount, masteredCount: masteredCount)
        }
    }

    func fetchSRSMaturity(questionId: Int64) throws -> SRSMaturity {
        try dbQueue.read { db in
            guard let card = try SRSCard.fetchOne(db, key: questionId) else {
                return .new
            }
            switch card.box {
            case 0, 1: return .learning
            case 2, 3: return .review
            case 4...: return .mastered
            default: return .new
            }
        }
    }

    func saveMnemonic(_ mnemonic: Mnemonic) throws {
        try dbQueue.write { db in
            var mutableMnemonic = mnemonic
            try mutableMnemonic.save(db)
        }
    }

    func fetchMnemonic(questionId: Int64) throws -> Mnemonic? {
        try dbQueue.read { db in
            try Mnemonic.fetchOne(db, key: questionId)
        }
    }

    func saveMockExamResult(_ result: MockExamResult) throws {
        try dbQueue.write { db in
            var mutableResult = result
            try mutableResult.insert(db)
        }
    }

    func fetchMockExamResults() throws -> [MockExamResult] {
        try dbQueue.read { db in
            try MockExamResult.order(Column("completedAt").desc).fetchAll(db)
        }
    }
    
    func fetchMockExamResults(leg: ExamLeg) throws -> [MockExamResult] {
        try dbQueue.read { db in
            try MockExamResult
                .filter(Column("leg") == leg.rawValue)
                .order(Column("completedAt").desc)
                .fetchAll(db)
        }
    }

    func fetchMockExamResult(id: Int64) throws -> MockExamResult? {
        try dbQueue.read { db in
            try MockExamResult.fetchOne(db, key: id)
        }
    }

    func recordStudyActivity(date: String, questionsAnswered: Int, correctAnswers: Int) throws {
        try dbQueue.write { db in
            if var existing = try StudyDay.fetchOne(db, key: date) {
                existing.questionsAnswered += questionsAnswered
                existing.correctAnswers += correctAnswers
                try existing.update(db)
            } else {
                var newDay = StudyDay(date: date, questionsAnswered: questionsAnswered, correctAnswers: correctAnswers)
                try newDay.insert(db)
            }
        }
    }

    func fetchStudyDays(from: String, to: String) throws -> [StudyDay] {
        try dbQueue.read { db in
            try StudyDay.filter(Column("date") >= from && Column("date") <= to).order(Column("date")).fetchAll(db)
        }
    }

    func fetchCurrentStreak() throws -> Int {
        try dbQueue.read { db in
            let days = try StudyDay.order(Column("date").desc).fetchAll(db)
            guard !days.isEmpty else { return 0 }

            let formatter = DateFormatter.yyyyMMdd
            let today = formatter.string(from: Date())

            var streak = 0
            var currentDate = today

            for day in days {
                if day.date == currentDate {
                    streak += 1
                    if let date = formatter.date(from: currentDate) {
                        currentDate = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: date)!)
                    }
                } else {
                    break
                }
            }

            return streak
        }
    }

    func fetchLongestStreak() throws -> Int {
        try dbQueue.read { db in
            let days = try StudyDay.order(Column("date")).fetchAll(db)
            guard !days.isEmpty else { return 0 }

            let formatter = DateFormatter.yyyyMMdd

            var maxStreak = 0
            var currentStreak = 1

            for i in 1..<days.count {
                guard let prevDate = formatter.date(from: days[i-1].date),
                      let currDate = formatter.date(from: days[i].date) else { continue }

                let dayDiff = Calendar.current.dateComponents([.day], from: prevDate, to: currDate).day ?? 0

                if dayDiff == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            }

            return max(maxStreak, currentStreak)
        }
    }

    func fetchStudyStats() throws -> StudyStats {
        try dbQueue.read { db in
            let formatter = DateFormatter.yyyyMMdd
            let today = formatter.string(from: Date())
            let weekAgo = formatter.string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)

            let answeredToday = try StudyDay.fetchOne(db, key: today)?.questionsAnswered ?? 0

            let answeredThisWeek = try Int.fetchOne(db, sql: """
                SELECT SUM(questionsAnswered) FROM study_days WHERE date >= ?
            """, arguments: [weekAgo]) ?? 0

            let answeredAllTime = try Int.fetchOne(db, sql: """
                SELECT SUM(questionsAnswered) FROM study_days
            """) ?? 0

            let correctAllTime = try Int.fetchOne(db, sql: """
                SELECT SUM(correctAnswers) FROM study_days
            """) ?? 0

            let correctPercentage = answeredAllTime > 0 ? Double(correctAllTime) / Double(answeredAllTime) * 100 : 0

            return StudyStats(answeredToday: answeredToday, answeredThisWeek: answeredThisWeek, answeredAllTime: answeredAllTime, correctPercentage: correctPercentage)
        }
    }
    
    // MARK: - XP Methods
    
    func logXP(_ event: XPEvent) throws {
        try dbQueue.write { db in
            var mutableEvent = event
            try mutableEvent.insert(db)
        }
    }
    
    func fetchTotalXP() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COALESCE(SUM(amount), 0) FROM xp_events") ?? 0
        }
    }
    
    func fetchXPToday() throws -> Int {
        try dbQueue.read { db in
            let today = DateFormatter.yyyyMMdd.string(from: Date())
            return try Int.fetchOne(db, sql: "SELECT COALESCE(SUM(amount), 0) FROM xp_events WHERE date(timestamp) = ?", arguments: [today]) ?? 0
        }
    }
    
    func fetchXPThisWeek() throws -> Int {
        try dbQueue.read { db in
            let weekAgo = DateFormatter.yyyyMMdd.string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
            return try Int.fetchOne(db, sql: "SELECT COALESCE(SUM(amount), 0) FROM xp_events WHERE date(timestamp) >= ?", arguments: [weekAgo]) ?? 0
        }
    }
    
    // MARK: - Achievement Methods
    
    func unlockAchievement(_ achievement: Achievement) throws {
        try dbQueue.write { db in
            var mutableAchievement = achievement
            try mutableAchievement.insert(db)
        }
    }
    
    func fetchAchievements() throws -> [Achievement] {
        try dbQueue.read { db in
            try Achievement.fetchAll(db)
        }
    }
    
    func fetchUnseenAchievements() throws -> [Achievement] {
        try dbQueue.read { db in
            try Achievement.filter(Column("seen") == false).fetchAll(db)
        }
    }
    
    func markAchievementSeen(_ id: String) throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE achievements SET seen = 1 WHERE id = ?", arguments: [id])
        }
    }
    
    func isAchievementUnlocked(_ id: String) throws -> Bool {
        try dbQueue.read { db in
            try Achievement.fetchOne(db, key: id) != nil
        }
    }
    
    // MARK: - Bookmark Methods
    
    func addBookmark(questionId: Int64) throws {
        try dbQueue.write { db in
            var bookmark = Bookmark(questionId: questionId, createdAt: Date())
            try bookmark.insert(db)
        }
    }
    
    func removeBookmark(questionId: Int64) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM bookmarks WHERE questionId = ?", arguments: [questionId])
        }
    }
    
    func isBookmarked(questionId: Int64) throws -> Bool {
        try dbQueue.read { db in
            try Bookmark.fetchOne(db, key: questionId) != nil
        }
    }
    
    func fetchBookmarkedQuestionIds() throws -> [Int64] {
        try dbQueue.read { db in
            try Int64.fetchAll(db, sql: "SELECT questionId FROM bookmarks ORDER BY createdAt DESC")
        }
    }
    
    func fetchBookmarkedQuestions() throws -> [Question] {
        try dbQueue.read { db in
            try Question.fetchAll(db, sql: """
                SELECT q.* FROM questions q
                INNER JOIN bookmarks b ON q.id = b.questionId
                ORDER BY b.createdAt DESC
            """)
        }
    }
    
    // MARK: - Note Methods
    
    func saveNote(_ note: Note) throws {
        try dbQueue.write { db in
            var mutableNote = note
            try mutableNote.insert(db)
        }
    }
    
    func fetchNote(questionId: Int64) throws -> Note? {
        try dbQueue.read { db in
            try Note.fetchOne(db, key: questionId)
        }
    }
    
    func deleteNote(questionId: Int64) throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM notes WHERE questionId = ?", arguments: [questionId])
        }
    }
    
    // MARK: - Search
    
    func searchQuestions(query: String, limit: Int) throws -> [Question] {
        try dbQueue.read { db in
            let pattern = "%\(query)%"
            return try Question.fetchAll(db, sql: """
                SELECT * FROM questions
                WHERE text LIKE ? OR correct LIKE ? OR incorrect0 LIKE ? OR incorrect1 LIKE ? OR incorrect2 LIKE ?
                LIMIT ?
            """, arguments: [pattern, pattern, pattern, pattern, pattern, limit])
        }
    }
    
    func saveQuestionReport(questionId: Int64, reason: String, details: String?) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO question_reports (questionId, reason, details, createdAt) VALUES (?, ?, ?, ?)",
                arguments: [questionId, reason, details, Date()]
            )
        }
    }
    
    // MARK: - Gamification Helpers
    
    func fetchMnemonicCount() throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM mnemonics") ?? 0
        }
    }
    
    func fetchConsecutiveCorrectStreak(limit: Int) throws -> Int {
        try dbQueue.read { db in
            let records = try AnswerRecord.order(Column("timestamp").desc).limit(limit).fetchAll(db)
            var streak = 0
            for record in records {
                if record.isCorrect {
                    streak += 1
                } else {
                    break
                }
            }
            return streak
        }
    }
    
    func fetchTimesWrong(questionId: Int64) throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM answer_records WHERE questionId = ? AND isCorrect = 0", arguments: [questionId]) ?? 0
        }
    }
    
    func fetchSRSCardsAtBoxOrAbove(box: Int, categoryId: Int64) throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM srs_cards s
                INNER JOIN questions q ON s.questionId = q.id
                WHERE s.box >= ? AND q.category = ?
            """, arguments: [box, categoryId]) ?? 0
        }
    }
    
    func fetchTotalSRSCardsForCategory(categoryId: Int64) throws -> Int {
        try dbQueue.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM srs_cards s
                INNER JOIN questions q ON s.questionId = q.id
                WHERE q.category = ?
            """, arguments: [categoryId]) ?? 0
        }
    }
    
    func resetAllProgress() throws {
        try dbQueue.write { db in
            let tables = ["answer_records", "srs_cards", "mnemonics", "mock_exam_results", "study_days", "xp_events", "achievements", "bookmarks", "notes", "quiz_sessions"]
            for table in tables {
                try db.execute(sql: "DELETE FROM \(table)")
            }
        }
    }
    
    // MARK: - Quiz Session Persistence
    
    func saveQuizSession(_ session: QuizSessionState) throws {
        try dbQueue.write { db in
            // Clear any existing session first
            try db.execute(sql: "DELETE FROM quiz_sessions")
            // Save new session
            var mutableSession = session
            try mutableSession.insert(db)
        }
    }
    
    func loadQuizSession() throws -> QuizSessionState? {
        try dbQueue.read { db in
            try QuizSessionState.fetchOne(db)
        }
    }
    
    func clearQuizSession() throws {
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM quiz_sessions")
        }
    }
    
    // MARK: - AI Response Caching
    
    func saveAIResponse(_ cache: AIResponseCache) throws {
        try dbQueue.write { db in
            var mutableCache = cache
            try mutableCache.save(db)
        }
    }
    
    func fetchAIResponse(questionId: Int64, responseType: String) throws -> AIResponseCache? {
        try dbQueue.read { db in
            try AIResponseCache
                .filter(Column("questionId") == questionId && Column("responseType") == responseType)
                .fetchOne(db)
        }
    }
}
