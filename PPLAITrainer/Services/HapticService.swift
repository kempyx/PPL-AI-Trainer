import UIKit

final class HapticService {
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func correctAnswer() {
        fire(.success)
    }
    
    func incorrectAnswer() {
        fire(.error)
    }
    
    func streakMilestone(_ count: Int) {
        if count >= 10 {
            impact(.heavy)
        } else if count >= 5 {
            impact(.medium)
        } else {
            impact(.light)
        }
    }
    
    func levelUp() {
        doubleTap(.heavy)
    }
    
    func badgeUnlock() {
        tripleTap(.medium)
    }
    
    private func fire(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard settingsManager.hapticFeedbackEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settingsManager.hapticFeedbackEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    private func doubleTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settingsManager.hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
    }
    
    private func tripleTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settingsManager.hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred()
            }
        }
    }
}
