import SwiftUI

struct AISetupPageView: View {
    @Binding var aiEnabled: Bool
    @Binding var selectedProvider: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            Text("Enable AI Assistant")
                .font(.title2.weight(.bold))
            Text("Optional: turn on AI hints and explanations now. Apple Intelligence works offline when available.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Toggle("Enable AI features", isOn: $aiEnabled)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppCornerRadius.medium))

            Picker("Preferred Provider", selection: $selectedProvider) {
                Text("Apple Intelligence").tag("apple")
                Text("OpenAI").tag("openai")
                Text("Gemini").tag("gemini")
                Text("Grok").tag("grok")
            }
            .pickerStyle(.segmented)
            .disabled(!aiEnabled)

            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .padding()
    }
}

#Preview {
    AISetupPageView(
        aiEnabled: .constant(true),
        selectedProvider: .constant("openai"),
        onContinue: {}
    )
}
