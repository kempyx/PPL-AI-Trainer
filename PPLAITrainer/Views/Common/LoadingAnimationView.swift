import SwiftUI

struct LoadingAnimationView: View {
    enum Presentation {
        case inline
        case panel
    }

    let requestCount: Int
    var title: String = "AI is thinking"
    var presentation: Presentation = .inline
    @State private var spin = false
    @State private var breathe = false
    @State private var glow = false

    private let messages = [
        "Cross-checking charts and references...",
        "Building an exam-ready explanation...",
        "Turning complex ideas into plain language..."
    ]

    var body: some View {
        let content = HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .mint, .cyan],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: spin)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), Color.cyan.opacity(0.6), Color.blue.opacity(0.35)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 20
                        )
                    )
                    .frame(width: 22, height: 22)
                    .scaleEffect(breathe ? 1.08 : 0.88)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: breathe)

                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                TimelineView(.periodic(from: .now, by: 1.6)) { timeline in
                    Text(statusMessage(for: timeline.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 150, height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.7), .blue, .mint.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: glow ? 150 : 42, height: 4)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)

        Group {
            if presentation == .panel {
                content
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.12), Color.blue.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                    )
            } else {
                content
                    .background(Color(.secondarySystemBackground).opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            spin = true
            breathe = true
            glow = true
        }
    }

    private func statusMessage(for date: Date) -> String {
        let interval = Int(date.timeIntervalSinceReferenceDate / 1.6)
        let index = (interval + requestCount) % messages.count
        return messages[index]
    }
}

#Preview {
    LoadingAnimationView(requestCount: 1)
}
