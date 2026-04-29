import AVFoundation
import SwiftUI

/// Live camera preview thumbnail rendered as the hero element of the settings
/// panel header. Creates a second `AVCaptureVideoPreviewLayer` from the same
/// session so the panel mirrors the running cam in real time.
///
/// Visual cues:
/// - Accent-colored outer glow + frame stroke when cam is live
/// - Tiny red dot in the top-right corner reinforces the "broadcasting" feel
/// - Aspect ratio + corner radius mirror the user's selected `CameraShape`
struct PanelPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var settings: SettingsStore

    @State private var panelLayer: AVCaptureVideoPreviewLayer?
    @State private var hasFailed = false

    private static let frameSize: CGFloat = 92

    var body: some View {
        ZStack {
            if settings.isCamOn { glow }
            previewFrame
            if settings.isCamOn { liveDot }
        }
        .frame(width: Self.frameSize, height: Self.frameSize)
        .animation(.easeInOut(duration: 0.3), value: settings.isCamOn)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: settings.cameraShape)
        .onAppear { createLayer() }
        .onDisappear { removeLayer() }
        .onChange(of: cameraManager.previewLayer) { _, _ in
            removeLayer()
            createLayer()
        }
    }

    private var glow: some View {
        clipShape
            .fill(Color.accentColor.opacity(0.18))
            .blur(radius: 14)
            .scaleEffect(1.15)
            .transition(.opacity)
    }

    private var previewFrame: some View {
        ZStack {
            previewContent
        }
        .aspectRatio(aspect, contentMode: .fit)
        .background(Color.black.opacity(0.4))
        .clipShape(clipShape)
        .overlay(
            clipShape.stroke(
                settings.isCamOn ? Color.accentColor.opacity(0.55) : Color.white.opacity(0.12),
                lineWidth: 1
            )
        )
        .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 4)
        .opacity(settings.baseOpacity * (settings.isCamOn ? 1 : 0.55))
    }

    @ViewBuilder
    private var previewContent: some View {
        if let layer = panelLayer, !hasFailed {
            CameraPreviewLayerView(previewLayer: layer)
                .scaleEffect(x: settings.isMirrored ? -1 : 1, y: 1)
        } else if hasFailed {
            placeholder
        } else {
            ProgressView().scaleEffect(0.7)
        }
    }

    private var liveDot: some View {
        Circle()
            .fill(Studio.liveRed)
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 0.5))
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .transition(.opacity)
    }

    private var placeholder: some View {
        ZStack {
            Color.black.opacity(0.25)
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var clipShape: AnyShape {
        switch settings.cameraShape {
        case .circle:        return AnyShape(Circle())
        case .roundedSquare: return AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        case .horizontal:    return AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .vertical:      return AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var aspect: CGFloat {
        switch settings.cameraShape {
        case .circle, .roundedSquare: return 1
        case .horizontal:             return 1.5 / 0.95
        case .vertical:               return 1.0 / 1.25
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
