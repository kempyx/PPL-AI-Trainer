import SwiftUI

enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 14
    static let large: CGFloat = 20
}

extension Color {
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    static let info = Color.blue
    static let xp = Color.yellow
    static let ai = Color.purple
    static let streakActive = Color.warning
    static let streakInactive = Color.gray
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.info)
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.info)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.info.opacity(0.1))
            .cornerRadius(AppCornerRadius.medium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .cornerRadius(AppCornerRadius.medium)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
