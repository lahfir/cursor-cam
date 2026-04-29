import AppKit
import Combine
import SwiftUI

@MainActor
final class ClickFeedbackState: ObservableObject {
    @Published var pulse: CGFloat = 1.0
    @Published var bloomScale: CGFloat = 1.0
    @Published var bloomOpacity: Double = 0.0

    func fire() {
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        bloomScale = 1.0
        bloomOpacity = 0.75
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.18)) { bloomOpacity = 0 }
            return
        }

        withAnimation(.easeOut(duration: 0.45)) {
            bloomScale = 1.55
            bloomOpacity = 0
        }
        withAnimation(.spring(response: 0.16, dampingFraction: 0.55)) {
            pulse = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            withAnimation(.spring(response: 0.36, dampingFraction: 0.6)) {
                self?.pulse = 1.0
            }
        }
    }
}

struct ClickBloomView: View {
    @ObservedObject var state: ClickFeedbackState
    let shape: AnyShape
    let camWidth: CGFloat
    let camHeight: CGFloat

    var body: some View {
        shape
            .fill(RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.85),
                    Color.accentColor.opacity(0.45),
                    Color.accentColor.opacity(0)
                ],
                center: .center,
                startRadius: 2,
                endRadius: max(camWidth, camHeight) * 0.7
            ))
            .frame(width: camWidth * 1.45, height: camHeight * 1.45)
            .scaleEffect(state.bloomScale)
            .opacity(state.bloomOpacity)
            .blur(radius: 10)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }
}
