import SwiftUI

struct RecommendedNextView: View {
    @Environment(\.dependencies) private var dependencies
    let weakAreas: [WeakArea]
    
    var body: some View {
        if let topWeakArea = weakAreas.first, dependencies != nil {
            NavigationLink {
                RecommendedQuizView(categoryId: topWeakArea.id, categoryName: topWeakArea.subcategoryName, accuracy: topWeakArea.correctPercentage)
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                        Text("Recommended Next")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Text("Focus on \(topWeakArea.subcategoryName)")
                        .font(.body)
                    
                    Text("\(Int(topWeakArea.correctPercentage))% accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
    }
}

struct RecommendedQuizView: View {
    @Environment(\.dependencies) private var dependencies
    let categoryId: Int64
    let categoryName: String
    let accuracy: Double
    
    var body: some View {
        if let deps = dependencies {
            let vm = deps.makeQuizViewModel()
            QuizSessionView(viewModel: vm)
                .onAppear {
                    vm.loadQuestions(categoryId: categoryId, parentCategoryId: nil, wrongAnswersOnly: false, srsDueOnly: false)
                }
        }
    }
}
