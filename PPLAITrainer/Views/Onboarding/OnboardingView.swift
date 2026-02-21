import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onComplete: () -> Void
    
    private let totalPages = 5
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: Double(viewModel.currentPage + 1), total: Double(totalPages))
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 8)
            
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
                onContinue: { viewModel.nextPage() }
            )
            .tag(3)

            AISetupPageView(
                aiEnabled: $viewModel.aiEnabled,
                selectedProvider: $viewModel.aiProvider,
                onContinue: {
                    viewModel.requestNotifications()
                    viewModel.completeOnboarding()
                    onComplete()
                }
            )
            .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentPage)
        }
        .ignoresSafeArea()
    }
}
