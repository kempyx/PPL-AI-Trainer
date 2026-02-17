import SwiftUI

struct ContinueStudyingCard: View {
    @Environment(\.dependencies) private var deps
    
    var body: some View {
        Group {
            if let deps = deps,
               let subjectId = deps.settingsManager.lastStudiedSubjectId,
               let subjectName = deps.settingsManager.lastStudiedSubjectName {
                NavigationLink {
                    SubcategoryListView(
                        viewModel: StudyViewModel(databaseManager: deps.databaseManager),
                        parentId: subjectId,
                        parentName: subjectName
                    )
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Continue Studying")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                            Text(subjectName)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
