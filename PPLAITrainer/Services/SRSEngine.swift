import Foundation

final class SRSEngine {
    func processAnswer(card: SRSCard, correct: Bool) -> SRSCard {
        var updated = card
        
        if correct {
            updated.box = min(updated.box + 1, 5)
            
            switch updated.repetitions {
            case 0:
                updated.interval = 1
            case 1:
                updated.interval = 6
            default:
                updated.interval = Int(Double(updated.interval) * updated.easeFactor)
            }
            
            updated.easeFactor = min(updated.easeFactor + 0.1, 3.0)
            updated.repetitions += 1
            updated.nextReviewDate = Calendar.current.date(byAdding: .day, value: updated.interval, to: Date())!
        } else {
            updated.box = 0
            updated.interval = 1
            updated.repetitions = 0
            updated.easeFactor = max(1.3, updated.easeFactor - 0.2)
            updated.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        }
        
        return updated
    }
    
    func maturity(for card: SRSCard) -> SRSMaturity {
        switch card.box {
        case 0, 1:
            return .learning
        case 2, 3:
            return .review
        case 4...:
            return .mastered
        default:
            return .new
        }
    }
}
