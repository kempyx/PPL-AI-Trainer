import SwiftUI

// MARK: - Shake Animation
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0))
    }
}

extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}

// MARK: - Flash Animation
struct FlashModifier: ViewModifier {
    let color: Color
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                color.opacity(opacity)
                    .animation(.easeInOut(duration: 0.3), value: opacity)
            )
            .onAppear {
                opacity = 0.3
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    opacity = 0
                }
            }
    }
}

extension View {
    func flash(color: Color) -> some View {
        modifier(FlashModifier(color: color))
    }
}

// MARK: - Scale Bounce
extension View {
    func scaleBounce(trigger: Bool) -> some View {
        scaleEffect(trigger ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: trigger)
    }
}

// MARK: - Staggered Fade In
struct StaggeredFadeIn: ViewModifier {
    let index: Int
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.1)) {
                    opacity = 1
                    offset = 0
                }
            }
    }
}

extension View {
    func staggeredFadeIn(index: Int) -> some View {
        modifier(StaggeredFadeIn(index: index))
    }
}

// MARK: - Pulse Animation
extension View {
    func pulse(isActive: Bool) -> some View {
        scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
    }
}

#Preview {
    Text("Sample Text")
        .staggeredFadeIn(index: 0)
}
