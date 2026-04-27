import AVFoundation
import SwiftUI

/// Camera picker. Lists every discovered `AVCaptureDevice` with a checkmark on
/// the active selection. Falls back to a friendly empty state when zero
/// cameras are available.
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
