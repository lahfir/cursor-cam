import SwiftUI

struct StatusPill: View {
    let isOn: Bool

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            dot
            Text(isOn ? "LIVE" : "STANDBY")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(isOn ? Studio.liveRed : Studio.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(background)
        .onAppear { startPulseIfNeeded() }
        .onChange(of: isOn) { _, _ in
            pulse = false
            startPulseIfNeeded()
        }
    }

    private var dot: some View {
        Circle()
            .fill(isOn ? Studio.liveRed : Color.gray.opacity(0.6))
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(Studio.liveRed.opacity(isOn ? 0.5 : 0), lineWidth: 1)
                    .scaleEffect(pulse ? 2.2 : 1)
                    .opacity(pulse ? 0 : 1)
            )
    }

    private var background: some View {
        Capsule()
            .fill(isOn ? Studio.liveRed.opacity(0.12) : Color.white.opacity(0.04))
            .overlay(Capsule().stroke(
                isOn ? Studio.liveRed.opacity(0.35) : Studio.chipStroke,
                lineWidth: 0.5
            ))
    }

    private func startPulseIfNeeded() {
        guard isOn else { return }
        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
            pulse = true
        }
    }
}
