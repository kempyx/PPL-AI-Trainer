import AudioToolbox
import Foundation

final class SoundService {
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func correctAnswer() {
        play(1057)
    }
    
    func incorrectAnswer() {
        play(1073)
    }
    
    func levelUp() {
        play(1025)
    }
    
    func badgeUnlock() {
        play(1026)
    }
    
    func goalComplete() {
        play(1028)
    }
    
    private func play(_ soundID: SystemSoundID) {
        guard settingsManager.soundEnabled else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}
