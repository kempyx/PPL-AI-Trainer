import SwiftUI

struct AISettingsView: View {
    @State var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                providerCard
                confirmCard
                promptLibraryCard
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

                Menu {
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(AIProviderType.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                } label: {
                    HStack {
                        Label(viewModel.selectedProvider.displayName, systemImage: "cpu")
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppCornerRadius.small))
                }

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

                Divider()

                Stepper(value: $viewModel.hintImageCount, in: 1...3) {
                    HStack {
                        Text("Deep Hint images")
                        Spacer()
                        Text("\(viewModel.hintImageCount)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Controls how many generated images are requested for Deep Hint (when supported).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Prompt Library

    private var promptLibraryCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SettingsSectionHeader(icon: "text.bubble", title: "AI Prompts", color: .orange)
                    Spacer()
                    if viewModel.modifiedPromptCount > 0 {
                        Text("\(viewModel.modifiedPromptCount) modified")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }

                Text("All AI providers use these shared prompts. Customize quick actions and templates in one place.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                NavigationLink {
                    AIPromptLibraryView(viewModel: viewModel)
                } label: {
                    HStack {
                        Text("Edit Prompts")
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

#Preview {
    let deps = Dependencies.preview
    AISettingsView(viewModel: SettingsViewModel(keychainStore: deps.keychainStore, settingsManager: deps.settingsManager))
        .environment(\.dependencies, deps)
}
