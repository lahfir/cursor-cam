import AVFoundation
import SwiftUI

struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var settings: SettingsStore
    @ObservedObject var overlayManager: OverlayWindowManager
    let screen: NSScreen

    @State private var dragOffset: CGSize = .zero

    private var state: ScreenCamState { overlayManager.stateForScreen(screen) }

    private var camWidth: CGFloat  { settings.cameraShape.dimensions(for: settings.cameraSize).width }
    private var camHeight: CGFloat { settings.cameraShape.dimensions(for: settings.cameraSize).height }
    private var cornerRadius: CGFloat { settings.cameraShape.cornerRadius(for: settings.cameraSize) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.001)

            camContent
                .frame(width: camWidth, height: camHeight)
                .clipShape(clipShape)
                .overlay { border }
                .position(x: state.position.x + dragOffset.width,
                          y: state.position.y + dragOffset.height)
                .animation(springOrNil, value: state.position)
                .animation(.easeInOut(duration: 0.25), value: state.alpha)
                .opacity(state.alpha)
                .gesture(freeDragMode ? drag : nil)
        }
        .frame(width: screen.frame.width, height: screen.frame.height)
        .ignoresSafeArea()
    }

    // MARK: - Content

    @ViewBuilder
    private var camContent: some View {
        switch cameraManager.cameraState {
        case .running:
            if let layer = cameraManager.previewLayer {
                CameraPreviewLayerView(previewLayer: layer)
                    .scaleEffect(x: settings.isMirrored ? -1 : 1, y: 1)
            }
        case .starting:
            placeholder("circle.dotted")
        case .disconnected, .error:
            placeholder("camera.badge.ellipsis")
        case .unavailable, .restricted, .notDetermined, .denied:
            placeholder("camera.metering.unknown")
        }
    }

    private func placeholder(_ systemName: String) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Shape

    private var clipShape: AnyShape {
        switch settings.cameraShape {
        case .circle:         return AnyShape(Circle())
        case .roundedSquare:  return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .horizontal:     return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .vertical:       return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    // MARK: - Border

    @ViewBuilder
    private var border: some View {
        if settings.borderStyle != .none {
            clipShape
                .stroke(Color.white.opacity(0.6), style: strokeStyle)
        }
    }

    private var strokeStyle: SwiftUI.StrokeStyle {
        switch settings.borderStyle {
        case .dashed: return StrokeStyle(lineWidth: settings.borderWidth, dash: [6, 4])
        default:      return StrokeStyle(lineWidth: settings.borderWidth)
        }
    }

    // MARK: - Drag

    private var freeDragMode: Bool { settings.positioningMode == .freeDrag }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation }
            .onEnded { value in
                let new = CGPoint(x: state.position.x + value.translation.width,
                                  y: state.position.y + value.translation.height)
                dragOffset = .zero
                overlayManager.onFreeDragMoved(to: new, screen: screen)
            }
    }

    // MARK: - Animation

    private var springOrNil: Animation? {
        freeDragMode ? nil : .spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0)
    }
}

// MARK: - Preview Layer Bridge

private struct CameraPreviewLayerView: NSViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeNSView(context: Context) -> CameraPreviewNSView {
        let v = CameraPreviewNSView()
        v.previewLayer = previewLayer
        return v
    }

    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.previewLayer = previewLayer
    }
}

private final class CameraPreviewNSView: NSView {
    private var layingOut = false

    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            guard previewLayer !== oldValue else { return }
            oldValue?.removeFromSuperlayer()
            guard let layer = previewLayer else { return }
            wantsLayer = true
            layer.frame = bounds
            self.layer?.addSublayer(layer)
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        guard !layingOut, let layer = previewLayer else { return }
        layingOut = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = bounds
        CATransaction.commit()
        layingOut = false
    }
}

// MARK: - Shape Eraser

private struct AnyShape: Shape, @unchecked Sendable {
    private let path: @Sendable (CGRect) -> Path

    init<S: Shape & Sendable>(_ shape: S) { path = { shape.path(in: $0) } }
    func path(in rect: CGRect) -> Path { path(rect) }
}
