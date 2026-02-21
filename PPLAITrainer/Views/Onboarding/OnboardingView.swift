import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onComplete: () -> Void
    
    var body: some View {
        TabView(selection: $viewModel.currentPage) {
            WelcomePageView(onContinue: { viewModel.nextPage() })
                .tag(0)
            
            FeatureShowcaseView(onContinue: { viewModel.nextPage() })
                .tag(1)
            
            ExamDatePickerView(
                examDateLeg1: $viewModel.examDateLeg1,
                examDateLeg2: $viewModel.examDateLeg2,
                examDateLeg3: $viewModel.examDateLeg3,
                onContinue: { viewModel.nextPage() }
            )
            .tag(2)
            
            DailyGoalPickerView(
                selectedGoal: $viewModel.dailyGoalTarget,
                recommendedGoal: viewModel.recommendedGoal,
                onContinue: {
                    viewModel.requestNotifications()
                    viewModel.nextPage()
                }
            )
            .tag(3)
            
            OnboardingResultsView(
                percentage: viewModel.baselinePercentage,
                onFinish: {
                    viewModel.completeOnboarding()
                    onComplete()
                }
            )
            .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentPage)
        .ignoresSafeArea()
    }
}
