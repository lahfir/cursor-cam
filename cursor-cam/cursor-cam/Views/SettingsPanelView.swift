import SwiftUI

struct SettingsPanelView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var overlayManager: OverlayWindowManager
    @ObservedObject var permissionsManager: PermissionsManager

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    PanelHeader(
                        settings: settings,
                        cameraManager: cameraManager,
                        overlayManager: overlayManager
                    )
                    .padding(.bottom, 4)
                    AppearanceSection(settings: settings)
                    PositioningSection(settings: settings)
                    BehaviorSection(
                        settings: settings,
                        permissionsManager: permissionsManager
                    )
                    CameraSection(cameraManager: cameraManager)
                }
                .padding(.horizontal, Studio.sidePadding)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .defaultScrollAnchor(.top)
            .frame(maxHeight: .infinity)
            stickyFooter
        }
        .frame(width: Studio.panelWidth)
        .background(panelBackground)
    }

    private var stickyFooter: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Studio.hairline).frame(height: 0.5)
            PanelFooter()
                .padding(.horizontal, Studio.sidePadding)
                .padding(.vertical, 10)
        }
        .background(
            Color.black.opacity(0.18)
                .background(.ultraThinMaterial)
        )
    }

    private var panelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.04),
                    Color.white.opacity(0.0),
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            if settings.isCamOn {
                RadialGradient(
                    colors: [Color.accentColor.opacity(0.22), .clear],
                    center: .init(x: 0.85, y: 0.10),
                    startRadius: 4,
                    endRadius: 220
                )
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: settings.isCamOn)
    }
}
