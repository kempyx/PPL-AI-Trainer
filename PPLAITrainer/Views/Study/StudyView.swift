import SwiftUI

struct StudyView: View {
    @State private var viewModel: StudyViewModel
    @Environment(\.dependencies) private var deps
    
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
                VStack(spacing: 16) {
                    tipsCard
                    timeBasedSessionsSection
                    continueStudyingSection
                    legSubjectsSection
                    toolsSection
                    moreSection
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
            }
        }
    }
    
    // MARK: - Tips
    
    private var tipsCard: some View {
        DisclosureGroup(isExpanded: $showTips) {
            VStack(alignment: .leading, spacing: 8) {
                tipRow("⚡", "Pick your time budget: 5, 10, or 15 minutes")
                tipRow("📚", "Browse subjects to study specific topics")
                tipRow("🎯", "The app adapts to your weak areas and SRS cards")
                tipRow("🔖", "Bookmark questions and add notes for later review")
                tipRow("✨", "Tap the AI button after answering to get explanations")
                tipRow("🧠", "SRS spaces out reviews so you remember long-term")
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("How to Study")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(14)
    }
    
    private func tipRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }
    
    // MARK: - Time-Based Sessions
    
    private var timeBasedSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How much time do you have?")
                .font(.headline)
            
            HStack(spacing: 12) {
                timeButton(icon: "bolt.fill", time: "5 min", label: "Quick", type: .quickReview)
                timeButton(icon: "calendar", time: "10 min", label: "Daily", type: .dailyPractice)
                timeButton(icon: "target", time: "15 min", label: "Focused", type: .weakAreaFocus)
            }
        }
    }
    
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
    
    // MARK: - Continue Studying
    
    private var continueStudyingSection: some View {
        Group {
            if let subjectId = deps?.settingsManager.lastStudiedSubjectId,
               let subjectName = deps?.settingsManager.lastStudiedSubjectName {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Or continue where you left off")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    NavigationLink {
                        SubcategoryListView(viewModel: viewModel, parentId: subjectId, parentName: subjectName)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subjectName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("Resume studying")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Leg Subjects
    
    private var legSubjects: [CategoryWithStats] {
        let legIds = Set(activeLeg.parentCategoryIds)
        return viewModel.topLevelCategories.filter { legIds.contains($0.category.id) }
    }
    
    private var legSubjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subjects")
                .font(.headline)
            
            ForEach(legSubjects, id: \.category.id) { item in
                NavigationLink {
                    SubcategoryListView(viewModel: viewModel, parentId: item.category.id, parentName: item.category.name)
                } label: {
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
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Tools
    
    private var toolsSection: some View {
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
            }.buttonStyle(.plain)
            
            if viewModel.hasWrongAnswers, let deps {
                NavigationLink {
                    QuizSessionView(viewModel: makeWrongAnswersVM(deps))
                } label: {
                    toolRow(icon: "xmark.circle", title: "Review Wrong Answers")
                }.buttonStyle(.plain)
            }
            
            NavigationLink { SRSReviewView(viewModel: viewModel) } label: {
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
            }.buttonStyle(.plain)
        }
    }
    
    // MARK: - More
    
    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More")
                .font(.headline)
            
            NavigationLink { CategoryListView(viewModel: viewModel) } label: {
                toolRow(icon: "list.bullet", title: "All Subjects")
            }.buttonStyle(.plain)
        }
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
