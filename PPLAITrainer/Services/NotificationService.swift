import UserNotifications
import Foundation

final class NotificationService {
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func rescheduleAll(dueCardCount: Int, currentStreak: Int, dailyGoalProgress: Double, readinessScore: Double, daysUntilExam: Int?) async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard settingsManager.notificationsEnabled else { return }
        
        scheduleDailyReviewReminder(dueCardCount: dueCardCount)
        
        if settingsManager.streakReminderEnabled && currentStreak > 0 {
            scheduleStreakProtection(currentStreak: currentStreak)
        }
        
        if dailyGoalProgress < 0.5 {
            scheduleDailyGoalNudge(progress: dailyGoalProgress)
        }
        
        if let days = daysUntilExam {
            scheduleExamCountdown(daysUntilExam: days)
        }
    }
    
    private func scheduleDailyReviewReminder(dueCardCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily PPL Review"
        content.body = dueCardCount > 0
            ? "You have \(dueCardCount) due card\(dueCardCount == 1 ? "" : "s"). A 10-minute review keeps retention high."
            : "No due cards yet. Run a quick weak-area drill to stay exam-ready."
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: settingsManager.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily_review", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleStreakProtection(currentStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Study Rhythm"
        content.body = "You're on a \(currentStreak)-day run. A short session today protects recall before exam day."
        content.sound = .default
        
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streak_protection", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleDailyGoalNudge(progress: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Progress Update"
        content.body = "You're \(Int(progress * 100))% of today's goal. Finish with a focused quiz set."
        content.sound = .default
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "daily_goal_nudge", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleExamCountdown(daysUntilExam: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Exam Countdown"
        content.body = "\(daysUntilExam) day\(daysUntilExam == 1 ? "" : "s") until your exam. Prioritize weak subjects this week."
        content.sound = .default
        
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 10
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "exam_countdown", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
