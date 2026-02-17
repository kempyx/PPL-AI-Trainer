import SwiftUI

struct AISettingsView: View {
    @State var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                providerCard
                confirmCard
                systemPromptCard
                dangerZoneCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { viewModel.saveCurrentKey() }
        .alert("Reset All Keys?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllKeys()
            }
        } message: {
            Text("This will delete all stored API keys.")
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

    // MARK: - Confirm Before Sending

    private var confirmCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "checkmark.shield", title: "Confirmation", color: .purple)

                Toggle("Confirm before sending", isOn: $viewModel.confirmBeforeSending)
            }
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
    
    // MARK: - Danger Zone
    
    private var dangerZoneCard: some View {
        SettingsCard {
            VStack(spacing: 12) {
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
}
