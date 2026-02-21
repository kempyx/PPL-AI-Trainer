import SwiftUI
import os

@Observable
class OnboardingViewModel {
    private let databaseManager: DatabaseManaging
    private let settingsManager: SettingsManager
    private let notificationService: NotificationService
    private let logger = Logger(subsystem: "com.pplaitrainer", category: "Onboarding")
    
    var currentPage = 0
    var examDateLeg1: Date? = Calendar.current.date(byAdding: .month, value: 3, to: Date())
    var examDateLeg2: Date? = Calendar.current.date(byAdding: .month, value: 3, to: Date())
    var examDateLeg3: Date? = Calendar.current.date(byAdding: .month, value: 3, to: Date())
    var dailyGoalTarget = 20
    var aiEnabled = false
    var aiProvider = "apple"
    var diagnosticCorrect = 0
    var diagnosticTotal = 0
    var isDiagnosticComplete = false
    
    var recommendedGoal: Int {
        let validDates = [examDateLeg1, examDateLeg2, examDateLeg3].compactMap { $0 }.filter { $0 > Date() }
        guard let nearest = validDates.min() else { return 20 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nearest).day ?? 90
        if days < 30 { return 60 }
        if days < 60 { return 40 }
        return 20
    }
    
    var baselinePercentage: Int {
        guard diagnosticTotal > 0 else { return 0 }
        return Int((Double(diagnosticCorrect) / Double(diagnosticTotal)) * 100)
    }
    
    init(databaseManager: DatabaseManaging, settingsManager: SettingsManager, notificationService: NotificationService) {
        self.databaseManager = databaseManager
        self.settingsManager = settingsManager
        self.notificationService = notificationService
        
        // Set default exam dates only if they're in the future
        let defaultLeg1 = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 13))
        let defaultLeg2 = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 11))
        let defaultLeg3 = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 8))
        
        let now = Date()
        self.examDateLeg1 = defaultLeg1.flatMap { $0 > now ? $0 : nil }
        self.examDateLeg2 = defaultLeg2.flatMap { $0 > now ? $0 : nil }
        self.examDateLeg3 = defaultLeg3.flatMap { $0 > now ? $0 : nil }
    }
    
    func nextPage() {
        currentPage += 1
    }
    
    func requestNotifications() {
        Task {
            _ = await notificationService.requestPermission()
        }
    }
    
    func completeOnboarding() {
        settingsManager.examDateLeg1 = examDateLeg1
        settingsManager.examDateLeg2 = examDateLeg2
        settingsManager.examDateLeg3 = examDateLeg3
        settingsManager.dailyGoalTarget = dailyGoalTarget
        settingsManager.aiEnabled = aiEnabled
        settingsManager.selectedProvider = aiProvider
        settingsManager.hasCompletedOnboarding = true
        
        let validDates = [examDateLeg1, examDateLeg2, examDateLeg3].compactMap { $0 }.filter { $0 > Date() }
        let nearest = validDates.min()
        Task {
            await notificationService.rescheduleAll(
                dueCardCount: 0,
                currentStreak: 0,
                dailyGoalProgress: 0,
                readinessScore: 0,
                daysUntilExam: nearest.flatMap { Calendar.current.dateComponents([.day], from: Date(), to: $0).day }
            )
        }
    }
}
