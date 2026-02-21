import SwiftUI

struct QuestionOfTheDayView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var question: Question?
    
    var body: some View {
        if let question {
            NavigationLink {
                QuestionDetailView(question: question)
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Question of the Day")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Text(question.text)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(.primary)
                    
                    Text(question.code)
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

#Preview {
    QuestionOfTheDayView()
        .environment(\.dependencies, Dependencies.preview)
}
