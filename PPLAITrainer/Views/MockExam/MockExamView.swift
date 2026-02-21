import SwiftUI

struct MockExamView: View {
    @State var viewModel: MockExamViewModel
    @State private var showSetup = false

    private var bestScore: Double {
        viewModel.examHistory.map(\.percentage).max() ?? 0
    }

    private var averageScore: Double {
        guard !viewModel.examHistory.isEmpty else { return 0 }
        return viewModel.examHistory.map(\.percentage).reduce(0, +) / Double(viewModel.examHistory.count)
    }
    
    private var activeLeg: ExamLeg {
        viewModel.activeLeg
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showSetup = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(activeLeg.emoji)
                                    .font(.title2)
                                Text(activeLeg.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Text(activeLeg.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(activeLeg.totalQuestions) questions · \(activeLeg.timeLimitMinutes) min")
                                .font(.caption2)
                                .foregroundColor(activeLeg.color)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Start Mock Exam")
                }
                
                if !viewModel.examHistory.isEmpty {
                    Section("Performance") {
                        HStack {
                            Label("Best", systemImage: "trophy.fill")
                            Spacer()
                            Text("\(Int(bestScore))%")
                                .font(.headline)
                        }
                        HStack {
                            Label("Average", systemImage: "chart.line.uptrend.xyaxis")
                            Spacer()
                            Text("\(Int(averageScore))%")
                                .font(.headline)
                        }
                    }

                    Section {
                        MockExamTrendChart(results: viewModel.examHistory)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                    
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text(activeLeg.emoji)
                        Text(activeLeg.shortTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear { viewModel.loadHistory() }
            .onChange(of: viewModel.isExamActive) {
                if !viewModel.isExamActive {
                    showSetup = false
                }
            }
            .navigationDestination(isPresented: $showSetup) {
                MockExamSetupView(viewModel: viewModel, leg: activeLeg)
            }
        }
    }
}
