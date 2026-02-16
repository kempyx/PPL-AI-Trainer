import SwiftUI

struct ResultView: View {
    @State var viewModel: QuizViewModel
    let question: PresentedQuestion
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(0..<question.shuffledAnswers.count, id: \.self) { index in
                    HStack {
                        Text(question.shuffledAnswers[index])
                        Spacer()
                        if index == question.correctAnswerIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if index == viewModel.selectedAnswer {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(index == question.correctAnswerIndex ? Color.green.opacity(0.1) : (index == viewModel.selectedAnswer ? Color.red.opacity(0.1) : Color.clear))
                    .cornerRadius(8)
                }
                
                if let explanation = question.question.explanation, !explanation.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Explanation")
                            .font(.headline)
                        Text(explanation)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
                    Text("No explanation available.")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                ForEach(question.explanationAttachments, id: \.id) { attachment in
                    if let image = loadBundleImage(filename: attachment.filename) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                }
                
                if let mnemonic = viewModel.aiMnemonic {
                    VStack(alignment: .leading) {
                        Text("Mnemonic")
                            .font(.headline)
                        Text(mnemonic)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Button("Next Question") {
                    viewModel.nextQuestion()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private func loadBundleImage(filename: String) -> Image? {
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension
        guard let path = Bundle.main.path(forResource: name, ofType: ext),
              let uiImage = UIImage(contentsOfFile: path) else { return nil }
        return Image(uiImage: uiImage)
    }
}
