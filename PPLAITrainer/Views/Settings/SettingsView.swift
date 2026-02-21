import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @Environment(\.dependencies) private var dependencies
    @State private var showResetConfirmation = false
    @State private var showLegSuggestion = false
    @State private var dismissedSuggestion: ExamLeg?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    examScheduleCard
                    studyPreferencesCard
                    appearanceCard
                    feedbackCard
                    aiAssistantCard
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
            .alert("Reset All Progress?", isPresented: $showResetProgressConfirmation) {
                TextField("Type RESET to confirm", text: $resetConfirmationText)
                Button("Cancel", role: .cancel) {
                    resetConfirmationText = ""
                }
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
                .disabled(resetConfirmationText != "RESET")
            } message: {
                Text("This will erase all XP, achievements, streaks, bookmarks, notes, answer history, and SRS progress. Type RESET to confirm.")
            }
            .alert("Switch to \(viewModel.suggestedLeg?.shortTitle ?? "")?", isPresented: $showLegSuggestion) {
                Button("Not Now", role: .cancel) {
                    dismissedSuggestion = viewModel.suggestedLeg
                }
                Button("Switch") {
                    viewModel.acceptSuggestedLeg()
                    dismissedSuggestion = nil
                }
            } message: {
                if let suggested = viewModel.suggestedLeg {
                    Text("\(suggested.emoji) \(suggested.title) exam is coming up soon. Switch to focus on it?")
                }
            }
        }
        .onAppear {
            checkLegSuggestion()
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

    private var examScheduleCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "calendar", title: "Exam Schedule", color: .cyan)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Leg")
                        .font(.subheadline.weight(.medium))
                    
                    Picker("Active Leg", selection: $viewModel.activeLeg) {
                        ForEach(ExamLeg.allCases) { leg in
                            Text("\(leg.emoji) \(leg.shortTitle)").tag(leg)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(viewModel.activeLeg.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exam Dates")
                        .font(.subheadline.weight(.medium))
                    
                    examDateRow(leg: .technicalLegal, date: $viewModel.examDateLeg1)
                    examDateRow(leg: .humanEnvironment, date: $viewModel.examDateLeg2)
                    examDateRow(leg: .planningNavigation, date: $viewModel.examDateLeg3)
                }
            }
        }
    }
    
    private func examDateRow(leg: ExamLeg, date: Binding<Date?>) -> some View {
        HStack {
            Text(leg.emoji)
            Text(leg.shortTitle)
                .font(.subheadline)
            Spacer()
            if let examDate = date.wrappedValue {
                DatePicker("", selection: Binding(
                    get: { examDate },
                    set: { date.wrappedValue = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
            } else {
                Button("Set Date") {
                    date.wrappedValue = Calendar.current.date(byAdding: .month, value: 2, to: Date())
                }
                .font(.caption)
            }
        }
    }
    
    private func checkLegSuggestion() {
        if let suggested = viewModel.suggestedLeg, suggested != dismissedSuggestion {
            showLegSuggestion = true
        }
    }

    // MARK: - Study Preferences
    
    private var studyPreferencesCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "book.fill", title: "Study Preferences", color: .green)
                
                Toggle("Daily Reminders", isOn: Binding(
                    get: { viewModel.settingsManager.notificationsEnabled },
                    set: { viewModel.settingsManager.notificationsEnabled = $0 }
                ))
                
                if viewModel.settingsManager.notificationsEnabled {
                    HStack {
                        Text("Reminder Time")
                            .font(.subheadline)
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { viewModel.settingsManager.reminderTime },
                            set: { viewModel.settingsManager.reminderTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    }
                }
                
                Toggle("Streak Protection", isOn: Binding(
                    get: { viewModel.settingsManager.streakReminderEnabled },
                    set: { viewModel.settingsManager.streakReminderEnabled = $0 }
                ))
            }
            .animation(.default, value: viewModel.settingsManager.notificationsEnabled)
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

    private var notificationsCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "bell.fill", title: "Notifications", color: .red)
                
                Toggle("Daily Reminders", isOn: Binding(
                    get: { viewModel.settingsManager.notificationsEnabled },
                    set: { viewModel.settingsManager.notificationsEnabled = $0 }
                ))
                
                Toggle("Streak Protection", isOn: Binding(
                    get: { viewModel.settingsManager.streakReminderEnabled },
                    set: { viewModel.settingsManager.streakReminderEnabled = $0 }
                ))
            }
        }
    }
    
    private var feedbackCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "hand.tap.fill", title: "Feedback", color: .purple)
                
                Toggle("Haptic Feedback", isOn: Binding(
                    get: { viewModel.settingsManager.hapticFeedbackEnabled },
                    set: { viewModel.settingsManager.hapticFeedbackEnabled = $0 }
                ))
                
                Toggle("Sound Effects", isOn: Binding(
                    get: { viewModel.settingsManager.soundEnabled },
                    set: { viewModel.settingsManager.soundEnabled = $0 }
                ))
            }
        }
    }
    
    // MARK: - AI Assistant
    
    private var aiAssistantCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "sparkles", title: "AI Assistant", color: .pink)
                
                Toggle("Enable AI Features", isOn: $viewModel.aiEnabled)
                
                if viewModel.aiEnabled {
                    NavigationLink {
                        AISettingsView(viewModel: viewModel)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active Model")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.selectedProvider.availableModels.first(where: { $0.id == viewModel.selectedModel })?.displayName ?? viewModel.selectedModel)
                                    .font(.subheadline.weight(.medium))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .animation(.default, value: viewModel.aiEnabled)
        }
    }

    @State private var showResetProgressConfirmation = false
    @State private var resetConfirmationText = ""

    private func resetProgress() {
        guard let deps = dependencies else { return }
        guard resetConfirmationText == "RESET" else { return }
        try? deps.databaseManager.resetAllProgress()
        deps.settingsManager.resetUserProgress()
        deps.gamificationService.resetSession()
        NotificationCenter.default.post(name: .didResetProgress, object: nil)
        resetConfirmationText = ""
    }

    private var dangerZoneCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Danger Zone")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("These actions cannot be undone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                Button(role: .destructive) {
                    showResetProgressConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All Progress")
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                
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

// MARK: - Helper Components

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsSectionHeader: View {
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

struct ModelRow: View {
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

struct SystemPromptEditor: View {
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var isFocused: Bool

    private let templates: [String: String] = [
        "Concise": "You are a concise flight instructor. Keep explanations under 120 words.",
        "Detailed": "You are an experienced flight instructor. Explain with steps, pitfalls, and practical examples.",
        "Exam Focus": "You are a PPL exam coach. Explain why the correct answer is correct and why distractors fail."
    ]

    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $viewModel.systemPrompt)
                .font(.system(.body, design: .monospaced))
                .focused($isFocused)
                .padding(4)
                .frame(maxHeight: .infinity)

            HStack {
                Text("\(viewModel.systemPrompt.count) chars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reset") { viewModel.resetSystemPrompt() }
                    .font(.caption.weight(.semibold))
                    .disabled(viewModel.isDefaultPrompt)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(templates.keys), id: \.self) { key in
                        Button(key) { viewModel.systemPrompt = templates[key] ?? viewModel.systemPrompt }
                            .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("System Prompt")
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
    SettingsView(viewModel: SettingsViewModel(keychainStore: deps.keychainStore, settingsManager: deps.settingsManager))
        .environment(\.dependencies, deps)
}
