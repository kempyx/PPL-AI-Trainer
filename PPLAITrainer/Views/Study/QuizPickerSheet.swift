import SwiftUI

struct QuizPickerSheet: View {
    let subjectName: String
    let totalQuestions: Int
    let onStart: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCount: QuizCount = .standard
    
    enum QuizCount: Int, CaseIterable {
        case quick = 10
        case standard = 20
        case deep = 50
        case all = -1
        
        var title: String {
            switch self {
            case .quick: return "Quick"
            case .standard: return "Standard"
            case .deep: return "Deep Dive"
            case .all: return "All"
            }
        }
        
        var icon: String {
            switch self {
            case .quick: return "bolt.fill"
            case .standard: return "checkmark.circle.fill"
            case .deep: return "chart.line.uptrend.xyaxis"
            case .all: return "infinity"
            }
        }
        
        var description: String {
            switch self {
            case .quick: return "~3 min"
            case .standard: return "~5 min"
            case .deep: return "~15 min"
            case .all: return "Full review"
            }
        }
        
        func questionCount(total: Int) -> Int {
            self == .all ? total : min(rawValue, total)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(subjectName)
                        .font(.title2.weight(.bold))
                    Text("\(totalQuestions) questions available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                VStack(spacing: 12) {
                    ForEach(QuizCount.allCases, id: \.self) { count in
                        Button {
                            selectedCount = count
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: count.icon)
                                    .font(.title3)
                                    .foregroundColor(selectedCount == count ? .white : .accentColor)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(count.title)
                                        .font(.headline)
                                        .foregroundColor(selectedCount == count ? .white : .primary)
                                    Text("\(count.questionCount(total: totalQuestions)) questions · \(count.description)")
                                        .font(.caption)
                                        .foregroundColor(selectedCount == count ? .white.opacity(0.9) : .secondary)
                                }
                                
                                Spacer()
                                
                                if selectedCount == count {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedCount == count ? Color.accentColor : Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    let count = selectedCount.questionCount(total: totalQuestions)
                    dismiss()
                    onStart(count)
                } label: {
                    Text("Start Quiz")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
