import SwiftUI

struct AIConversationSheet: View {
    @State var viewModel: AIConversationViewModel
    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool
    @Environment(\.dependencies) private var dependencies
    
    private var visibleMessages: [ChatMessage] {
        viewModel.chatMessages.filter { $0.role != .system }
    }
    
    private var isTypewriting: Bool {
        guard let last = viewModel.chatMessages.last, last.role == .assistant else { return false }
        return viewModel.displayedAIText.count < last.content.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if visibleMessages.isEmpty && !viewModel.isLoadingAI {
                                quickActions
                            }
                            
                            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                                chatBubble(message: message, isLast: index == visibleMessages.count - 1)
                            }
                            
                            if viewModel.isLoadingAI {
                                LoadingAnimationView(requestCount: viewModel.requestCount)
                                    .id("shimmer")
                            }
                            
                            if let error = viewModel.aiError {
                                VStack(spacing: 12) {
                                    Label(aiErrorMessage(error), systemImage: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                        .font(.callout)
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            viewModel.retryLastMessage()
                                        } label: {
                                            HStack {
                                                Image(systemName: "arrow.clockwise")
                                                Text("Retry")
                                            }
                                        }
                                        .buttonStyle(SecondaryButtonStyle())
                                        
                                        if case .noAPIKey = error {
                                            NavigationLink {
                                                if let deps = dependencies {
                                                    SettingsView(viewModel: SettingsViewModel(keychainStore: deps.keychainStore, settingsManager: deps.settingsManager))
                                                }
                                            } label: {
                                                HStack {
                                                    Image(systemName: "gear")
                                                    Text("Settings")
                                                }
                                            }
                                            .buttonStyle(SecondaryButtonStyle())
                                        }
                                    }
                                }
                                .padding()
                            }
                            
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.displayedAIText) {
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                    .onChange(of: viewModel.isLoadingAI) {
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                    .onChange(of: viewModel.chatMessages.count) {
                        withAnimation { proxy.scrollTo("bottom") }
                    }
                }
                
                Divider()
                
                HStack(spacing: 8) {
                    TextField("Ask a follow-up…", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.plain)
                        .focused($inputFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                        .submitLabel(.send)
                        .onSubmit {
                            let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            inputText = ""
                            inputFocused = false
                            viewModel.sendChatMessage(text)
                        }
                    
                    if inputFocused && !inputText.isEmpty {
                        Button {
                            inputText = ""
                            inputFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        inputText = ""
                        inputFocused = false
                        viewModel.sendChatMessage(text)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoadingAI)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("Ask AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { viewModel.showAISheet = false }
                }
            }
            .alert("Send request to AI?", isPresented: $viewModel.showConfirmation) {
                Button("Cancel", role: .cancel) { viewModel.cancelAIRequest() }
                Button("Confirm") { viewModel.confirmAIRequest() }
            }
            .onDisappear {
                viewModel.ttsService.stop()
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(spacing: 10) {
            Text("AI responses are for study support. Verify with the official explanation and syllabus references.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Text("How can I help?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                quickActionButton("Explain", icon: "lightbulb.fill", color: .blue) {
                    viewModel.requestExplanation()
                }
                quickActionButton("Simplify", icon: "arrow.down.circle.fill", color: .green) {
                    viewModel.requestSimplification()
                }
                quickActionButton("Analogy", icon: "link.circle.fill", color: .orange) {
                    viewModel.requestAnalogy()
                }
                quickActionButton("Common Mistakes", icon: "exclamationmark.triangle.fill", color: .red) {
                    viewModel.requestCommonMistakes()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func quickActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .accessibilityHint("Sends a guided AI request")
    }
    
    // MARK: - Chat Bubble
    
    @ViewBuilder
    private func chatBubble(message: ChatMessage, isLast: Bool) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if isUser {
                    Text(message.content)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                } else if isLast && isTypewriting {
                    Text(viewModel.displayedAIText)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                } else {
                    let aiText = message.content
                    AIMarkdownMathView(content: aiText)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                }
                
                if !isUser {
                    Button {
                        if viewModel.ttsService.isSpeaking {
                            viewModel.ttsService.stop()
                        } else {
                            let text = isLast && !viewModel.displayedAIText.isEmpty ? viewModel.displayedAIText : message.content
                            viewModel.ttsService.speak(text)
                        }
                    } label: {
                        Image(systemName: viewModel.ttsService.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
    }
    
    private func aiErrorMessage(_ error: AIServiceError) -> String {
        switch error {
        case .noAPIKey: return "No API key configured"
        case .noNetwork: return "No internet connection. Try Apple Intelligence for offline AI."
        case .providerError(let msg): 
            if msg.contains("401") || msg.contains("403") {
                return "Invalid API key. Check your settings."
            } else if msg.contains("429") {
                return "Rate limit exceeded. Try again in a moment."
            } else if msg.contains("500") || msg.contains("503") {
                return "AI service temporarily unavailable."
            }
            return "AI request failed. Please try again."
        }
    }
}

#Preview {
    let deps = Dependencies.preview
    let viewModel = AIConversationViewModel(
        aiService: deps.aiService,
        settingsManager: deps.settingsManager,
        contextProvider: { "Sample question context for preview." }
    )
    AIConversationSheet(viewModel: viewModel)
        .environment(\.dependencies, deps)
}
