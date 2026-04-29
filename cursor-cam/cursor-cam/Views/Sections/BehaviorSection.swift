import SwiftUI

struct BehaviorSection: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var permissionsManager: PermissionsManager

    var body: some View {
        VStack(alignment: .leading, spacing: Studio.rowGap) {
            Studio.sectionLabel("BEHAVIOR")
            velocityRow
            edgeAwareRow
            idleDimRow
            if settings.idleDimEnabled { idleSliders }
            clickFeedbackRow
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: settings.idleDimEnabled)
    }

    private var velocityRow: some View {
        CamRow(
            title: "Velocity scaling",
            subtitle: "Pulse cam on quick cursor moves"
        ) {
            CamToggle(isOn: $settings.velocityScalingEnabled)
        }
    }

    private var edgeAwareRow: some View {
        CamRow(
            title: "Edge-aware offset",
            subtitle: "Cam moves to opposite side at edges"
        ) {
            CamToggle(isOn: $settings.edgeAwareOffsetEnabled)
        }
    }

    private var idleDimRow: some View {
        CamRow(
            title: "Idle auto-dim",
            subtitle: "Fade when cursor goes still"
        ) {
            CamToggle(isOn: $settings.idleDimEnabled)
        }
    }

    private var idleSliders: some View {
        VStack(spacing: Studio.rowGap) {
            StudioStack(title: "Timeout") {
                CamSlider(
                    value: $settings.idleTimeoutSeconds,
                    range: 1...10,
                    step: 1,
                    format: { "\(Int($0))s" }
                )
            }
            StudioStack(title: "Dimmed") {
                CamSlider(
                    value: $settings.idleDimmedOpacity,
                    range: 0...0.8,
                    format: { "\(Int($0 * 100))%" }
                )
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var clickFeedbackRow: some View {
        CamRow(
            title: "Click feedback",
            subtitle: permissionsManager.accessibilityPermissionGranted
                ? "Expanding ring on click"
                : "Needs Accessibility permission"
        ) {
            CamToggle(isOn: $settings.clickFeedbackEnabled)
                .disabled(!permissionsManager.accessibilityPermissionGranted)
                .opacity(permissionsManager.accessibilityPermissionGranted ? 1 : 0.4)
        }
    }
}
