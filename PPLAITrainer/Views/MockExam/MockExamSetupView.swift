import SwiftUI

struct MockExamSetupView: View {
    @State var viewModel: MockExamViewModel
    let leg: ExamLeg
    @State private var isPracticeMode = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(leg.title)
                .font(.largeTitle)
                .bold()
            
            Picker("Mode", selection: $isPracticeMode) {
                Text("Timed Exam").tag(false)
                Text("Practice").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                if isPracticeMode {
                    Text("Practice mode: No timer, feedback after each question")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(leg.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                ForEach(leg.subjectQuotas, id: \.name) { subject in
                    HStack {
                        Text(subject.name)
                        Spacer()
                        if isPracticeMode {
                            Text("\(subject.questionCount) questions")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(subject.questionCount) q · \(subject.timeMinutes) min")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
                
                Divider()
                
                HStack {
                    Text("Total:")
                    Spacer()
                    if isPracticeMode {
                        Text("\(leg.totalQuestions) questions")
                            .bold()
                    } else {
                        Text("\(leg.totalQuestions) questions · \(leg.timeLimitMinutes) min")
                            .bold()
                    }
                }
                
                HStack {
                    Text("Pass Mark:")
                    Spacer()
                    Text("75% (15/20 per subject)")
                        .bold()
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(AppCornerRadius.medium)
            
            Button(isPracticeMode ? "Start Practice" : "Start Exam") {
                viewModel.startExam(leg: leg, practiceMode: isPracticeMode)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .navigationDestination(isPresented: $viewModel.isExamActive) {
            MockExamSessionView(viewModel: viewModel)
        }
    }
}
