import SwiftUI

struct StudyView: View {
    @State private var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    @State private var savedSession: QuizSessionState? = nil
    @State private var showResumeConfirmation = false
    @State private var resumeVM: QuizViewModel? = nil
    
    init(viewModel: StudyViewModel) {
        self.viewModel = viewModel
    }
    
    @State private var showTips = false
    
    private var activeLeg: ExamLeg {
        deps?.settingsManager.activeLeg ?? .technicalLegal
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Resume session banner
                    if let session = savedSession {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Resume Quiz")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(session.currentIndex + 1) of \(session.questionIds.split(separator: ",").count) questions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Resume") {
                                guard let deps = deps else { return }
                                let vm = deps.makeQuizViewModel()
                                vm.restoreSession(from: session)
                                resumeVM = vm
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                showResumeConfirmation = true
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // QUICK START
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Start")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            timeButton(icon: "bolt.fill", time: "5 min", label: "Quick", type: .quickReview)
                            timeButton(icon: "calendar", time: "10 min", label: "Daily", type: .dailyPractice)
                            timeButton(icon: "target", time: "15 min", label: "Focused", type: .weakAreaFocus)
                        }
                    }
                    
                    // SUBJECTS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Subjects")
                            .font(.headline)
                        
                        ForEach(legSubjects, id: \.category.id) { item in
                            NavigationLink {
                                SubcategoryListView(viewModel: viewModel, parentId: item.category.id, parentName: item.category.name)
                            } label: {
                                subjectRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // TOOLS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tools")
                            .font(.headline)
                        
                        NavigationLink { SearchView() } label: {
                            toolRow(icon: "magnifyingglass", title: "Search Questions")
                        }.buttonStyle(.plain)
                        
                        NavigationLink { BookmarkedQuestionsView() } label: {
                            toolRow(icon: "bookmark.fill", title: "Bookmarks")
                        }.buttonStyle(.plain)
                        
                        NavigationLink { FlashcardView(sessionType: .legFocus(leg: activeLeg), leg: activeLeg) } label: {
                            flashcardRow
                        }.buttonStyle(.plain)
                        
                        if viewModel.hasWrongAnswers, let deps {
                            NavigationLink {
                                QuizSessionView(viewModel: makeWrongAnswersVM(deps))
                            } label: {
                                toolRow(icon: "xmark.circle", title: "Review Wrong Answers")
                            }.buttonStyle(.plain)
                        }
                        
                        NavigationLink { SRSReviewView(viewModel: viewModel) } label: {
                            srsRow
                        }.buttonStyle(.plain)
                        
                        NavigationLink { CategoryListView(viewModel: viewModel) } label: {
                            toolRow(icon: "list.bullet", title: "All Subjects")
                        }.buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Study")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text(activeLeg.emoji)
                        Text(activeLeg.shortTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear { 
                viewModel.loadTopLevelCategories()
                loadSavedSession()
            }
            .alert("Discard saved session?", isPresented: $showResumeConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    try? deps?.databaseManager.clearQuizSession()
                    savedSession = nil
                }
            } message: {
                if let session = savedSession {
                    Text("You've answered \(session.currentIndex) of \(session.questionIds.split(separator: ",").count) questions.")
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { resumeVM != nil },
                set: { if !$0 { resumeVM = nil } }
            )) {
                if let vm = resumeVM {
                    QuizSessionView(viewModel: vm)
                }
            }
        }
    }
    
    private func loadSavedSession() {
        savedSession = try? deps?.databaseManager.loadQuizSession()
    }
    
    // MARK: - Components
    
    private func timeButton(icon: String, time: String, label: String, type: SessionType) -> some View {
        NavigationLink {
            if let deps {
                QuizSessionView(viewModel: makeSessionVM(deps, type: type))
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                Text(time)
                    .font(.headline)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.regularMaterial)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Components
    
    private var flashcardRow: some View {
        HStack {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                .foregroundStyle(.white)
            Text("Flashcards")
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    private var srsRow: some View {
        HStack {
            Image(systemName: "brain.head.profile")
            Text("SRS Review")
            Spacer()
            if viewModel.dueCardCount > 0 {
                Text("\(viewModel.dueCardCount)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
    }
    
    private func subjectRow(_ item: CategoryWithStats) -> some View {
        HStack(spacing: 12) {
            Text(emojiForCategory(item.category.name))
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.category.name)
                    .font(.subheadline.weight(.medium))
                if item.srsStats.masteredCount > 0 {
                    Text("\(item.srsStats.masteredCount) mastered · \(item.stats.totalQuestions) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if item.stats.answeredQuestions > 0 {
                    Text("\(item.stats.answeredQuestions) answered · \(item.stats.totalQuestions) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(item.stats.totalQuestions) questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
    }
    
    private var legSubjects: [CategoryWithStats] {
        let legIds = Set(activeLeg.parentCategoryIds)
        return viewModel.topLevelCategories.filter { legIds.contains($0.category.id) }
    }
    
    // MARK: - Helpers
    
    private func toolRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
    }
    
    private func makeSessionVM(_ deps: Dependencies, type: SessionType) -> QuizViewModel {
        let vm = deps.makeQuizViewModel()
        let engine = SmartSessionEngine(databaseManager: deps.databaseManager)
        if let questions = try? engine.generateSession(type: type, leg: activeLeg), !questions.isEmpty {
            vm.loadQuestions(from: questions)
        }
        return vm
    }
    
    private func makeWrongAnswersVM(_ deps: Dependencies) -> QuizViewModel {
        let vm = deps.makeQuizViewModel()
        vm.loadQuestions(categoryId: nil, parentCategoryId: nil, wrongAnswersOnly: true, srsDueOnly: false)
        return vm
    }
    
    private func emojiForCategory(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("air law") { return "⚖️" }
        if lower.contains("aircraft") && lower.contains("general") { return "✈️" }
        if lower.contains("flight performance") { return "📊" }
        if lower.contains("mass") && lower.contains("balance") { return "⚖️" }
        if lower.contains("human performance") { return "🧠" }
        if lower.contains("meteorology") { return "🌦️" }
        if lower.contains("navigation") { return "🧭" }
        if lower.contains("operational") { return "📋" }
        if lower.contains("principles of flight") { return "🪂" }
        if lower.contains("communications") { return "📡" }
        return "📚"
    }
}
