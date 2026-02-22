import SwiftUI
import UIKit

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @Environment(\.dependencies) private var dependencies
    @State private var showResetConfirmation = false
    @State private var showLegSuggestion = false
    @State private var dismissedSuggestion: ExamLeg?
    @State private var kpiSnapshot: KPISnapshot?
    @State private var kpiMarkdownReport: String = ""
    @State private var showKPIReportSheet = false

    private struct KPISnapshot {
        let windowDays: Int
        let activeDays: Int
        let goalHitDays: Int
        let answeredQuestions: Int
        let sessionStarts: Int
        let sessionCompletions: Int
        let hintRequests: Int
        let contextualExplainRequests: Int
        let inlineAIRequests: Int
        let mockExamCompletions: Int
        let wrongQueueCount: Int

        var completionRate: Double {
            guard sessionStarts > 0 else { return 0 }
            return Double(sessionCompletions) / Double(sessionStarts)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    examScheduleCard
                    studyPreferencesCard
                    appearanceCard
                    feedbackCard
                    aiAssistantCard
                    productMetricsCard
                    experimentsCard
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
            .sheet(isPresented: $showKPIReportSheet) {
                NavigationStack {
                    ScrollView {
                        Text(kpiMarkdownReport)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle("KPI Report")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            HStack(spacing: 16) {
                                Button("Copy") {
                                    UIPasteboard.general.string = kpiMarkdownReport
                                }
                                ShareLink(item: kpiMarkdownReport) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            checkLegSuggestion()
            refreshKPISnapshot()
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

                Toggle("Show Premium Content", isOn: $viewModel.showPremiumContent)
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

    private var productMetricsCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SettingsSectionHeader(icon: "chart.xyaxis.line", title: "Product Metrics (7d)", color: .blue)
                    Spacer()
                    Button("Export MD") {
                        prepareKPIReport()
                    }
                    .font(.caption.weight(.semibold))
                    Button("Refresh") {
                        refreshKPISnapshot()
                    }
                    .font(.caption.weight(.semibold))
                }

                if let kpiSnapshot {
                    metricRow("Active study days", value: "\(kpiSnapshot.activeDays)/\(kpiSnapshot.windowDays)")
                    metricRow("Goal hit days", value: "\(kpiSnapshot.goalHitDays)")
                    metricRow("Questions answered", value: "\(kpiSnapshot.answeredQuestions)")
                    metricRow("Quiz completion", value: "\(Int(kpiSnapshot.completionRate * 100))%")
                    metricRow("Hint requests", value: "\(kpiSnapshot.hintRequests)")
                    metricRow("Context explain", value: "\(kpiSnapshot.contextualExplainRequests)")
                    metricRow("Inline AI requests", value: "\(kpiSnapshot.inlineAIRequests)")
                    metricRow("Mock exams done", value: "\(kpiSnapshot.mockExamCompletions)")
                    metricRow("Wrong-answer queue", value: "\(kpiSnapshot.wrongQueueCount)")
                } else {
                    Text("No metrics yet. Complete a few sessions to populate this panel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var experimentsCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionHeader(icon: "slider.horizontal.3", title: "Experiments (QA)", color: .orange)

                ForEach(AppExperiment.allCases) { experiment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(experiment.title)
                            .font(.subheadline.weight(.semibold))
                        Text("Assigned: \(viewModel.settingsManager.experimentVariant(for: experiment))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Menu {
                            Button("Auto") {
                                viewModel.settingsManager.setExperimentOverride(nil, for: experiment)
                            }
                            ForEach(experiment.variants, id: \.self) { variant in
                                Button(variant) {
                                    viewModel.settingsManager.setExperimentOverride(variant, for: experiment)
                                }
                            }
                        } label: {
                            HStack {
                                Text("Override: \(viewModel.settingsManager.experimentOverride(for: experiment) ?? "Auto")")
                                    .font(.caption.weight(.medium))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: AppCornerRadius.small))
                        }
                    }
                }

                Button("Clear All Overrides") {
                    viewModel.settingsManager.clearExperimentOverrides()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            }
        }
    }

    private func metricRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
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
        refreshKPISnapshot()
    }

    private func refreshKPISnapshot() {
        guard let deps = dependencies else { return }
        let windowDays = 7
        let fromDate = Calendar.current.date(byAdding: .day, value: -(windowDays - 1), to: Date()) ?? Date()
        let formatter = DateFormatter.yyyyMMdd
        let from = formatter.string(from: fromDate)
        let to = formatter.string(from: Date())

        let eventCounts = (try? deps.databaseManager.fetchInteractionEventCounts(from: fromDate)) ?? [:]
        let studyDays = (try? deps.databaseManager.fetchStudyDays(from: from, to: to)) ?? []
        let answeredQuestions = studyDays.reduce(0) { $0 + $1.questionsAnswered }
        let goalTarget = max(viewModel.settingsManager.dailyGoalTarget, 1)
        let goalHitDays = studyDays.filter { $0.questionsAnswered >= goalTarget }.count
        let wrongQueueCount = (try? deps.databaseManager.fetchWrongAnswerQuestionIds().count) ?? 0

        kpiSnapshot = KPISnapshot(
            windowDays: windowDays,
            activeDays: studyDays.count,
            goalHitDays: goalHitDays,
            answeredQuestions: answeredQuestions,
            sessionStarts: eventCounts["quiz_session_started"] ?? 0,
            sessionCompletions: eventCounts["quiz_session_completed"] ?? 0,
            hintRequests: eventCounts["quiz_hint_requested"] ?? 0,
            contextualExplainRequests: eventCounts["quiz_contextual_explain_requested"] ?? 0,
            inlineAIRequests: eventCounts["quiz_inline_ai_requested"] ?? 0,
            mockExamCompletions: eventCounts["mock_exam_completed"] ?? 0,
            wrongQueueCount: wrongQueueCount
        )
    }

    private func prepareKPIReport() {
        if kpiSnapshot == nil {
            refreshKPISnapshot()
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let now = dateFormatter.string(from: Date())
        let assignments = viewModel.settingsManager.experimentAssignments()
        let assignmentLines = assignments.map {
            "- \($0.experiment.title): `\($0.resolved)` (override: \($0.override ?? "Auto"))"
        }.joined(separator: "\n")

        if let kpiSnapshot {
            kpiMarkdownReport = """
            # PPL AI Trainer KPI Snapshot

            Generated: \(now)
            Window: Last \(kpiSnapshot.windowDays) days

            ## Engagement
            - Active study days: \(kpiSnapshot.activeDays)/\(kpiSnapshot.windowDays)
            - Questions answered: \(kpiSnapshot.answeredQuestions)
            - Goal-hit days: \(kpiSnapshot.goalHitDays)

            ## Session Flow
            - Quiz sessions started: \(kpiSnapshot.sessionStarts)
            - Quiz sessions completed: \(kpiSnapshot.sessionCompletions)
            - Completion rate: \(Int(kpiSnapshot.completionRate * 100))%
            - Wrong-answer queue size: \(kpiSnapshot.wrongQueueCount)

            ## AI Support Usefulness
            - Hint requests: \(kpiSnapshot.hintRequests)
            - Contextual explain requests: \(kpiSnapshot.contextualExplainRequests)
            - Inline AI requests: \(kpiSnapshot.inlineAIRequests)

            ## Mock Exam Outcomes
            - Mock exam completions: \(kpiSnapshot.mockExamCompletions)

            ## Active Experiments
            \(assignmentLines)
            """
        } else {
            kpiMarkdownReport = """
            # PPL AI Trainer KPI Snapshot

            Generated: \(now)

            No KPI data available yet. Complete a study session, then refresh metrics.
            """
        }
        showKPIReportSheet = true
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
