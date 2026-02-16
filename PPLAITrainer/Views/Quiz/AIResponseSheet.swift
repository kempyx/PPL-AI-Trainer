import SwiftUI

struct AIResponseSheet: View {
    @State var viewModel: QuizViewModel
    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool
    
    private var visibleMessages: [ChatMessage] {
        chatMessages.filter { $0.role != .system }
    }
    
    private var chatMessages: [ChatMessage] {
        viewModel.chatMessages
    }
    
    /// Whether the last assistant message is still being typewritten
    private var isTypewriting: Bool {
        guard let last = chatMessages.last, last.role == .assistant else { return false }
        return viewModel.displayedAIText.count < last.content.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            // Quick action buttons when chat is empty
                            if visibleMessages.isEmpty && !viewModel.isLoadingAI {
                                quickActions
                            }
                            
                            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                                chatBubble(message: message, isLast: index == visibleMessages.count - 1)
                            }
                            
                            if viewModel.isLoadingAI {
                                ShimmerView()
                                    .id("shimmer")
                            }
                            
                            if let error = viewModel.aiError {
                                Label(aiErrorMessage(error), systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                    .font(.callout)
                                    .padding(.horizontal)
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
                
                // Input bar
                HStack(spacing: 8) {
                    TextField("Ask a follow-up…", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.plain)
                        .focused($inputFocused)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                    
                    Button {
                        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        inputText = ""
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
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(spacing: 10) {
            Text("How can I help with this question?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            
            HStack(spacing: 12) {
                quickActionButton("Explain", icon: "lightbulb.fill", color: .blue) {
                    viewModel.requestExplanation()
                }
                quickActionButton("Mnemonic", icon: "brain.head.profile", color: .purple) {
                    viewModel.requestMnemonic()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func quickActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }
    
    // MARK: - Chat Bubble
    
    @ViewBuilder
    private func chatBubble(message: ChatMessage, isLast: Bool) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading) {
                // For the last assistant message, show typewriter text
                if !isUser && isLast && !viewModel.displayedAIText.isEmpty {
                    Text(viewModel.displayedAIText)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                } else {
                    Text(message.content)
                        .padding(12)
                        .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                        .foregroundStyle(isUser ? .white : .primary)
                        .cornerRadius(16)
                }
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
    }
    
    private func aiErrorMessage(_ error: AIServiceError) -> String {
        switch error {
        case .noAPIKey: return "No API key configured. Add one in Settings."
        case .noNetwork: return "No internet connection."
        case .providerError(let msg): return msg
        }
    }
}

struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                    .frame(maxWidth: i == 3 ? 180 : .infinity)
                    .overlay(
                        GeometryReader { geo in
                            LinearGradient(
                                colors: [.clear, Color(.systemGray3).opacity(0.6), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geo.size.width * 0.4)
                            .offset(x: -geo.size.width * 0.4 + geo.size.width * 1.4 * phase)
                        }
                        .clipped()
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
