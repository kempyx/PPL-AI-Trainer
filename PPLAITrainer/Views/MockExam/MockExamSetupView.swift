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
                
                HStack {
                    Text("Questions:")
                    Spacer()
                    Text("\(leg.totalQuestions)")
                        .bold()
                }
                
                HStack {
                    Text("Time Limit:")
                    Spacer()
                    Text("\(leg.timeLimitMinutes) minutes")
                        .bold()
                }
                
                HStack {
                    Text("Pass Mark:")
                    Spacer()
                    Text("75%")
                        .bold()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
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
