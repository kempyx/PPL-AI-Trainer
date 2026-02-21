import SwiftUI

struct QuestionView: View {
    let question: PresentedQuestion
    @Binding var selectedAnswer: Int?
    @Binding var selectedExplainText: String?
    @State private var hasOpenedReferenceFigure = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if shouldShowFocusSteps {
                    focusStepsCard
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Question")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    SelectableTextView(
                        text: question.question.text,
                        font: .preferredFont(forTextStyle: .headline),
                        onSelectionChange: { selected in
                            selectedExplainText = selected
                        }
                    )
                    if let reference = question.question.reference?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !reference.isEmpty {
                        Label(reference, systemImage: "book")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !question.questionAttachments.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Reference Figure")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if !hasOpenedReferenceFigure {
                                Label("Open before submit", systemImage: "eye")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                        }

                        ForEach(Array(question.questionAttachments.enumerated()), id: \.element.id) { index, attachment in
                            if let uiImage = loadBundleUIImage(filename: attachment.filename) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZoomableImageView(uiImage: uiImage) {
                                        hasOpenedReferenceFigure = true
                                    }
                                    Text("Figure \(index + 1). Inspect units, labels, and orientation before selecting an answer.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppCornerRadius.medium))
                }

                if !question.questionAttachments.isEmpty, !hasOpenedReferenceFigure {
                    Label("Open the figure at least once to reduce avoidable chart-reading errors.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.small))
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Answer Choices")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(0..<question.shuffledAnswers.count, id: \.self) { index in
                        Button {
                            selectedAnswer = index
                            selectedExplainText = nil
                        } label: {
                            HStack(spacing: 12) {
                                Text(["A", "B", "C", "D"][index])
                                    .font(.caption.weight(.semibold))
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(selectedAnswer == index ? Color.blue : Color(.systemGray5)))
                                    .foregroundStyle(selectedAnswer == index ? .white : .primary)

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
                        .accessibilityHint("Select option \(["A", "B", "C", "D"][index])")
                    }
                }
            }
            .padding()
        }
    }

    private var shouldShowFocusSteps: Bool {
        !question.questionAttachments.isEmpty || question.question.text.count > 160 || hasDenseTopicKeywords
    }

    private var hasDenseTopicKeywords: Bool {
        let lower = question.question.text.lowercased()
        let keywords = ["metar", "taf", "qnh", "sigwx", "notam", "chart", "pressure", "mass", "balance", "performance", "altitude", "navigation"]
        return keywords.contains(where: { lower.contains($0) })
    }

    private var focusSteps: [String] {
        var steps: [String] = []
        if !question.questionAttachments.isEmpty {
            steps.append("Inspect each reference figure first. Confirm units, labels, and orientation.")
        }
        let lower = question.question.text.lowercased()
        if lower.contains("metar") || lower.contains("taf") || lower.contains("weather") {
            steps.append("Decode weather data in sequence: wind, visibility, cloud, then significant weather.")
        }
        if lower.contains("mass") || lower.contains("balance") || lower.contains("performance") || lower.contains("load factor") {
            steps.append("Write the governing relationship mentally before comparing answer options.")
        }
        steps.append("Restate what is being asked in one phrase before committing to an answer.")
        return Array(steps.prefix(3))
    }

    private var focusStepsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Focus Steps", systemImage: "list.bullet.rectangle.portrait")
                .font(.subheadline.weight(.semibold))
            ForEach(Array(focusSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(step)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium))
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

#Preview {
    let sampleQuestion = Question(
        id: 1,
        category: 551,
        code: "Q1",
        text: "Sample question?",
        correct: "A",
        incorrect0: "B",
        incorrect1: "C",
        incorrect2: "D",
        explanation: "Sample explanation",
        reference: nil,
        attachments: nil,
        mockonly: 0
    )
    let presented = PresentedQuestion(
        question: sampleQuestion,
        shuffledAnswers: ["A", "B", "C", "D"],
        correctAnswerIndex: 0,
        questionAttachments: [],
        explanationAttachments: [],
        categoryName: "Air Law"
    )
    QuestionView(
        question: presented,
        selectedAnswer: .constant(nil),
        selectedExplainText: .constant(nil)
    )
}
