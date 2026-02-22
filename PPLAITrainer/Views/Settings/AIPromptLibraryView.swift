import SwiftUI

struct AIPromptLibraryView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section {
                Text("Prompt changes apply to all providers (OpenAI, Gemini, Grok).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Prompts") {
                ForEach(viewModel.promptItems) { item in
                    NavigationLink {
                        AIPromptEditorView(viewModel: viewModel, item: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.title)
                                Spacer()
                                if viewModel.promptText(for: item.key) != (SettingsManager.defaultAIPrompts[item.key] ?? "") {
                                    Text("Modified")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.15))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("AI Prompts")
    }
}

struct AIPromptEditorView: View {
    @State var viewModel: SettingsViewModel
    let item: SettingsViewModel.AIPromptItem
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: Binding(
                get: { viewModel.promptText(for: item.key) },
                set: { viewModel.updatePrompt(item.key, text: $0) }
            ))
            .font(.system(.body, design: .monospaced))
            .focused($isFocused)
            .padding(4)
            .frame(maxHeight: .infinity)

            HStack {
                Text("\(viewModel.promptText(for: item.key).count) chars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset") { viewModel.resetPrompt(item.key) }
                    .font(.caption.weight(.semibold))
                    .disabled(viewModel.promptText(for: item.key) == (SettingsManager.defaultAIPrompts[item.key] ?? ""))
            }

            if !item.tokenHints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Available tokens")
                        .font(.caption.weight(.semibold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.tokenHints, id: \.self) { token in
                                Text(token)
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.secondarySystemBackground), in: Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFocused = false }
            }
        }
    }
}

#Preview {
    let deps = Dependencies.preview
    AIPromptLibraryView(viewModel: SettingsViewModel(keychainStore: deps.keychainStore, settingsManager: deps.settingsManager))
        .environment(\.dependencies, deps)
}
