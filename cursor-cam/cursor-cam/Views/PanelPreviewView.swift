import AVFoundation
import SwiftUI

/// Live camera preview thumbnail for the settings panel.
/// Creates a second AVCaptureVideoPreviewLayer from the same session
/// so the panel shows a real-time miniature of the cam.
struct PanelPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var settings: SettingsStore

    @State private var panelLayer: AVCaptureVideoPreviewLayer?
    @State private var hasFailed = false

    private var camWidth: CGFloat { settings.cameraShape.dimensions(for: settings.cameraSize).width }
    private var camHeight: CGFloat { settings.cameraShape.dimensions(for: settings.cameraSize).height }
    private var cornerRadius: CGFloat { settings.cameraShape.cornerRadius(for: settings.cameraSize) }

    var body: some View {
        ZStack {
            if let layer = panelLayer, !hasFailed {
                CameraPreviewLayerView(previewLayer: layer)
                    .scaleEffect(x: settings.isMirrored ? -1 : 1, y: 1)
            } else if hasFailed {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(previewClipShape)
        .overlay(previewClipShape.stroke(Color.white.opacity(0.3), lineWidth: 1))
        .shadow(
            color: .black.opacity(settings.shadowEnabled ? settings.shadowIntensity.shadowOpacity : 0),
            radius: settings.shadowEnabled ? settings.shadowIntensity.shadowRadius / 2 : 0,
            x: 0, y: settings.shadowEnabled ? settings.shadowIntensity.shadowOffset / 2 : 0
        )
        .opacity(settings.baseOpacity)
        .onAppear {
            createLayer()
        }
        .onDisappear {
            removeLayer()
        }
        .onChange(of: cameraManager.previewLayer) { _ in
            removeLayer()
            createLayer()
        }
    }

    private var previewClipShape: AnyShape {
        switch settings.cameraShape {
        case .circle:        return AnyShape(Circle())
        case .roundedSquare: return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .horizontal:    return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .vertical:      return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    private func createLayer() {
        guard panelLayer == nil else { return }
        if let layer = cameraManager.createPanelPreviewLayer() {
            panelLayer = layer
            hasFailed = false
        } else {
            hasFailed = true
        }
    }

    private func removeLayer() {
        panelLayer?.removeFromSuperlayer()
        panelLayer = nil
    }
}
