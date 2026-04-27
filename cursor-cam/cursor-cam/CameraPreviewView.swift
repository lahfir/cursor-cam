import AVFoundation
import SwiftUI

struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var settings: SettingsStore
    @ObservedObject var overlayManager: OverlayWindowManager
    let screen: NSScreen

    @State private var dragOffset: CGSize = .zero

    private var state: ScreenCamState {
        overlayManager.stateForScreen(screen)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.001)

            camBubble
                .position(
                    x: state.position.x + dragOffset.width,
                    y: state.position.y + dragOffset.height
                )
                .animation(
                    settings.positioningMode != .freeDrag
                        ? .spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0)
                        : nil,
                    value: state.position
                )
                .animation(.easeInOut(duration: 0.25), value: state.alpha)
                .opacity(state.alpha)
                .gesture(
                    settings.positioningMode == .freeDrag
                        ? DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                let newPosition = CGPoint(
                                    x: state.position.x + value.translation.width,
                                    y: state.position.y + value.translation.height
                                )
                                dragOffset = .zero
                                overlayManager.onFreeDragMoved(to: newPosition, screen: screen)
                            }
                        : nil
                )
        }
        .frame(width: screen.frame.width, height: screen.frame.height)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var camBubble: some View {
        Group {
            switch cameraManager.cameraState {
            case .running:
                if let previewLayer = cameraManager.previewLayer {
                    CameraPreviewLayerView(previewLayer: previewLayer)
                        .scaleEffect(x: settings.isMirrored ? -1 : 1, y: 1)
                        .clipShape(camClipShape())
                }
            case .starting:
                camPlaceholder(systemName: "circle.dotted")
                    .symbolEffect(.rotate)
            case .disconnected, .error:
                camPlaceholder(systemName: "camera.badge.ellipsis")
            case .unavailable, .restricted, .notDetermined, .denied:
                camPlaceholder(systemName: "camera.metering.unknown")
            }
        }
        .frame(
            width: settings.cameraSize.pixelValue,
            height: settings.cameraSize.pixelValue
        )
    }

    private func camPlaceholder(systemName: String) -> some View {
        RoundedRectangle(cornerRadius: settings.cameraSize.cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
    }

    private func camClipShape() -> AnyShape {
        switch settings.cameraShape {
        case .circle:
            return AnyShape(Circle())
        case .roundedSquare:
            return AnyShape(RoundedRectangle(cornerRadius: settings.cameraSize.cornerRadius))
        }
    }
}

private struct CameraPreviewLayerView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.previewLayer = previewLayer
        return view
    }

    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.previewLayer = previewLayer
    }
}

private final class CameraPreviewNSView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            oldValue?.removeFromSuperlayer()
            guard let previewLayer else { return }
            layer?.addSublayer(previewLayer)
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}

private struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape & Sendable>(_ shape: S) {
        _path = { shape.path(in: $0) }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}
