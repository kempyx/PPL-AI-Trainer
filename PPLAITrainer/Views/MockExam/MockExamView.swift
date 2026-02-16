import SwiftUI

struct MockExamView: View {
    @State var viewModel: MockExamViewModel
    @State private var selectedLeg: ExamLeg? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section("Start New Exam") {
                    ForEach(ExamLeg.allCases) { leg in
                        Button {
                            selectedLeg = leg
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(leg.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(leg.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(leg.totalQuestions) questions · \(leg.timeLimitMinutes) min")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if !viewModel.examHistory.isEmpty {
                    Section("History") {
                        ForEach(viewModel.examHistory, id: \.id) { result in
                            NavigationLink {
                                MockExamResultView(result: result)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(result.completedAt, style: .date)
                                            .font(.headline)
                                        Text("\(result.correctAnswers) / \(result.totalQuestions)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text(result.passed ? "PASS" : "FAIL")
                                        .foregroundColor(result.passed ? .green : .red)
                                        .bold()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mock Exam")
            .onAppear { viewModel.loadHistory() }
            .navigationDestination(item: $selectedLeg) { leg in
                MockExamSetupView(viewModel: viewModel, leg: leg)
            }
        }
    }
}
