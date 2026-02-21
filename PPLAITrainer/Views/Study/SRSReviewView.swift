import SwiftUI

struct SRSReviewView: View {
    @State var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.dueCardCount == 0 {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("You're caught up!")
                        .font(.title)
                    
                    Text("Come back later for more reviews")
                        .foregroundColor(.secondary)
                    
                    if let nextReview = nextReviewDate() {
                        Text("Next review: \(nextReview, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("\(viewModel.dueCardCount) cards due")
                        .font(.title2)
                    
                    Text("Estimated time: ~\(estimatedMinutes()) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let deps = deps {
                        NavigationLink("Start Review") {
                            QuizSessionView(viewModel: makeSRSQuizVM(deps))
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("SRS Review")
    }
    
    private func makeSRSQuizVM(_ deps: Dependencies) -> QuizViewModel {
        let vm = deps.makeQuizViewModel()
        vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: false, srsDueOnly: true)
        return vm
    }
    
    private func estimatedMinutes() -> Int {
        return max(1, viewModel.dueCardCount / 4)
    }
    
    private func nextReviewDate() -> Date? {
        guard let deps = deps else { return nil }
        return try? deps.databaseManager.fetchNextReviewDate()
    }
}
