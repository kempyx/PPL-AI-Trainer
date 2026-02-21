import SwiftUI
import MarkdownUI

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
    }
    
    // MARK: - Chat Bubble
    
    @ViewBuilder
    private func chatBubble(message: ChatMessage, isLast: Bool) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if !isUser && isLast && !viewModel.displayedAIText.isEmpty {
                    Markdown(convertLatexToUnicode(viewModel.displayedAIText))
                        .markdownTextStyle(\.text) {
                            ForegroundColor(.primary)
                        }
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                } else if isUser {
                    Text(message.content)
                        .textSelection(.enabled)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                } else {
                    Markdown(convertLatexToUnicode(message.content))
                        .markdownTextStyle(\.text) {
                            ForegroundColor(.primary)
                        }
                        .textSelection(.enabled)
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
    
    private func convertLatexToUnicode(_ text: String) -> String {
        var result = text
        
        // Remove $$ and $ delimiters first
        result = result.replacingOccurrences(of: "$$", with: "")
        result = result.replacingOccurrences(of: "$", with: "")
        
        // Handle fractions BEFORE removing braces
        result = result.replacingOccurrences(of: "\\frac{1}{2}", with: "½")
        result = result.replacingOccurrences(of: "\\frac{1}{3}", with: "⅓")
        result = result.replacingOccurrences(of: "\\frac{2}{3}", with: "⅔")
        result = result.replacingOccurrences(of: "\\frac{1}{4}", with: "¼")
        result = result.replacingOccurrences(of: "\\frac{3}{4}", with: "¾")
        result = result.replacingOccurrences(of: "\\frac{1}{5}", with: "⅕")
        result = result.replacingOccurrences(of: "\\frac{2}{5}", with: "⅖")
        result = result.replacingOccurrences(of: "\\frac{3}{5}", with: "⅗")
        result = result.replacingOccurrences(of: "\\frac{4}{5}", with: "⅘")
        result = result.replacingOccurrences(of: "\\frac{1}{6}", with: "⅙")
        result = result.replacingOccurrences(of: "\\frac{5}{6}", with: "⅚")
        result = result.replacingOccurrences(of: "\\frac{1}{8}", with: "⅛")
        result = result.replacingOccurrences(of: "\\frac{3}{8}", with: "⅜")
        result = result.replacingOccurrences(of: "\\frac{5}{8}", with: "⅝")
        result = result.replacingOccurrences(of: "\\frac{7}{8}", with: "⅞")
        
        // Handle malformed fractions (without braces)
        result = result.replacingOccurrences(of: "frac12", with: "½")
        result = result.replacingOccurrences(of: "frac13", with: "⅓")
        result = result.replacingOccurrences(of: "frac14", with: "¼")
        result = result.replacingOccurrences(of: "frac34", with: "¾")
        
        // Handle superscripts with braces BEFORE removing braces
        result = result.replacingOccurrences(of: "^{-1}", with: "⁻¹")
        result = result.replacingOccurrences(of: "^{2}", with: "²")
        result = result.replacingOccurrences(of: "^{3}", with: "³")
        
        // Handle subscripts with braces (multi-character) - AVIATION SPECIFIC
        result = result.replacingOccurrences(of: "_{max}", with: "ₘₐₓ")
        result = result.replacingOccurrences(of: "_{min}", with: "ₘᵢₙ")
        result = result.replacingOccurrences(of: "_{exit}", with: "ₑₓᵢₜ")
        result = result.replacingOccurrences(of: "_{inlet}", with: "ᵢₙₗₑₜ")
        result = result.replacingOccurrences(of: "_{Lmax}", with: "ₗₘₐₓ")
        result = result.replacingOccurrences(of: "_{total}", with: "ₜₒₜₐₗ")
        result = result.replacingOccurrences(of: "_{parasite}", with: "ₚₐᵣₐₛᵢₜₑ")
        result = result.replacingOccurrences(of: "_{induced}", with: "ᵢₙ��ᵤ��ₑ��")
        result = result.replacingOccurrences(of: "_{stall}", with: "ₛₜₐₗₗ")
        result = result.replacingOccurrences(of: "_{cruise}", with: "��ᵣᵤᵢₛₑ")
        result = result.replacingOccurrences(of: "_{climb}", with: "��ₗᵢₘ��")
        result = result.replacingOccurrences(of: "_{descent}", with: "��ₑₛ��ₑₙₜ")
        result = result.replacingOccurrences(of: "_{takeoff}", with: "ₜₐₖₑₒ��")
        result = result.replacingOccurrences(of: "_{landing}", with: "ₗₐₙ��ᵢₙ��")
        result = result.replacingOccurrences(of: "_{ground}", with: "��ᵣₒᵤₙ��")
        result = result.replacingOccurrences(of: "_{air}", with: "ₐᵢᵣ")
        result = result.replacingOccurrences(of: "_{true}", with: "ₜᵣᵤₑ")
        result = result.replacingOccurrences(of: "_{indicated}", with: "ᵢₙ��ᵢ��ₐₜₑ��")
        result = result.replacingOccurrences(of: "_{calibrated}", with: "��ₐₗᵢ��ᵣₐₜₑ��")
        result = result.replacingOccurrences(of: "_{equivalent}", with: "ₑ��ᵤᵢᵥₐₗₑₙₜ")
        
        // Remove \text{} wrappers
        result = result.replacingOccurrences(of: "\\text{", with: "")
        
        // Arrows
        result = result.replacingOccurrences(of: "\\uparrow", with: "↑")
        result = result.replacingOccurrences(of: "\\downarrow", with: "↓")
        result = result.replacingOccurrences(of: "\\rightarrow", with: "→")
        result = result.replacingOccurrences(of: "\\leftarrow", with: "←")
        result = result.replacingOccurrences(of: "\\Rightarrow", with: "⇒")
        result = result.replacingOccurrences(of: "\\Leftarrow", with: "⇐")
        result = result.replacingOccurrences(of: "\\leftrightarrow", with: "↔")
        result = result.replacingOccurrences(of: "\\Leftrightarrow", with: "⇔")
        result = result.replacingOccurrences(of: "\\to", with: "→")
        
        // Greek letters (lowercase)
        result = result.replacingOccurrences(of: "\\alpha", with: "α")
        result = result.replacingOccurrences(of: "\\beta", with: "β")
        result = result.replacingOccurrences(of: "\\gamma", with: "γ")
        result = result.replacingOccurrences(of: "\\delta", with: "δ")
        result = result.replacingOccurrences(of: "\\epsilon", with: "ε")
        result = result.replacingOccurrences(of: "\\varepsilon", with: "ε")
        result = result.replacingOccurrences(of: "\\zeta", with: "ζ")
        result = result.replacingOccurrences(of: "\\eta", with: "η")
        result = result.replacingOccurrences(of: "\\theta", with: "θ")
        result = result.replacingOccurrences(of: "\\iota", with: "ι")
        result = result.replacingOccurrences(of: "\\kappa", with: "κ")
        result = result.replacingOccurrences(of: "\\lambda", with: "λ")
        result = result.replacingOccurrences(of: "\\mu", with: "μ")
        result = result.replacingOccurrences(of: "\\nu", with: "ν")
        result = result.replacingOccurrences(of: "\\xi", with: "ξ")
        result = result.replacingOccurrences(of: "\\pi", with: "π")
        result = result.replacingOccurrences(of: "\\rho", with: "ρ")
        result = result.replacingOccurrences(of: "\\sigma", with: "σ")
        result = result.replacingOccurrences(of: "\\tau", with: "τ")
        result = result.replacingOccurrences(of: "\\upsilon", with: "υ")
        result = result.replacingOccurrences(of: "\\phi", with: "φ")
        result = result.replacingOccurrences(of: "\\varphi", with: "φ")
        result = result.replacingOccurrences(of: "\\chi", with: "χ")
        result = result.replacingOccurrences(of: "\\psi", with: "ψ")
        result = result.replacingOccurrences(of: "\\omega", with: "ω")
        
        // Greek letters (uppercase)
        result = result.replacingOccurrences(of: "\\Gamma", with: "Γ")
        result = result.replacingOccurrences(of: "\\Delta", with: "Δ")
        result = result.replacingOccurrences(of: "\\Theta", with: "Θ")
        result = result.replacingOccurrences(of: "\\Lambda", with: "Λ")
        result = result.replacingOccurrences(of: "\\Xi", with: "Ξ")
        result = result.replacingOccurrences(of: "\\Pi", with: "Π")
        result = result.replacingOccurrences(of: "\\Sigma", with: "Σ")
        result = result.replacingOccurrences(of: "\\Phi", with: "Φ")
        result = result.replacingOccurrences(of: "\\Psi", with: "Ψ")
        result = result.replacingOccurrences(of: "\\Omega", with: "Ω")
        
        // Mathematical operators
        result = result.replacingOccurrences(of: "\\times", with: "×")
        result = result.replacingOccurrences(of: "\\div", with: "÷")
        result = result.replacingOccurrences(of: "\\pm", with: "±")
        result = result.replacingOccurrences(of: "\\cdot", with: "·")
        result = result.replacingOccurrences(of: "\\bullet", with: "•")
        result = result.replacingOccurrences(of: "\\circ", with: "°")
        
        // Relations
        result = result.replacingOccurrences(of: "\\leq", with: "≤")
        result = result.replacingOccurrences(of: "\\geq", with: "≥")
        result = result.replacingOccurrences(of: "\\neq", with: "≠")
        result = result.replacingOccurrences(of: "\\approx", with: "≈")
        result = result.replacingOccurrences(of: "\\equiv", with: "≡")
        result = result.replacingOccurrences(of: "\\propto", with: "∝")
        
        // Calculus & misc
        result = result.replacingOccurrences(of: "\\infty", with: "∞")
        result = result.replacingOccurrences(of: "\\partial", with: "∂")
        result = result.replacingOccurrences(of: "\\nabla", with: "∇")
        result = result.replacingOccurrences(of: "\\int", with: "∫")
        result = result.replacingOccurrences(of: "\\sum", with: "∑")
        result = result.replacingOccurrences(of: "\\prod", with: "∏")
        result = result.replacingOccurrences(of: "\\sqrt", with: "√")
        result = result.replacingOccurrences(of: "\\angle", with: "∠")
        result = result.replacingOccurrences(of: "\\degree", with: "°")
        
        // Superscripts without braces (do AFTER braced versions)
        result = result.replacingOccurrences(of: "^0", with: "⁰")
        result = result.replacingOccurrences(of: "^1", with: "¹")
        result = result.replacingOccurrences(of: "^2", with: "²")
        result = result.replacingOccurrences(of: "^3", with: "³")
        result = result.replacingOccurrences(of: "^4", with: "⁴")
        result = result.replacingOccurrences(of: "^5", with: "⁵")
        result = result.replacingOccurrences(of: "^6", with: "⁶")
        result = result.replacingOccurrences(of: "^7", with: "⁷")
        result = result.replacingOccurrences(of: "^8", with: "⁸")
        result = result.replacingOccurrences(of: "^9", with: "⁹")
        
        // Subscripts - single character (do AFTER multi-character)
        result = result.replacingOccurrences(of: "_0", with: "₀")
        result = result.replacingOccurrences(of: "_1", with: "₁")
        result = result.replacingOccurrences(of: "_2", with: "₂")
        result = result.replacingOccurrences(of: "_3", with: "₃")
        result = result.replacingOccurrences(of: "_4", with: "₄")
        result = result.replacingOccurrences(of: "_5", with: "₅")
        result = result.replacingOccurrences(of: "_L", with: "ₗ")
        result = result.replacingOccurrences(of: "_D", with: "ᴅ")
        result = result.replacingOccurrences(of: "_i", with: "ᵢ")
        result = result.replacingOccurrences(of: "_n", with: "ₙ")
        result = result.replacingOccurrences(of: "_e", with: "ₑ")
        result = result.replacingOccurrences(of: "_x", with: "ₓ")
        result = result.replacingOccurrences(of: "_a", with: "ₐ")
        result = result.replacingOccurrences(of: "_t", with: "ₜ")
        result = result.replacingOccurrences(of: "_s", with: "ₛ")
        result = result.replacingOccurrences(of: "_o", with: "ₒ")
        result = result.replacingOccurrences(of: "_p", with: "ₚ")
        result = result.replacingOccurrences(of: "_r", with: "ᵣ")
        result = result.replacingOccurrences(of: "_u", with: "ᵤ")
        result = result.replacingOccurrences(of: "_v", with: "ᵥ")
        result = result.replacingOccurrences(of: "_h", with: "ₕ")
        result = result.replacingOccurrences(of: "_k", with: "ₖ")
        result = result.replacingOccurrences(of: "_m", with: "ₘ")
        result = result.replacingOccurrences(of: "_w", with: "w") // no subscript w in Unicode
        result = result.replacingOccurrences(of: "_y", with: "y") // no subscript y in Unicode
        result = result.replacingOccurrences(of: "_z", with: "z") // no subscript z in Unicode
        
        // Aviation-specific subscript words without braces (do BEFORE single letters)
        result = result.replacingOccurrences(of: "_total", with: "ₜₒₜₐₗ")
        result = result.replacingOccurrences(of: "_parasite", with: "ₚₐᵣₐₛᵢₜₑ")
        result = result.replacingOccurrences(of: "_induced", with: "ᵢₙ��ᵤ��ₑ��")
        result = result.replacingOccurrences(of: "_profile", with: "ₚᵣₒ��ᵢₗₑ")
        result = result.replacingOccurrences(of: "_form", with: "��ₒᵣₘ")
        result = result.replacingOccurrences(of: "_wave", with: "wₐᵥₑ")
        result = result.replacingOccurrences(of: "_stall", with: "ₛₜₐₗₗ")
        result = result.replacingOccurrences(of: "_cruise", with: "��ᵣᵤᵢₛₑ")
        result = result.replacingOccurrences(of: "_climb", with: "��ₗᵢₘ��")
        result = result.replacingOccurrences(of: "_descent", with: "��ₑₛ��ₑₙₜ")
        result = result.replacingOccurrences(of: "_takeoff", with: "ₜₐₖₑₒ��")
        result = result.replacingOccurrences(of: "_landing", with: "ₗₐₙ��ᵢₙ��")
        result = result.replacingOccurrences(of: "_ground", with: "��ᵣₒᵤₙ��")
        result = result.replacingOccurrences(of: "_air", with: "ₐᵢᵣ")
        result = result.replacingOccurrences(of: "_true", with: "ₜᵣᵤₑ")
        result = result.replacingOccurrences(of: "_indicated", with: "ᵢₙ��ᵢ��ₐₜₑ��")
        result = result.replacingOccurrences(of: "_calibrated", with: "��ₐₗᵢ��ᵣₐₜₑ��")
        result = result.replacingOccurrences(of: "_equivalent", with: "ₑ��ᵤᵢᵥₐₗₑₙₜ")
        result = result.replacingOccurrences(of: "_never", with: "ₙₑᵥₑᵣ")
        result = result.replacingOccurrences(of: "_max", with: "ₘₐₓ")
        result = result.replacingOccurrences(of: "_min", with: "ₘᵢₙ")
        result = result.replacingOccurrences(of: "_exit", with: "ₑₓᵢₜ")
        result = result.replacingOccurrences(of: "_inlet", with: "ᵢₙₗₑₜ")
        result = result.replacingOccurrences(of: "_st", with: "ₛₜ")
        result = result.replacingOccurrences(of: "_ref", with: "ᵣₑ��")
        result = result.replacingOccurrences(of: "_sea", with: "ₛₑₐ")
        result = result.replacingOccurrences(of: "_std", with: "ₛₜ��")
        result = result.replacingOccurrences(of: "_ISA", with: "ᵢₛₐ")
        result = result.replacingOccurrences(of: "_SL", with: "ₛₗ")
        result = result.replacingOccurrences(of: "_TO", with: "ₜₒ")
        result = result.replacingOccurrences(of: "_LDG", with: "ₗ����")
        result = result.replacingOccurrences(of: "_APP", with: "ₐₚₚ")
        result = result.replacingOccurrences(of: "_MCT", with: "ₘ��ₜ")
        result = result.replacingOccurrences(of: "_MTOW", with: "ₘₜₒw")
        result = result.replacingOccurrences(of: "_MLW", with: "ₘₗw")
        result = result.replacingOccurrences(of: "_MZFW", with: "ₘz��w")
        result = result.replacingOccurrences(of: "_CG", with: "����")
        result = result.replacingOccurrences(of: "_MAC", with: "ₘₐ��")
        result = result.replacingOccurrences(of: "_LE", with: "ₗₑ")
        result = result.replacingOccurrences(of: "_TE", with: "ₜₑ")
        
        // Clean up remaining braces and backslashes (do LAST)
        result = result.replacingOccurrences(of: "{", with: "")
        result = result.replacingOccurrences(of: "}", with: "")
        result = result.replacingOccurrences(of: "\\", with: "")
        
        // Clean up leftover command fragments and malformed fractions
        result = result.replacingOccurrences(of: "circ", with: "°")
        result = result.replacingOccurrences(of: "/LW", with: " / (L/W)")
        result = result.replacingOccurrences(of: "/LiftDrag", with: " / (Lift/Drag)")
        result = result.replacingOccurrences(of: "/DistanceAltitude", with: " / (Distance/Altitude)")
        result = result.replacingOccurrences(of: "/Total", with: " / Total")
        result = result.replacingOccurrences(of: "frac", with: "/")
        
        return result
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
