import SwiftUI

/// A single selectable row in the camera picker. Hover and selected states are
/// rendered inline (not via `List`) so the row blends with the studio aesthetic.
struct CameraRow: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                videoIcon
                Text(name)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Studio.textPrimary : Studio.textPrimary.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hovered = $0 }
    }

    private var videoIcon: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.05))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle().stroke(
                        isSelected ? Color.accentColor.opacity(0.5) : Studio.chipStroke,
                        lineWidth: 0.5
                    )
                )
            Image(systemName: "video.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Studio.textMuted)
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(rowFill)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.25) : Color.clear, lineWidth: 0.5)
            )
    }

    private var rowFill: Color {
        if isSelected { return Color.accentColor.opacity(0.08) }
        return hovered ? Color.white.opacity(0.04) : Color.clear
    }
}

/// Empty state for the camera picker when no cameras are available.
struct EmptyCameraRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Studio.textMuted)
            Text("No camera available")
                .font(.system(size: 12))
                .foregroundStyle(Studio.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Studio.chipFill)
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Studio.chipStroke, lineWidth: 0.5))
        )
    }
}
