import AVFoundation

final class TextToSpeechService {
    private let synthesizer = AVSpeechSynthesizer()
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
    
    func speak(_ text: String) {
        // Strip markdown for better speech
        let cleanText = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "###", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
        
        let utterance = AVSpeechUtterance(string: cleanText)
        
        // Use enhanced voice if available (sounds more natural)
        if let voice = AVSpeechSynthesisVoice(language: "en-GB") {
            utterance.voice = voice
        }
        
        utterance.rate = 0.52 // Slightly faster than default 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
