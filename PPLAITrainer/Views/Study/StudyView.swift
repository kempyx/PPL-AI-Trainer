import SwiftUI

struct StudyView: View {
    @State private var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    
    init(viewModel: StudyViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("SRS Review") {
                    NavigationLink {
                        SRSReviewView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Text("Review Due Cards")
                            Spacer()
                            Text("\(viewModel.dueCardCount)")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if viewModel.hasWrongAnswers {
                    Section("Wrong Answers") {
                        if let deps = deps {
                            NavigationLink("Review Wrong Answers") {
                                QuizSessionView(viewModel: makeWrongAnswersVM(deps))
                            }
                        }
                    }
                }
                
                Section("Browse Categories") {
                    NavigationLink("All Subjects") {
                        CategoryListView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("Study")
            .onAppear {
                viewModel.loadTopLevelCategories()
            }
        }
    }
    
    private func makeWrongAnswersVM(_ deps: Dependencies) -> QuizViewModel {
        let vm = deps.makeQuizViewModel()
        vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: true, srsDueOnly: false)
        return vm
    }
}
