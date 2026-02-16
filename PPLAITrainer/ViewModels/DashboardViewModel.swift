import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.primendro.PPLAITrainer", category: "DashboardVM")

@Observable
final class DashboardViewModel {
    private let databaseManager: DatabaseManaging

    var readinessScore: Double = 0
    var totalQuestions: Int = 0
    var totalCorrect: Int = 0
    var categoryProgress: [CategoryProgress] = []
    var studyDays: [StudyDay] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var weakAreas: [WeakArea] = []
    var studyStats: StudyStats?

    init(databaseManager: DatabaseManaging) {
        self.databaseManager = databaseManager
    }

    func loadData() {
        Task {
            await loadCategoryProgress()
            await loadStudyDays()
            await loadStreaks()
            await loadWeakAreas()
            await loadStudyStats()
        }
    }

    @MainActor
    private func loadCategoryProgress() async {
        do {
            let categories = try databaseManager.fetchAllTopLevelCategories()
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
                let sortOrder: Int64
            }

            var all: [ProgressEntry] = []

            for entry in standalone {
                all.append(ProgressEntry(
                    id: entry.category.id,
                    name: entry.category.name,
                    totalQuestions: entry.stats.totalQuestions,
                    correctAnswers: entry.stats.correctAnswers,
                    sortOrder: entry.category.sortorder ?? Int64.max
                ))
            }

            for (groupId, members) in grouped {
                let name = groupMap[groupId] ?? members.first?.category.name ?? "Unknown"
                let total = members.reduce(0) { $0 + $1.stats.totalQuestions }
                let correct = members.reduce(0) { $0 + $1.stats.correctAnswers }
                let minSort = members.compactMap(\.category.sortorder).min() ?? Int64.max
                all.append(ProgressEntry(
                    id: groupId,
                    name: name,
                    totalQuestions: total,
                    correctAnswers: correct,
                    sortOrder: minSort
                ))
            }

            all.sort { $0.sortOrder < $1.sortOrder }

            categoryProgress = all.map { entry in
                let pct = entry.totalQuestions > 0 ? Double(entry.correctAnswers) / Double(entry.totalQuestions) * 100 : 0
                return CategoryProgress(id: entry.id, name: entry.name, percentage: pct, totalQuestions: entry.totalQuestions, answeredCorrectly: entry.correctAnswers)
            }

            // Compute readiness from the same data
            let allTotal = all.reduce(0) { $0 + $1.totalQuestions }
            let allCorrect = all.reduce(0) { $0 + $1.correctAnswers }
            totalQuestions = allTotal
            totalCorrect = allCorrect
            readinessScore = allTotal > 0 ? (Double(allCorrect) / Double(allTotal)) * 100 : 0

            logger.info("Loaded \(all.count) category progress entries, readiness: \(self.readinessScore)%")
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
    private func loadWeakAreas() async {
        do {
            let topLevelCategories = try databaseManager.fetchAllTopLevelCategories()
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
