import SwiftUI

struct OnboardingResultsView: View {
    let percentage: Int
    let onFinish: () -> Void
    
    private var scoreColor: Color {
        if percentage >= 80 { return .green }
        if percentage >= 60 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("You're All Set!")
                .font(.title.weight(.bold))
            
            Text("Your personalized study plan is ready. Let's start learning!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                onFinish()
            } label: {
                Text("Let's Go! 🚀")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

#Preview {
    OnboardingResultsView(
        percentage: 78,
        onFinish: {}
    )
}
