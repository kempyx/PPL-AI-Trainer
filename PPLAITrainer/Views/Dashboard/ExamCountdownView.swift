import SwiftUI

struct ExamCountdownView: View {
    let examDateLeg1: Date?
    let examDateLeg2: Date?
    let examDateLeg3: Date?
    
    private let legLabels = ["Leg 1", "Leg 2", "Leg 3"]
    
    private var legs: [(label: String, days: Int)] {
        let dates = [examDateLeg1, examDateLeg2, examDateLeg3]
        return zip(legLabels, dates).compactMap { label, date in
            guard let date, let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day, days >= 0 else { return nil }
            return (label, days)
        }
    }
    
    var body: some View {
        if !legs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                    Text("Exam Countdown")
                        .font(.subheadline.weight(.semibold))
                }
                
                HStack(spacing: 12) {
                    ForEach(legs, id: \.label) { leg in
                        HStack(spacing: 6) {
                            Text("\(leg.days)")
                                .font(.system(size: 24, weight: .bold).monospacedDigit())
                            VStack(alignment: .leading, spacing: 0) {
                                Text("days")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(leg.label)
                                    .font(.caption2.weight(.medium))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .cornerRadius(14)
        }
    }
}
