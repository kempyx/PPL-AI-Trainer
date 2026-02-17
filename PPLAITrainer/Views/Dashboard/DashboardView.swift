import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // HERO SECTION: Status & Action
                    ReadinessScoreView(
                        score: viewModel.readinessScore,
                        totalQuestions: viewModel.totalQuestions,
                        totalCorrect: viewModel.totalCorrect,
                        stats: viewModel.studyStats
                    )
                    .staggeredFadeIn(index: 0)
                    
                    ContinueStudyingCard()
                        .staggeredFadeIn(index: 1)
                    
                    RecommendedNextView(weakAreas: viewModel.weakAreas)
                        .staggeredFadeIn(index: 2)
                    
                    // HABIT SECTION: Daily Engagement
                    DailyGoalView(
                        answeredToday: viewModel.answeredToday,
                        target: viewModel.dailyGoalTarget
                    )
                    .staggeredFadeIn(index: 3)
                    
                    StreakCalendarView(
                        studyDays: viewModel.studyDays,
                        currentStreak: viewModel.currentStreak,
                        longestStreak: viewModel.longestStreak
                    )
                    .staggeredFadeIn(index: 4)
                    
                    // STATUS SECTION: Background Info
                    ExamCountdownView(
                        examDateLeg1: viewModel.examDateLeg1,
                        examDateLeg2: viewModel.examDateLeg2,
                        examDateLeg3: viewModel.examDateLeg3
                    )
                    .staggeredFadeIn(index: 5)
                    
                    XPBarView(
                        totalXP: viewModel.totalXP,
                        currentLevel: viewModel.currentLevel,
                        progress: viewModel.xpProgress
                    )
                    .staggeredFadeIn(index: 6)
                    
                    CategoryProgressGrid(categories: viewModel.categoryProgress)
                        .staggeredFadeIn(index: 7)
                    
                    WeakAreasView(weakAreas: viewModel.weakAreas)
                        .staggeredFadeIn(index: 8)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.loadData()
            }
            .overlay {
                if viewModel.answeredToday >= viewModel.dailyGoalTarget && viewModel.dailyGoalTarget > 0 {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
