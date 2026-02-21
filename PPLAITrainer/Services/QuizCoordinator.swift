import Foundation

struct QuizCoordinator {
    enum LaunchMode {
        case category(categoryId: Int64?, parentCategoryId: Int64?)
        case wrongAnswers
        case srsDue
        case preloaded([Question])
    }

    let dependencies: Dependencies

    func makeViewModel(mode: LaunchMode) -> QuizViewModel {
        let vm = dependencies.makeQuizViewModel()
        switch mode {
        case .category(let categoryId, let parentCategoryId):
            vm.loadQuestions(categoryId: categoryId, parentCategoryId: parentCategoryId, wrongAnswersOnly: false, srsDueOnly: false)
        case .wrongAnswers:
            vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: true, srsDueOnly: false)
        case .srsDue:
            vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: false, srsDueOnly: true)
        case .preloaded(let questions):
            vm.loadQuestions(from: questions)
        }
        return vm
    }
}
