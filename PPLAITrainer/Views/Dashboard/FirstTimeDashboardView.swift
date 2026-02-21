import SwiftUI

struct FirstTimeDashboardView: View {
    @Environment(\.dependencies) private var deps
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "airplane.departure")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Text("Welcome to PPL AI Trainer!")
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text("Start your first quiz to begin tracking your progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            if let deps = deps {
                NavigationLink {
                    StudyView(viewModel: StudyViewModel(databaseManager: deps.databaseManager))
                } label: {
                    Text("Start Your First Quiz")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    FirstTimeDashboardView()
}
