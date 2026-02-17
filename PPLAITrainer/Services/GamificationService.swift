import Foundation
import Observation

struct AchievementContext {
    var sessionComplete = false
    var sessionResult: (total: Int, correct: Int)? = nil
    var mockExamPassed = false
    var lastAnsweredQuestionId: Int64? = nil
    var lastAnswerCorrect: Bool? = nil
}

@Observable
final class GamificationService {
    private let databaseManager: DatabaseManaging
    private let settingsManager: SettingsManager
    
    var sessionXP: Int = 0
    var recentlyUnlockedAchievements: [AchievementDefinition] = []
    var didLevelUp: Bool = false
    var previousLevel: PilotLevel?
    private(set) var consecutiveCorrectInSession: Int = 0
    
    init(databaseManager: DatabaseManaging, settingsManager: SettingsManager) {
        self.databaseManager = databaseManager
        self.settingsManager = settingsManager
    }
    
    func awardXP(for correct: Bool, isSRSCard: Bool) throws -> Int {
        let prevTotal = try databaseManager.fetchTotalXP()
        let prevLevel = PilotLevel.level(for: prevTotal)
        
        var earned = 0
        
        // Base XP
        let source: XPSource = correct ? .correctAnswer : .incorrectAnswer
        try databaseManager.logXP(XPEvent(id: nil, amount: source.amount, source: source.rawValue, timestamp: Date()))
        earned += source.amount
        
        // SRS bonus
        if isSRSCard {
            try databaseManager.logXP(XPEvent(id: nil, amount: XPSource.srsBonus.amount, source: XPSource.srsBonus.rawValue, timestamp: Date()))
            earned += XPSource.srsBonus.amount
        }
        
        // Consecutive correct tracking
        if correct {
            consecutiveCorrectInSession += 1
            
            // Streak bonuses at exact thresholds
            if consecutiveCorrectInSession == 3 {
                try databaseManager.logXP(XPEvent(id: nil, amount: XPSource.streakBonus3.amount, source: XPSource.streakBonus3.rawValue, timestamp: Date()))
                earned += XPSource.streakBonus3.amount
            } else if consecutiveCorrectInSession == 5 {
                try databaseManager.logXP(XPEvent(id: nil, amount: XPSource.streakBonus5.amount, source: XPSource.streakBonus5.rawValue, timestamp: Date()))
                earned += XPSource.streakBonus5.amount
            } else if consecutiveCorrectInSession == 10 {
                try databaseManager.logXP(XPEvent(id: nil, amount: XPSource.streakBonus10.amount, source: XPSource.streakBonus10.rawValue, timestamp: Date()))
                earned += XPSource.streakBonus10.amount
            }
        } else {
            consecutiveCorrectInSession = 0
        }
        
        sessionXP += earned
        
        // Level up check
        let newTotal = try databaseManager.fetchTotalXP()
        let newLevel = PilotLevel.level(for: newTotal)
        if newLevel.minXP > prevLevel.minXP {
            didLevelUp = true
            previousLevel = prevLevel
        }
        
        return earned
    }
    
    func awardDailyGoalXP() throws {
        try databaseManager.logXP(XPEvent(id: nil, amount: XPSource.dailyGoalComplete.amount, source: XPSource.dailyGoalComplete.rawValue, timestamp: Date()))
    }
    
    func awardMockExamPassXP() throws {
        try databaseManager.logXP(XPEvent(id: nil, amount: XPSource.mockExamPass.amount, source: XPSource.mockExamPass.rawValue, timestamp: Date()))
    }
    
    func checkAchievements(context: AchievementContext) throws {
        recentlyUnlockedAchievements = []
        
        if context.sessionComplete {
            try tryUnlock(.firstSolo)
        }
        
        let streak = try databaseManager.fetchCurrentStreak()
        if streak >= 7 { try tryUnlock(.ironWill) }
        if streak >= 30 { try tryUnlock(.marathon) }
        
        if consecutiveCorrectInSession >= 10 {
            try tryUnlock(.eagleEye)
        }
        
        if let result = context.sessionResult, result.total >= 20, result.correct == result.total {
            try tryUnlock(.perfectFlight)
        }
        
        if context.mockExamPassed {
            try tryUnlock(.mockMaster)
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 4 { try tryUnlock(.nightOwl) }
        if hour >= 4 && hour < 7 { try tryUnlock(.earlyBird) }
        
        if let qid = context.lastAnsweredQuestionId, context.lastAnswerCorrect == true {
            let wrongCount = try databaseManager.fetchTimesWrong(questionId: qid)
            if wrongCount >= 3 {
                try tryUnlock(.comebackKid)
            }
        }
        
        let mnemonicCount = try databaseManager.fetchMnemonicCount()
        if mnemonicCount >= 10 { try tryUnlock(.askTheInstructor) }
        if mnemonicCount >= 20 { try tryUnlock(.memoryPalace) }
        
        if context.sessionComplete {
            try checkSubjectMastery()
        }
    }
    
    private func checkSubjectMastery() throws {
        let topLevelIds: [Int64] = [500, 501, 528, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560]
        for catId in topLevelIds {
            let total = try databaseManager.fetchTotalSRSCardsForCategory(categoryId: catId)
            let mastered = try databaseManager.fetchSRSCardsAtBoxOrAbove(box: 4, categoryId: catId)
            if total > 0 && mastered == total {
                if let achievement = AchievementDefinition.masteryAchievement(for: catId) {
                    try tryUnlock(achievement)
                }
            }
        }
    }
    
    private func tryUnlock(_ achievement: AchievementDefinition) throws {
        guard try !databaseManager.isAchievementUnlocked(achievement.rawValue) else { return }
        try databaseManager.unlockAchievement(Achievement(id: achievement.rawValue, unlockedAt: Date(), seen: false))
        recentlyUnlockedAchievements.append(achievement)
    }
    
    func resetSession() {
        sessionXP = 0
        consecutiveCorrectInSession = 0
        recentlyUnlockedAchievements = []
        didLevelUp = false
        previousLevel = nil
    }
}
