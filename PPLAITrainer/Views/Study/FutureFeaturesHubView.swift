import SwiftUI

struct FutureFeaturesHubView: View {
    @AppStorage("leaderboardOptIn") private var leaderboardOptIn = false
    @Environment(\.dependencies) private var deps

    var body: some View {
        List {
            Section("NEW-5 Weekly Plan") {
                Text("Mon/Wed/Fri: 20-question mixed review. Tue/Thu: weak areas. Weekend: mock exam + recap.")
                    .font(.subheadline)
            }

            Section("NEW-6 Leaderboards") {
                Toggle("Opt in to anonymous leaderboard", isOn: $leaderboardOptIn)
            }

            Section("NEW-7 Annotations") {
                Text("Use Notes on any question from Result view to highlight key takeaways.")
            }

            Section("NEW-8 Quick Review") {
                NavigationLink("Start Rapid 3-second Flashcards") {
                    FlashcardView(sessionType: .quickReview)
                }
            }

            Section("NEW-9 Diagram Annotation") {
                Text("Zoom + screenshot supported for diagram questions. Save notes with each question.")
            }

            Section("NEW-10 Export") {
                ShareLink(item: exportSummary) {
                    Label("Share Progress Summary", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Study Lab")
    }

    private var exportSummary: String {
        let goal = deps?.settingsManager.dailyGoalTarget ?? 20
        return "PPLAITrainer summary: Daily goal \(goal), leaderboard opt-in: \(leaderboardOptIn ? "Yes" : "No")."
    }
}

#Preview {
    FutureFeaturesHubView()
}
