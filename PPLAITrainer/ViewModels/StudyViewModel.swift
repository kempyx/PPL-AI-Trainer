import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.primendro.PPLAITrainer", category: "StudyVM")

@Observable
final class StudyViewModel {
    private let databaseManager: DatabaseManaging
    private let settingsManager: SettingsManager
    
    var topLevelCategories: [CategoryWithStats] = []
    var displayCategories: [DisplayCategory] = []
    var subcategories: [CategoryWithStats] = []
    var dueCardCount: Int = 0
    var hasWrongAnswers: Bool = false
    
    init(databaseManager: DatabaseManaging, settingsManager: SettingsManager = SettingsManager()) {
        self.databaseManager = databaseManager
        self.settingsManager = settingsManager
    }
    
    func loadTopLevelCategories() {
        Task {
            await loadCategories()
            await loadDueCardCount()
            await loadWrongAnswersStatus()
        }
    }
    
    func loadSubcategories(parentId: Int64) {
        Task {
            await loadSubcategoriesForParent(parentId: parentId)
        }
    }
    
    @MainActor
    private func loadCategories() async {
        do {
            let showPremiumContent = settingsManager.showPremiumContent
            let categories = try databaseManager.fetchAllTopLevelCategories()
                .filter { showPremiumContent || !$0.isLocked }

            let categoryStats = try categories.map { category in
                let stats = try databaseManager.fetchAggregatedCategoryStats(parentId: category.id)
                let srsStats = try databaseManager.fetchAggregatedSRSStats(parentId: category.id)
                let subCount = try databaseManager.fetchSubcategoryCount(parentId: category.id)
                return CategoryWithStats(category: category, stats: stats, srsStats: srsStats, subcategoryCount: subCount)
            }
            topLevelCategories = categoryStats.filter { $0.stats.totalQuestions > 0 }
            let hiddenEmptyCount = categoryStats.count - topLevelCategories.count
            logger.info("Fetched \(categories.count) top-level categories, hid \(hiddenEmptyCount) with zero questions")

            // Build grouped display categories using category_groups table
            let groups = try databaseManager.fetchCategoryGroups()
            let groupMap = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0.name) })

            // Bucket top-level categories by their categorygroup
            var grouped: [Int64: [CategoryWithStats]] = [:]
            var standalone: [CategoryWithStats] = []
            for item in topLevelCategories {
                if let gid = item.category.categorygroup {
                    grouped[gid, default: []].append(item)
                } else {
                    standalone.append(item)
                }
            }

            var result: [DisplayCategory] = []

            // Standalone categories (no group)
            for item in standalone {
                result.append(DisplayCategory(
                    id: "cat-\(item.category.id)",
                    name: item.category.name,
                    memberCategories: [item],
                    stats: item.stats,
                    srsStats: item.srsStats,
                    subcategoryCount: item.subcategoryCount
                ))
            }

            // Grouped categories
            for (groupId, members) in grouped {
                let name = groupMap[groupId] ?? members.first?.category.name ?? "Unknown"
                let totalQuestions = members.reduce(0) { $0 + $1.stats.totalQuestions }
                let answeredQuestions = members.reduce(0) { $0 + $1.stats.answeredQuestions }
                let correctAnswers = members.reduce(0) { $0 + $1.stats.correctAnswers }
                let subCount = members.reduce(0) { $0 + $1.subcategoryCount }
                let srs = SRSStats(
                    newCount: members.reduce(0) { $0 + $1.srsStats.newCount },
                    learningCount: members.reduce(0) { $0 + $1.srsStats.learningCount },
                    reviewCount: members.reduce(0) { $0 + $1.srsStats.reviewCount },
                    masteredCount: members.reduce(0) { $0 + $1.srsStats.masteredCount }
                )
                let combinedStats = CategoryStat(
                    categoryId: groupId,
                    categoryName: name,
                    totalQuestions: totalQuestions,
                    answeredQuestions: answeredQuestions,
                    correctAnswers: correctAnswers
                )
                result.append(DisplayCategory(
                    id: "group-\(groupId)",
                    name: name,
                    memberCategories: members.sorted { ($0.category.sortorder ?? 0) < ($1.category.sortorder ?? 0) },
                    stats: combinedStats,
                    srsStats: srs,
                    subcategoryCount: subCount
                ))
            }

            // Sort by the minimum sortorder of member categories
            result.sort { a, b in
                let aOrder = a.memberCategories.compactMap(\.category.sortorder).min() ?? Int64.max
                let bOrder = b.memberCategories.compactMap(\.category.sortorder).min() ?? Int64.max
                return aOrder < bOrder
            }

            displayCategories = result
            logger.info("Built \(result.count) display categories (\(standalone.count) standalone, \(grouped.count) groups)")
        } catch {
            logger.error("Failed to load categories: \(error)")
            topLevelCategories = []
            displayCategories = []
        }
    }
    
    @MainActor
    private func loadSubcategoriesForParent(parentId: Int64) async {
        do {
            let showPremiumContent = settingsManager.showPremiumContent
            let categories = try databaseManager.fetchSubcategories(parentId: parentId)
                .filter { showPremiumContent || !$0.isLocked }

            let subcategoryStats = try categories.map { category in
                let stats = try databaseManager.fetchCategoryStats(categoryId: category.id)
                let srsStats = try databaseManager.fetchSRSStats(categoryId: category.id)
                return CategoryWithStats(category: category, stats: stats, srsStats: srsStats)
            }
            subcategories = subcategoryStats.filter { $0.stats.totalQuestions > 0 }
            let hiddenEmptyCount = subcategoryStats.count - subcategories.count
            logger.info("Fetched \(categories.count) subcategories for parent \(parentId), hid \(hiddenEmptyCount) with zero questions")
        } catch {
            logger.error("Failed to load subcategories for parent \(parentId): \(error)")
            subcategories = []
        }
    }
    
    @MainActor
    private func loadDueCardCount() async {
        do {
            let cards = try databaseManager.fetchDueCards(limit: nil)
            dueCardCount = cards.count
        } catch {
            dueCardCount = 0
        }
    }
    
    @MainActor
    private func loadWrongAnswersStatus() async {
        do {
            hasWrongAnswers = try databaseManager.hasIncorrectAnswers()
        } catch {
            hasWrongAnswers = false
        }
    }
}
