import SwiftUI

/// Slider with an inline monospaced value chip on the right.
/// Uses native SwiftUI `Slider` for accessibility/keyboard support and
/// adds a value pill so the current setting is always legible.
struct CamSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    let format: (Double) -> String

    var body: some View {
        HStack(spacing: 12) {
            slider
            valueChip
        }
    }

    @ViewBuilder
    private var slider: some View {
        if let step {
            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
                .tint(Color.accentColor)
        } else {
            Slider(value: $value, in: range)
                .controlSize(.small)
                .tint(Color.accentColor)
        }
    }

    private var valueChip: some View {
        Text(format(value))
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(Studio.textPrimary.opacity(0.85))
            .frame(width: 38, alignment: .trailing)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(Studio.chipFill)
                    .overlay(Capsule().stroke(Studio.chipStroke, lineWidth: 0.5))
            )
    }
}
