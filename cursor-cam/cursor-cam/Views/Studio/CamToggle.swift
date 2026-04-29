import SwiftUI

struct CamToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            ZStack {
                Capsule()
                    .fill(isOn ? Color.accentColor : Color.white.opacity(0.10))
                HStack {
                    if isOn { Spacer() }
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .padding(2)
                    if !isOn { Spacer() }
                }
            }
            .frame(width: 34, height: 18)
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

struct PowerSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Capsule()
                        .fill(isOn ? Color.accentColor : Color.white.opacity(0.08))
                    HStack {
                        if isOn { Spacer() }
                        Circle()
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                            .padding(2)
                        if !isOn { Spacer() }
                    }
                }
                .frame(width: 36, height: 18)
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                Text(isOn ? "ON" : "OFF")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(isOn ? Color.accentColor : Studio.textMuted)
                    .frame(width: 24, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}
