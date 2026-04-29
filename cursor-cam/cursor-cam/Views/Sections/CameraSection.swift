import AVFoundation
import SwiftUI

struct CameraSection: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        VStack(alignment: .leading, spacing: Studio.rowGap) {
            Studio.sectionLabel("CAMERA")
            if cameraManager.availableCameras.isEmpty {
                EmptyCameraRow()
            } else {
                rows
            }
        }
    }

    private var rows: some View {
        VStack(spacing: 4) {
            ForEach(cameraManager.availableCameras, id: \.uniqueID) { device in
                CameraRow(
                    name: device.localizedName,
                    isSelected: cameraManager.currentCamera?.uniqueID == device.uniqueID,
                    action: { cameraManager.selectCamera(by: device.uniqueID) }
                )
            }
        }
    }
}
