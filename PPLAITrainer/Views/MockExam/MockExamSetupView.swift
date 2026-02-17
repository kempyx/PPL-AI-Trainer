import SwiftUI

struct MockExamSetupView: View {
    @State var viewModel: MockExamViewModel
    let leg: ExamLeg
    
    var body: some View {
        VStack(spacing: 20) {
            Text(leg.title)
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 10) {
                Text(leg.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                ForEach(leg.subjectQuotas, id: \.name) { subject in
                    HStack {
                        Text(subject.name)
                        Spacer()
                        Text("\(subject.questionCount) q · \(subject.timeMinutes) min")
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                
                Divider()
                
                HStack {
                    Text("Total:")
                    Spacer()
                    Text("\(leg.totalQuestions) questions · \(leg.timeLimitMinutes) min")
                        .bold()
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
            .cornerRadius(14)
            
            Button("Start Exam") {
                viewModel.startExam(leg: leg)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .navigationDestination(isPresented: $viewModel.isExamActive) {
            MockExamSessionView(viewModel: viewModel)
        }
    }
}
