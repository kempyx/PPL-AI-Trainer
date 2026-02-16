import SwiftUI

struct SRSReviewView: View {
    @State var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    
    var body: some View {
        VStack {
            if viewModel.dueCardCount == 0 {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("You're caught up!")
                        .font(.title)
                    
                    Text("Come back later for more reviews")
                        .foregroundColor(.gray)
                }
            } else {
                VStack(spacing: 20) {
                    Text("\(viewModel.dueCardCount) cards due")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    if let deps = deps {
                        NavigationLink("Start Review") {
                            QuizSessionView(viewModel: makeSRSQuizVM(deps))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("SRS Review")
    }
    
    private func makeSRSQuizVM(_ deps: Dependencies) -> QuizViewModel {
        let vm = deps.makeQuizViewModel()
        vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: false, srsDueOnly: true)
        return vm
    }
}
