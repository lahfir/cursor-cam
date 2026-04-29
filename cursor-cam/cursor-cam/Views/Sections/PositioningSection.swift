import SwiftUI

struct PositioningSection: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        StudioCard(title: "POSITIONING") {
            VStack(alignment: .leading, spacing: Studio.rowGap) {
                modeRow
                if settings.positioningMode == .pinToCorner { cornerRow }
                if settings.positioningMode == .followCursor { offsetRow }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.85), value: settings.positioningMode)
        }
    }

    private var modeRow: some View {
        StudioStack(title: "Mode") {
            CamSegmented(
                selection: $settings.positioningMode,
                options: [
                    (PositioningMode.followCursor, "Follow"),
                    (PositioningMode.pinToCorner, "Pin"),
                    (PositioningMode.freeDrag, "Drag")
                ]
            )
        }
    }

    private var cornerRow: some View {
        StudioStack(title: "Corner") {
            CamSegmented(
                selection: $settings.pinnedCorner,
                options: [
                    (Corner.topLeft, "TL"),
                    (Corner.topRight, "TR"),
                    (Corner.bottomLeft, "BL"),
                    (Corner.bottomRight, "BR")
                ]
            )
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var offsetRow: some View {
        StudioStack(title: "Offset") {
            CamSegmented(
                selection: $settings.cursorPosition,
                options: [
                    (CursorPosition.center, "Ctr"),
                    (CursorPosition.topLeft, "TL"),
                    (CursorPosition.topRight, "TR"),
                    (CursorPosition.bottomLeft, "BL"),
                    (CursorPosition.bottomRight, "BR")
                ]
            )
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
