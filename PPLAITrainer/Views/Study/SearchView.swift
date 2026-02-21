import SwiftUI

struct SearchView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: SearchViewModel?
    @State private var searchText = ""
    
    var body: some View {
        List {
            if let viewModel {
                if viewModel.results.isEmpty && !searchText.isEmpty && !viewModel.isSearching {
                    ContentUnavailableView.search
                } else {
                    ForEach(viewModel.results, id: \.id) { question in
                        NavigationLink {
                            QuestionDetailView(question: question)
                        } label: {
                            SearchResultRow(question: question, searchText: searchText)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search questions...")
        .onChange(of: searchText) {
            viewModel?.searchText = searchText
            viewModel?.search()
        }
        .navigationTitle("Search")
        .onAppear {
            if viewModel == nil, let deps = dependencies {
                viewModel = SearchViewModel(databaseManager: deps.databaseManager)
            }
        }
    }
}

struct QuestionDetailView: View {
    @Environment(\.dependencies) private var dependencies
    let question: Question
    @State private var isBookmarked = false
    @State private var note: Note?
    @State private var showNoteEditor = false
    @State private var showAISheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(question.text)
                    .font(.title3.weight(.semibold))
                
                VStack(alignment: .leading, spacing: 8) {
                    optionRow(option: question.correct, isCorrect: true)
                    optionRow(option: question.incorrect0, isCorrect: false)
                    optionRow(option: question.incorrect1, isCorrect: false)
                    optionRow(option: question.incorrect2, isCorrect: false)
                }
                
                if let explanation = question.explanation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation")
                            .font(.headline)
                        Text(explanation)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
                
                if let note {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Note")
                            .font(.headline)
                        Text(note.text)
                    }
                    .padding()
                    .background(.yellow.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if dependencies?.settingsManager.aiEnabled == true {
                        Button {
                            showAISheet = true
                        } label: {
                            Image(systemName: "sparkles")
                        }
                    }
                    Button {
                        showNoteEditor = true
                    } label: {
                        Image(systemName: note != nil ? "note.text" : "note.text.badge.plus")
                    }
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                }
            }
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(question: question, existingNote: note) { savedNote in
                note = savedNote
            }
        }
        .sheet(isPresented: $showAISheet) {
            if let deps = dependencies {
                StandaloneAISheet(question: question, deps: deps)
                    .presentationDetents([.medium, .large])
            }
        }
        .task {
            loadBookmarkStatus()
            loadNote()
        }
    }
    
    private func toggleBookmark() {
        guard let deps = dependencies else { return }
        do {
            if isBookmarked {
                try deps.databaseManager.removeBookmark(questionId: question.id)
            } else {
                try deps.databaseManager.addBookmark(questionId: question.id)
            }
            isBookmarked.toggle()
        } catch {}
    }
    
    private func loadBookmarkStatus() {
        guard let deps = dependencies else { return }
        isBookmarked = (try? deps.databaseManager.isBookmarked(questionId: question.id)) ?? false
    }
    
    private func loadNote() {
        guard let deps = dependencies else { return }
        note = try? deps.databaseManager.fetchNote(questionId: question.id)
    }
    
    private func optionRow(option: String, isCorrect: Bool) -> some View {
        HStack {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCorrect ? .green : .gray)
            Text(option)
        }
    }
}

// MARK: - Standalone AI Sheet for bookmarks/search

struct StandaloneAISheet: View {
    let question: Question
    let deps: Dependencies
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var displayedText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if messages.filter({ $0.role != .system }).isEmpty && !isLoading {
                                VStack(spacing: 10) {
                                    Text("Ask about this question")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 20)
                                    VStack(spacing: 8) {
                                        Button("Explain") { send("Explain this question and the correct answer.") }
                                            .buttonStyle(.bordered).tint(.blue).frame(maxWidth: .infinity)
                                        Button("Simplify") { send("Simplify this concept. Break it down into simple terms.") }
                                            .buttonStyle(.bordered).tint(.green).frame(maxWidth: .infinity)
                                        Button("Analogy") { send("Give me a real-world analogy to help me understand this.") }
                                            .buttonStyle(.bordered).tint(.orange).frame(maxWidth: .infinity)
                                        Button("Common Mistakes") { send("What do students commonly get wrong about this?") }
                                            .buttonStyle(.bordered).tint(.red).frame(maxWidth: .infinity)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            ForEach(messages.filter { $0.role != .system }, id: \.id) { msg in
                                let isUser = msg.role == .user
                                let isLastAssistant = msg.id == messages.last?.id && !isUser
                                HStack {
                                    if isUser { Spacer(minLength: 60) }
                                    Text(isLastAssistant && !displayedText.isEmpty ? displayedText : msg.content)
                                        .padding(12)
                                        .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                                        .foregroundStyle(isUser ? .white : .primary)
                                        .cornerRadius(16)
                                    if !isUser { Spacer(minLength: 60) }
                                }
                                .padding(.horizontal, 12)
                            }
                            
                            if isLoading {
                                ProgressView().padding()
                            }
                            
                            Color.clear.frame(height: 1).id("bottom")
                        }
                    }
                    .onChange(of: messages.count) { withAnimation { proxy.scrollTo("bottom") } }
                    .onChange(of: displayedText) { withAnimation { proxy.scrollTo("bottom") } }
                }
                
                Divider()
                HStack(spacing: 8) {
                    TextField("Ask a follow-up…", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                    Button {
                        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        inputText = ""
                        send(text)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("Ask AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func send(_ text: String) {
        if messages.isEmpty {
            messages.append(ChatMessage(role: .system, content: deps.settingsManager.systemPrompt))
            let ctx = """
            Question: \(question.text)
            Correct answer: \(question.correct)
            Other options: \(question.incorrect0), \(question.incorrect1), \(question.incorrect2)
            \(question.explanation.map { "Explanation: \($0)" } ?? "")
            """
            messages.append(ChatMessage(role: .user, content: ctx))
            messages.append(ChatMessage(role: .assistant, content: "I can see the question. How can I help?"))
        }
        messages.append(ChatMessage(role: .user, content: text))
        
        Task {
            isLoading = true
            displayedText = ""
            do {
                let response = try await deps.aiService.sendChat(messages: messages)
                messages.append(ChatMessage(role: .assistant, content: response))
                isLoading = false
                // Quick typewriter
                for char in response {
                    displayedText.append(char)
                    try? await Task.sleep(for: .milliseconds(5))
                }
            } catch {
                isLoading = false
            }
        }
    }
}

private struct SearchResultRow: View {
    @Environment(\.dependencies) private var dependencies
    let question: Question
    let searchText: String
    @State private var categoryName: String?
    @State private var attemptStatus: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(highlightedText(question.text))
                .font(.body)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                if let categoryName {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let attemptStatus {
                    Text(attemptStatus)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                }
                
                Text(question.code)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            loadMetadata()
        }
    }
    
    private var statusColor: Color {
        if attemptStatus == "Correct" { return .green }
        if attemptStatus == "Wrong" { return .red }
        return .secondary
    }
    
    private func highlightedText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: searchText, options: .caseInsensitive) {
            attributed[range].font = .body.bold()
        }
        return attributed
    }
    
    private func loadMetadata() {
        guard let deps = dependencies else { return }
        categoryName = try? deps.databaseManager.fetchCategoryStats(categoryId: question.category).categoryName
        
        if let history = try? deps.databaseManager.fetchAnswerHistory(questionId: question.id), !history.isEmpty {
            let lastAttempt = history.last!
            attemptStatus = lastAttempt.isCorrect ? "Correct" : "Wrong"
        }
    }
}
