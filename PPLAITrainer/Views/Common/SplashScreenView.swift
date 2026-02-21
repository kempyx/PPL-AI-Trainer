import SwiftUI

struct SplashScreenView: View {
    @State private var showAirplane = false
    @State private var showBrain = false
    @State private var showMap = false
    @State private var showTitle = false
    @State private var rotateSymbols = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.teal.opacity(0.3), Color.orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Symbol triangle
                ZStack {
                    // Top - Airplane (Technical)
                    Image(systemName: "airplane")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.blue)
                        .offset(y: -60)
                        .scaleEffect(showAirplane ? 1 : 0.3)
                        .opacity(showAirplane ? 1 : 0)
                        .rotationEffect(.degrees(rotateSymbols ? 360 : 0))
                    
                    // Bottom Left - Brain (Human)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.teal)
                        .offset(x: -50, y: 40)
                        .scaleEffect(showBrain ? 1 : 0.3)
                        .opacity(showBrain ? 1 : 0)
                        .rotationEffect(.degrees(rotateSymbols ? 360 : 0))
                    
                    // Bottom Right - Map (Navigation)
                    Image(systemName: "map")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.orange)
                        .offset(x: 50, y: 40)
                        .scaleEffect(showMap ? 1 : 0.3)
                        .opacity(showMap ? 1 : 0)
                        .rotationEffect(.degrees(rotateSymbols ? 360 : 0))
                    
                    // Center circle
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showTitle ? 1 : 0.5)
                        .opacity(showTitle ? 1 : 0)
                }
                .frame(height: 200)
                
                // Title
                VStack(spacing: 8) {
                    Text("PPL Theory Trainer")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Master Your Aviation Knowledge")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Stagger the symbol appearances
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            showAirplane = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showBrain = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showMap = true
        }
        
        withAnimation(.easeInOut(duration: 0.5).delay(0.5)) {
            showTitle = true
        }
        
        // Subtle rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(0.6)) {
            rotateSymbols = true
        }
        
        // Dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashScreenView {}
}
