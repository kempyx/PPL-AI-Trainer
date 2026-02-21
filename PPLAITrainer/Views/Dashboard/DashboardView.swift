import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @AppStorage("dashboardProgressExpanded") private var progressExpanded = true
    @AppStorage("dashboardStreaksExpanded") private var streaksExpanded = true

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            if let stats = viewModel.studyStats, stats.answeredAllTime < 10 {
                FirstTimeDashboardView()
            } else {
                dashboardContent
            }
        }
    }
    
    private var dashboardContent: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // ACTION ZONE (always visible)
                    ReadinessScoreView(
                        score: viewModel.readinessScore,
                        totalQuestions: viewModel.totalQuestions,
                        totalCorrect: viewModel.totalCorrect,
                        stats: viewModel.studyStats
                    )
                    .staggeredFadeIn(index: 0)
                    
                    NextUpCard()
                        .staggeredFadeIn(index: 1)
                    
                    DailyGoalView(
                        answeredToday: viewModel.answeredToday,
                        target: viewModel.dailyGoalTarget
                    )
                    .staggeredFadeIn(index: 2)
                    
                    // PROGRESS (collapsible)
                    DisclosureGroup(isExpanded: $progressExpanded) {
                        VStack(spacing: 20) {
                            CategoryProgressGrid(categories: viewModel.categoryProgress)
                            WeakAreasView(weakAreas: viewModel.weakAreas)
                        }
                        .padding(.top, 12)
                    } label: {
                        Label("Progress", systemImage: "chart.bar.fill")
                            .font(.headline)
                    }
                    .cardStyle()
                    .staggeredFadeIn(index: 3)
                    
                    // STREAKS & STATS (collapsible)
                    DisclosureGroup(isExpanded: $streaksExpanded) {
                        VStack(spacing: 20) {
                            StreakCalendarView(
                                studyDays: viewModel.studyDays,
                                currentStreak: viewModel.currentStreak,
                                longestStreak: viewModel.longestStreak
                            )
                            
                            ExamCountdownView(
                                examDateLeg1: viewModel.examDateLeg1,
                                examDateLeg2: viewModel.examDateLeg2,
                                examDateLeg3: viewModel.examDateLeg3
                            )
                            
                            XPBarView(
                                totalXP: viewModel.totalXP,
                                currentLevel: viewModel.currentLevel,
                                progress: viewModel.xpProgress
                            )
                        }
                        .padding(.top, 12)
                    } label: {
                        Label("Streaks & Stats", systemImage: "flame.fill")
                            .font(.headline)
                    }
                    .cardStyle()
                    .staggeredFadeIn(index: 4)
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
