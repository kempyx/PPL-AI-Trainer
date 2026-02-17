import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var rotation: Double
    var size: CGFloat
}

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    let colors: [Color] = [.yellow, .orange, .pink, .blue, .green, .purple]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    var contextCopy = context
                    contextCopy.translateBy(x: particle.position.x, y: particle.position.y)
                    contextCopy.rotate(by: .degrees(particle.rotation))
                    
                    let rect = CGRect(x: -particle.size/2, y: -particle.size/2, width: particle.size, height: particle.size)
                    contextCopy.fill(Path(rect), with: .color(particle.color))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            emit()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func emit() {
        let screenWidth = UIScreen.main.bounds.width
        
        for _ in 0..<80 {
            let particle = Particle(
                position: CGPoint(x: screenWidth / 2, y: -20),
                velocity: CGPoint(
                    x: Double.random(in: -200...200),
                    y: Double.random(in: 100...300)
                ),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...12)
            )
            particles.append(particle)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func updateParticles() {
        let gravity: CGFloat = 500
        let dt: CGFloat = 1/60
        
        particles = particles.compactMap { particle in
            var updated = particle
            updated.velocity.y += gravity * dt
            updated.position.x += updated.velocity.x * dt
            updated.position.y += updated.velocity.y * dt
            updated.rotation += 5
            
            // Remove if off screen
            if updated.position.y > UIScreen.main.bounds.height + 50 {
                return nil
            }
            return updated
        }
        
        // Stop timer when all particles are gone
        if particles.isEmpty {
            timer?.invalidate()
        }
    }
}
