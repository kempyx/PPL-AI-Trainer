import SwiftUI

struct QuestionView: View {
    let question: PresentedQuestion
    @Binding var selectedAnswer: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(question.question.text)
                    .font(.headline)
                    .textSelection(.enabled)
                    .padding()

                ForEach(question.questionAttachments, id: \.id) { attachment in
                    if let uiImage = loadBundleUIImage(filename: attachment.filename) {
                        ZoomableImageView(uiImage: uiImage)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)

                ForEach(0..<question.shuffledAnswers.count, id: \.self) { index in
                    Button {
                        selectedAnswer = index
                    } label: {
                        HStack {
                            Text(question.shuffledAnswers[index])
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            Spacer()
                            if selectedAnswer == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(selectedAnswer == index ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                        .cornerRadius(AppCornerRadius.small)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func loadBundleUIImage(filename: String) -> UIImage? {
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension
        guard let path = Bundle.main.path(forResource: name, ofType: ext),
              let uiImage = UIImage(contentsOfFile: path) else { return nil }
        return uiImage
    }
}
