import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.primendro.PPLAITrainer", category: "DashboardVM")

@Observable
final class DashboardViewModel {
    private let databaseManager: DatabaseManaging
    private let settingsManager: SettingsManager

    var readinessScore: Double = 0
    var totalQuestions: Int = 0
    var totalCorrect: Int = 0
    var categoryProgress: [CategoryProgress] = []
    var studyDays: [StudyDay] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var weakAreas: [WeakArea] = []
    var studyStats: StudyStats?
    var totalXP: Int = 0
    var currentLevel: PilotLevel = PilotLevel.allLevels[0]
    var xpProgress: Double = 0
    var dailyGoalTarget: Int = 20
    var answeredToday: Int = 0
    var examDateLeg1: Date?
    var examDateLeg2: Date?
    var examDateLeg3: Date?

    init(databaseManager: DatabaseManaging, settingsManager: SettingsManager) {
        self.databaseManager = databaseManager
        self.settingsManager = settingsManager
    }

    func loadData() {
        let activeLeg = settingsManager.activeLeg
        examDateLeg1 = settingsManager.examDateLeg1
        examDateLeg2 = settingsManager.examDateLeg2
        examDateLeg3 = settingsManager.examDateLeg3
        dailyGoalTarget = settingsManager.dailyGoalTarget
        Task {
            await loadCategoryProgress(leg: activeLeg)
            await loadStudyDays()
            await loadStreaks()
            await loadWeakAreas(leg: activeLeg)
            await loadStudyStats()
            await loadXPData()
            await loadDailyGoal()
        }
    }
    
    @MainActor
    private func loadDailyGoal() async {
        do {
            let formatter = DateFormatter.yyyyMMdd
            let today = formatter.string(from: Date())
            if let studyDay = try databaseManager.fetchStudyDays(from: today, to: today).first {
                answeredToday = studyDay.questionsAnswered
            }
        } catch {
            logger.error("Failed to load daily goal: \(error)")
        }
    }
    
    @MainActor
    private func loadXPData() async {
        do {
            totalXP = try databaseManager.fetchTotalXP()
            currentLevel = PilotLevel.level(for: totalXP)
            xpProgress = PilotLevel.progressToNext(xp: totalXP)
        } catch {
            logger.error("Failed to load XP data: \(error)")
        }
    }

