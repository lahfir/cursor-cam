import SwiftUI

/// Shape, size, mirror, opacity, and shadow controls.
/// Visual tone for the cam — the most-frequently-changed bucket.
struct AppearanceSection: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Studio.rowGap) {
            Studio.sectionLabel("APPEARANCE")
            shapeRow
            sizeAndMirror
            opacityRow
            shadowRow
        }
    }

    private var shapeRow: some View {
        StudioStack(title: "Shape") {
            CamSegmented(
                selection: $settings.cameraShape,
                options: [
                    (CameraShape.circle, "Circle"),
                    (CameraShape.roundedSquare, "Round"),
                    (CameraShape.horizontal, "Wide"),
                    (CameraShape.vertical, "Tall")
                ]
            )
        }
    }

    private var sizeAndMirror: some View {
        HStack(alignment: .bottom, spacing: 12) {
            StudioStack(title: "Size") {
                CamSegmented(
                    selection: $settings.cameraSize,
                    options: [
                        (CameraSize.small, "S"),
                        (CameraSize.medium, "M"),
                        (CameraSize.large, "L")
                    ]
                )
            }
            StudioStack(title: "Mirror") {
                HStack {
                    CamToggle(isOn: $settings.isMirrored)
                    Spacer(minLength: 0)
                }
                .frame(height: 30)
            }
            .frame(width: 70)
        }
    }

    private var opacityRow: some View {
        StudioStack(title: "Opacity") {
            CamSlider(
                value: $settings.baseOpacity,
                range: 0.2...1.0,
                format: { "\(Int($0 * 100))%" }
            )
        }
    }

    private var shadowRow: some View {
        StudioStack(title: "Shadow") {
            HStack(spacing: 10) {
                CamToggle(isOn: $settings.shadowEnabled)
                if settings.shadowEnabled {
                    CamSegmented(
                        selection: $settings.shadowIntensity,
                        options: [
                            (ShadowIntensity.light, "Light"),
                            (ShadowIntensity.medium, "Medium"),
                            (ShadowIntensity.heavy, "Heavy")
                        ]
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: settings.shadowEnabled)
        }
    }
}
