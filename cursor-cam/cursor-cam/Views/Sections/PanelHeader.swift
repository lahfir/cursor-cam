import SwiftUI

struct PanelHeader: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var overlayManager: OverlayWindowManager

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                StatusPill(isOn: settings.isCamOn)
                Text("CURSOR · CAM")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(Studio.textPrimary)
                PowerSwitch(isOn: powerBinding)
            }
            Spacer(minLength: 0)
            PanelPreviewView(cameraManager: cameraManager, settings: settings)
                .frame(width: 92, height: 92)
        }
    }

    private var powerBinding: Binding<Bool> {
        Binding(
            get: { settings.isCamOn },
            set: { on in
                settings.isCamOn = on
                if on {
                    cameraManager.startSession()
                    overlayManager.show()
                } else {
                    overlayManager.hide()
                    cameraManager.stopSession()
                }
            }
        )
    }
}