    @MainActor
    private func loadCategoryProgress(leg: ExamLeg) async {
        do {
            let legCategoryIds = Set(leg.parentCategoryIds)
            let categories = try databaseManager.fetchAllTopLevelCategories()
                .filter { legCategoryIds.contains($0.id) }
            let groups = try databaseManager.fetchCategoryGroups()
            let groupMap = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0.name) })

            struct CatEntry {
                let category: Category
                let stats: CategoryStat
            }

            let entries: [CatEntry] = try categories.map { category in
                let stats = try databaseManager.fetchAggregatedCategoryStats(parentId: category.id)
                return CatEntry(category: category, stats: stats)
            }

            var grouped: [Int64: [CatEntry]] = [:]
            var standalone: [CatEntry] = []
            for entry in entries {
                if let gid = entry.category.categorygroup {
                    grouped[gid, default: []].append(entry)
                } else {
                    standalone.append(entry)
                }
            }

            struct ProgressEntry {
                let id: Int64
                let name: String
                let totalQuestions: Int
                let correctAnswers: Int
                let answeredQuestions: Int
                let sortOrder: Int64
            }

            var all: [ProgressEntry] = []

            for entry in standalone {
                all.append(ProgressEntry(
                    id: entry.category.id,
                    name: entry.category.name,
                    totalQuestions: entry.stats.totalQuestions,
                    correctAnswers: entry.stats.correctAnswers,
                    answeredQuestions: entry.stats.answeredQuestions,
                    sortOrder: entry.category.sortorder ?? Int64.max
                ))
            }

            for (groupId, members) in grouped {
                let name = groupMap[groupId] ?? members.first?.category.name ?? "Unknown"
                let total = members.reduce(0) { $0 + $1.stats.totalQuestions }
                let correct = members.reduce(0) { $0 + $1.stats.correctAnswers }
                let answered = members.reduce(0) { $0 + $1.stats.answeredQuestions }
                let minSort = members.compactMap(\.category.sortorder).min() ?? Int64.max
                all.append(ProgressEntry(
                    id: groupId,
                    name: name,
                    totalQuestions: total,
                    correctAnswers: correct,
                    answeredQuestions: answered,
                    sortOrder: minSort
                ))
            }

            all.sort { $0.sortOrder < $1.sortOrder }

            categoryProgress = all.map { entry in
                let pct = entry.totalQuestions > 0 ? Double(entry.correctAnswers) / Double(entry.totalQuestions) * 100 : 0
                let incorrect = entry.answeredQuestions - entry.correctAnswers
                return CategoryProgress(
                    id: entry.id,
                    name: entry.name,
                    percentage: pct,
                    totalQuestions: entry.totalQuestions,
                    answeredCorrectly: entry.correctAnswers,
                    answeredIncorrectly: incorrect
                )
            }

            // Compute readiness based on SRS mastery (box 3+)
            // Box 3+ indicates questions successfully recalled multiple times with spaced intervals
            // Research shows this predicts 90%+ retention, the gold standard for mastery learning
            var masteredCount = 0
            for entry in entries {
                let mastered = try databaseManager.fetchSRSCardsAtBoxOrAbove(box: 3, categoryId: entry.category.id)
                masteredCount += mastered
            }
            
            totalQuestions = masteredCount
            totalCorrect = masteredCount
            // Calculate readiness as percentage of 60-question exam coverage
            // If you've mastered 45 questions, you're 75% ready (45/60)
            readinessScore = min(Double(masteredCount) / 60.0 * 100, 100)

            logger.info("Loaded \(all.count) category progress entries, \(masteredCount) questions mastered (SRS box 3+), readiness: \(Int(self.readinessScore))%")
        } catch {
            logger.error("Failed to load category progress: \(error)")
            categoryProgress = []
            readinessScore = 0
        }
    }

    @MainActor
    private func loadStudyDays() async {
        do {
            let formatter = DateFormatter.yyyyMMdd
            let to = formatter.string(from: Date())
            let from = formatter.string(from: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
            studyDays = try databaseManager.fetchStudyDays(from: from, to: to)
        } catch {
            studyDays = []
        }
    }

    @MainActor
    private func loadStreaks() async {
        do {
            currentStreak = try databaseManager.fetchCurrentStreak()
            longestStreak = try databaseManager.fetchLongestStreak()
        } catch {
            currentStreak = 0
            longestStreak = 0
        }
    }

    @MainActor
    private func loadWeakAreas(leg: ExamLeg) async {
        do {
            let legCategoryIds = Set(leg.parentCategoryIds)
            let topLevelCategories = try databaseManager.fetchAllTopLevelCategories()
                .filter { legCategoryIds.contains($0.id) }
            let groups = try databaseManager.fetchCategoryGroups()
            let groupMap = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0.name) })
            var areas: [WeakArea] = []

            for parent in topLevelCategories {
                let parentDisplayName: String
                if let gid = parent.categorygroup, let groupName = groupMap[gid] {
                    parentDisplayName = groupName
                } else {
                    parentDisplayName = parent.name
                }
                let subcategories = try databaseManager.fetchSubcategories(parentId: parent.id)
                for sub in subcategories {
                    let stats = try databaseManager.fetchCategoryStats(categoryId: sub.id)
                    if stats.answeredQuestions > 0 {
                        let percentage = Double(stats.correctAnswers) / Double(stats.answeredQuestions) * 100
                        areas.append(WeakArea(id: sub.id, subcategoryName: sub.name, parentCategoryName: parentDisplayName, correctPercentage: percentage, totalAnswered: stats.answeredQuestions))
                    }
                }
            }

            weakAreas = areas.sorted { $0.correctPercentage < $1.correctPercentage }.prefix(5).map { $0 }
        } catch {
            weakAreas = []
        }
    }

    @MainActor
    private func loadStudyStats() async {
        do {
            studyStats = try databaseManager.fetchStudyStats()
        } catch {
            studyStats = nil
        }
    }
}
