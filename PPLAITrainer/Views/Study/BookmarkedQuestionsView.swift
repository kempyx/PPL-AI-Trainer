import SwiftUI

struct BookmarkedQuestionsView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var bookmarkedQuestions: [Question] = []
    @State private var showQuizSheet = false
    
    var body: some View {
        Group {
            if bookmarkedQuestions.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark",
                    description: Text("Bookmark questions to review them later")
                )
            } else {
                List {
                    ForEach(bookmarkedQuestions, id: \.id) { question in
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
                    .onDelete(perform: deleteBookmarks)
                }
            }
        }
        .navigationTitle("Bookmarks")
        .toolbar {
            if !bookmarkedQuestions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showQuizSheet = true
                    } label: {
                        Label("Quiz Bookmarks", systemImage: "play.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showQuizSheet) {
            if let deps = dependencies {
                NavigationStack {
                    QuizSessionView(viewModel: {
                        deps.quizCoordinator.makeViewModel(mode: .preloaded(bookmarkedQuestions))
                    }())
                }
            }
        }
        .task {
            loadBookmarks()
        }
    }
    
    private func loadBookmarks() {
        guard let deps = dependencies else { return }
        bookmarkedQuestions = (try? deps.databaseManager.fetchBookmarkedQuestions()) ?? []
    }
    
    private func deleteBookmarks(at offsets: IndexSet) {
        guard let deps = dependencies else { return }
        for index in offsets {
            let question = bookmarkedQuestions[index]
            try? deps.databaseManager.removeBookmark(questionId: question.id)
        }
        bookmarkedQuestions.remove(atOffsets: offsets)
    }
}
