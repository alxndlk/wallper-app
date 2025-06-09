import SwiftUI

struct AnimatedStar: View {
    let angle: Double
    let distance: CGFloat
    let delay: Double

    @State private var isAnimated = false

    var body: some View {
        let x = cos(angle) * distance
        let y = sin(angle) * distance

        Image(systemName: "sparkle")
            .foregroundColor(.white.opacity(0.5))
            .font(.system(size: CGFloat.random(in: 8...14)))
            .scaleEffect(isAnimated ? 0.4 : 1.6)
            .opacity(isAnimated ? 0 : 1)
            .shadow(color: .white.opacity(0.15), radius: 4)
            .offset(x: isAnimated ? x : 0, y: isAnimated ? y : 0)
            .rotationEffect(.degrees(isAnimated ? Double.random(in: 90...360) : 0))
            .onAppear {
                animateLoop()
            }
    }

    private func animateLoop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 1.5)) {
                isAnimated = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + 1.0) {
                isAnimated = false
                animateLoop()
            }
        }
    }
}
