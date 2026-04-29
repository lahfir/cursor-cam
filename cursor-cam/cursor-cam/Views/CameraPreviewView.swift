import AVFoundation
import SwiftUI

struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var settings: SettingsStore
    @ObservedObject var overlayManager: OverlayWindowManager

    @StateObject private var click = ClickFeedbackState()
    @State private var dragOffset: CGSize = .zero

    private var state: CamState { overlayManager.camState }
    private var camWidth: CGFloat  { settings.cameraShape.dimensions(for: settings.cameraSize).width }
    private var camHeight: CGFloat { settings.cameraShape.dimensions(for: settings.cameraSize).height }
    private var cornerRadius: CGFloat { settings.cameraShape.cornerRadius(for: settings.cameraSize) }
    private var freeDragMode: Bool { settings.positioningMode == .freeDrag }

    private var finalOpacity: Double {
        Double(state.alpha) * settings.baseOpacity * Double(overlayManager.idleDimMultiplier)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.001)
                if settings.clickFeedbackEnabled {
                    ClickBloomView(state: click, shape: clipShape, camWidth: camWidth, camHeight: camHeight)
                        .position(camPositionWithDrag)
                }
                cam
                    .position(camPositionWithDrag)
                    .gesture(freeDragMode ? drag : nil)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .cursorCamClickFeedback)) { _ in
            guard settings.clickFeedbackEnabled else { return }
            click.fire()
        }
    }

    private var camPositionWithDrag: CGPoint {
        CGPoint(x: state.position.x + dragOffset.width, y: state.position.y + dragOffset.height)
    }

    private var cam: some View {
        camContent
            .frame(width: camWidth, height: camHeight)
            .scaleEffect(overlayManager.velocityScale * click.pulse)
            .shadow(
                color: .black.opacity(settings.shadowEnabled ? settings.shadowIntensity.shadowOpacity : 0),
                radius: settings.shadowEnabled ? settings.shadowIntensity.shadowRadius : 0,
                x: 0, y: settings.shadowEnabled ? settings.shadowIntensity.shadowOffset : 0
            )
            .clipShape(clipShape)
            .overlay { border }
            .animation(positionSpring, value: state.position)
            .animation(.easeInOut(duration: 0.25), value: state.alpha)
            .animation(.spring(response: 0.38, dampingFraction: 0.85, blendDuration: 0), value: overlayManager.velocityScale)
            .opacity(finalOpacity)
            .animation(dimAnimation, value: finalOpacity)
    }

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
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
    }

    private var clipShape: AnyShape {
        switch settings.cameraShape {
        case .circle:        return AnyShape(Circle())
        case .roundedSquare: return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .horizontal:    return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .vertical:      return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    @ViewBuilder
    private var border: some View {
        if settings.borderStyle != .none {
            clipShape.stroke(Color.white.opacity(0.6), style: strokeStyle)
        }
    }

    private var strokeStyle: SwiftUI.StrokeStyle {
        switch settings.borderStyle {
        case .dashed: return StrokeStyle(lineWidth: settings.borderWidth, dash: [6, 4])
        default:      return StrokeStyle(lineWidth: settings.borderWidth)
        }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation }
            .onEnded { value in
                let new = CGPoint(x: state.position.x + value.translation.width,
                                  y: state.position.y + value.translation.height)
                dragOffset = .zero
                if let screen = overlayManager.screenContainingCursor() ?? NSScreen.main {
                    overlayManager.onFreeDragMoved(to: new, screen: screen)
                }
            }
    }

    private var positionSpring: Animation? {
        freeDragMode ? nil : .spring(response: 0.42, dampingFraction: 0.88, blendDuration: 0)
    }

    private var dimAnimation: Animation? {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { return nil }
        let dimming = overlayManager.idleDimMultiplier < 1.0
        return .easeInOut(duration: dimming ? 0.55 : 0.20)
    }
}

struct CameraPreviewLayerView: NSViewRepresentable {
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

final class CameraPreviewNSView: NSView {
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

struct AnyShape: Shape, @unchecked Sendable {
    private let path: @Sendable (CGRect) -> Path
    init<S: Shape & Sendable>(_ shape: S) { path = { shape.path(in: $0) } }
    func path(in rect: CGRect) -> Path { path(rect) }
}
