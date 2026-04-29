import SwiftUI
import AppKit

struct PanelFooter: View {
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                KeyChip("⌃")
                KeyChip("⌥")
                KeyChip("C")
            }
            Text("toggle")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(Studio.textMuted)
            Spacer()
            quitButton
        }
        .padding(.top, 4)
    }

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Studio.textPrimary.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Studio.chipFill)
                        .overlay(Capsule().stroke(Studio.chipStroke, lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}
