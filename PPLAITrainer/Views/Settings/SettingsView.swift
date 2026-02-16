import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    providerCard
                    aiFeaturesCard
                    systemPromptCard
                    appearanceCard
                    dangerZoneCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .onDisappear { viewModel.saveCurrentKey() }
            .navigationTitle("Settings")
            .alert("Reset All Keys?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllKeys()
                }
            } message: {
                Text("This will delete all stored API keys.")
            }
        }
    }

    // MARK: - AI Provider

    private var providerCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "cpu", title: "AI Provider", color: .blue)

                Picker("Provider", selection: $viewModel.selectedProvider) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 0) {
                    ForEach(viewModel.selectedProvider.availableModels) { model in
                        ModelRow(
                            model: model,
                            isSelected: viewModel.selectedModel == model.id
                        ) {
                            viewModel.selectedModel = model.id
                        }

                        if model.id != viewModel.selectedProvider.availableModels.last?.id {
                            Divider().padding(.leading, 40)
                        }
                    }
                }

                Divider()

                HStack {
                    SecureField(
                        "\(viewModel.selectedProvider.displayName) API Key",
                        text: $viewModel.currentApiKey
                    )
                    .textContentType(.password)

                    if viewModel.hasApiKey {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .imageScale(.large)
                    }
                }
            }
        }
    }

    // MARK: - AI Features

    private var aiFeaturesCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "sparkles", title: "AI Features", color: .purple)

                Toggle("Enable AI Features", isOn: $viewModel.aiEnabled)

                if viewModel.aiEnabled {
                    Toggle("Confirm before sending", isOn: $viewModel.confirmBeforeSending)
                }
            }
            .animation(.default, value: viewModel.aiEnabled)
        }
    }

    // MARK: - System Prompt

    private var systemPromptCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SettingsSectionHeader(icon: "text.bubble", title: "System Prompt", color: .orange)
                    Spacer()
                    if !viewModel.isDefaultPrompt {
                        Text("Modified")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }

                Text(viewModel.systemPrompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                NavigationLink {
                    SystemPromptEditor(viewModel: viewModel)
                } label: {
                    HStack {
                        Text("Edit System Prompt")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "paintbrush", title: "Appearance", color: .indigo)

                Picker("Theme", selection: $viewModel.appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneCard: some View {
        SettingsCard {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Reset All API Keys")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Helper Components

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SettingsSectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(title)
                .font(.headline)
        }
    }
}

private struct ModelRow: View {
    let model: AIModel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .imageScale(.large)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(model.subtitle)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    Text(model.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SystemPromptEditor: View {
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $viewModel.systemPrompt)
            .font(.system(.body, design: .monospaced))
            .focused($isFocused)
            .padding(4)
            .navigationTitle("System Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFocused = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.resetSystemPrompt()
                        } label: {
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(viewModel.isDefaultPrompt)
                }
            }
    }
}
