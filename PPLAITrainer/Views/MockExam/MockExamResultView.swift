import SwiftUI

struct MockExamResultView: View {
    let result: MockExamResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    Text(result.passed ? "PASSED" : "FAILED")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(result.passed ? .green : .red)
                    
                    Text("\(Int(result.percentage))%")
                        .font(.system(size: 60))
                        .bold()
                    
                    Text("\(result.correctAnswers) / \(result.totalQuestions) correct")
                        .foregroundColor(.gray)
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("Category Breakdown")
                        .font(.headline)
                        .padding(.bottom)
                    
                    if let breakdown = try? JSONDecoder().decode([CategoryExamScore].self, from: result.categoryBreakdown) {
                        ForEach(breakdown, id: \.categoryId) { score in
                            HStack {
                                Text(score.categoryName)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(score.correctAnswers) / \(score.totalQuestions)")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Exam Result")
    }
}
