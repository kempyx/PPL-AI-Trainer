import SwiftUI

struct BookmarkedQuestionsView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var bookmarkedQuestions: [Question] = []
    
    var body: some View {
        Group {
            if bookmarkedQuestions.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark",
                    description: Text("Bookmark questions to review them later")
                )
            } else {
                List(bookmarkedQuestions, id: \.id) { question in
                    NavigationLink {
                        QuestionDetailView(question: question)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.text)
                                .font(.body)
                                .lineLimit(2)
                            Text(question.code)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
        .task {
            loadBookmarks()
        }
    }
    
    private func loadBookmarks() {
        guard let deps = dependencies else { return }
        bookmarkedQuestions = (try? deps.databaseManager.fetchBookmarkedQuestions()) ?? []
    }
}
