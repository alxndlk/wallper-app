import SwiftUI

struct WhiteLinearProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(height: 3)

            Capsule()
                .fill(Color.white)
                .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * 180, height: 3)
                .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
        }
    }
}
