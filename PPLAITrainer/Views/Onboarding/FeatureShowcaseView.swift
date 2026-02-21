import SwiftUI

struct FeatureShowcaseView: View {
    let onContinue: () -> Void
    @State private var currentPage = 0
    
    private let features = [
        Feature(
            icon: "brain.head.profile",
            color: .purple,
            title: "Smart Spaced Repetition",
            description: "Questions you struggle with appear more often. Master them and they'll space out automatically."
        ),
        Feature(
            icon: "sparkles",
            color: .blue,
            title: "AI-Powered Explanations",
            description: "Get instant explanations for any question. Choose from OpenAI, Google Gemini, Grok, or Apple Intelligence."
        ),
        Feature(
            icon: "chart.line.uptrend.xyaxis",
            color: .green,
            title: "Track Your Progress",
            description: "See your readiness score, weak areas, streaks, and detailed stats across all 13 subjects."
        )
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            TabView(selection: $currentPage) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 400)
            
            Button {
                if currentPage < features.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onContinue()
                }
            } label: {
                Text(currentPage < features.count - 1 ? "Next" : "Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)
            
            Button("Skip") {
                onContinue()
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 48)
        }
        .padding()
    }
}

struct Feature {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

struct FeatureCard: View {
    let feature: Feature
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: feature.icon)
                .font(.system(size: 80))
                .foregroundStyle(feature.color)
            
            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    FeatureShowcaseView(onContinue: {})
}
