import SwiftUI

struct DailyGoalPickerView: View {
    @Binding var selectedGoal: Int
    let recommendedGoal: Int
    let onContinue: () -> Void
    
    private let goals = [20, 40, 60]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Daily Study Goal")
                .font(.title.weight(.bold))
            
            Text("How many questions per day?")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(goals, id: \.self) { goal in
                    Button {
                        selectedGoal = goal
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(goal) questions")
                                    .font(.headline)
                                Text(goalLabel(goal))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if goal == recommendedGoal {
                                Text("Recommended")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            Image(systemName: selectedGoal == goal ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedGoal == goal ? .blue : .gray)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedGoal == goal ? Color.blue : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
    
    private func goalLabel(_ goal: Int) -> String {
        switch goal {
        case 20: return "~10 min/day • Casual"
        case 40: return "~20 min/day • Steady"
        case 60: return "~30 min/day • Intensive"
        default: return ""
        }
    }
}
