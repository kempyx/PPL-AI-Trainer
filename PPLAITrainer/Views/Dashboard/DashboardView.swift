import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ReadinessScoreView(
                        score: viewModel.readinessScore,
                        totalQuestions: viewModel.totalQuestions,
                        totalCorrect: viewModel.totalCorrect,
                        stats: viewModel.studyStats
                    )

                    StreakCalendarView(
                        studyDays: viewModel.studyDays,
                        currentStreak: viewModel.currentStreak,
                        longestStreak: viewModel.longestStreak
                    )

                    CategoryProgressGrid(categories: viewModel.categoryProgress)

                    WeakAreasView(weakAreas: viewModel.weakAreas)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}
