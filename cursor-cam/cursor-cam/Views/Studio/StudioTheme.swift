import SwiftUI

/// Design tokens for the Cursor-Cam settings panel.
/// Centralizes typography, spacing, and color so the panel reads
/// like a single coherent surface.
enum Studio {
    static let panelWidth: CGFloat = 380
    static let maxPanelHeight: CGFloat = 620
    static let sidePadding: CGFloat = 18
    static let sectionGap: CGFloat = 18
    static let rowGap: CGFloat = 10

    static let textPrimary = Color.white.opacity(0.92)
    static let textMuted = Color.white.opacity(0.45)
    static let textBody = Color.white.opacity(0.7)
    static let hairline = Color.white.opacity(0.07)
    static let chipFill = Color.white.opacity(0.05)
    static let chipStroke = Color.white.opacity(0.08)
    static let liveRed = Color(red: 0.96, green: 0.32, blue: 0.34)

    static func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.4)
            .foregroundStyle(textMuted)
    }

    static func rowLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(textBody)
    }
}

/// Hairline divider that sits between sections.
struct StudioHairline: View {
    var body: some View {
        Rectangle().fill(Studio.hairline).frame(height: 0.5)
    }
}

/// Stacked label-above-control layout used by every form row.
struct StudioStack<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Studio.rowLabel(title)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
