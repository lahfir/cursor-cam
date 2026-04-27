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

    private var camWidth: CGFloat {
        settings.cameraShape.dimensions(for: settings.cameraSize).width
    }
    private var camHeight: CGFloat {
        settings.cameraShape.dimensions(for: settings.cameraSize).height
    }
    private var cornerRadius: CGFloat {
        settings.cameraShape.cornerRadius(for: settings.cameraSize)
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
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { endDrag($0) }
                        : nil
                )
        }
        .frame(width: screen.frame.width, height: screen.frame.height)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var camBubble: some View {
        ZStack {
            // DEBUG: remove after confirming cam renders
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(width: camWidth, height: camHeight)
                .clipShape(camClipShape())

            Group {
                switch cameraManager.cameraState {
                case .running:
                    if let previewLayer = cameraManager.previewLayer {
                        CameraPreviewLayerView(previewLayer: previewLayer)
                            .scaleEffect(x: settings.isMirrored ? -1 : 1, y: 1)
                            .clipShape(camClipShape())
                    } else {
                        Text("no layer")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                case .starting:
                    camPlaceholder(systemName: "circle.dotted", withMaterial: true)
                case .disconnected, .error:
                    camPlaceholder(systemName: "camera.badge.ellipsis", withMaterial: true)
                case .unavailable, .restricted, .notDetermined, .denied:
                    camPlaceholder(systemName: "camera.metering.unknown", withMaterial: true)
                }
            }
            .frame(width: camWidth, height: camHeight)

            camBorder
        }
    }

    @ViewBuilder
    private var camBorder: some View {
        if settings.borderStyle != .none {
            camClipShape()
                .stroke(Color.white.opacity(0.6), style: borderStrokeStyle)
        }
    }

    private var borderStrokeStyle: SwiftUI.StrokeStyle {
        switch settings.borderStyle {
        case .dashed:
            return StrokeStyle(lineWidth: settings.borderWidth, dash: [6, 4])
        case .solid, .none:
            return StrokeStyle(lineWidth: settings.borderWidth)
        }
    }

    private func endDrag(_ value: DragGesture.Value) {
        let newPosition = CGPoint(
            x: state.position.x + value.translation.width,
            y: state.position.y + value.translation.height
        )
        dragOffset = .zero
        overlayManager.onFreeDragMoved(to: newPosition, screen: screen)
    }

    private func camPlaceholder(systemName: String, withMaterial: Bool = false) -> some View {
        Group {
            if withMaterial {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Image(systemName: systemName)
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func camClipShape() -> AnyShape {
        switch settings.cameraShape {
        case .circle:
            return AnyShape(Circle())
        case .roundedSquare:
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .verticalPill:
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .horizontalPill:
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
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
    private var isLayingOut = false

    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            guard previewLayer !== oldValue else { return }
            oldValue?.removeFromSuperlayer()
            guard let previewLayer else { return }
            wantsLayer = true
            previewLayer.frame = bounds
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
        guard !isLayingOut, let previewLayer else { return }
        isLayingOut = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
        isLayingOut = false
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
