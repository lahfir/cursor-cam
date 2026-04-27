import AVFoundation
import Combine

enum CameraState: Equatable {
    case unavailable
    case restricted
    case notDetermined
    case denied
    case starting
    case running
    case disconnected
    case error(String)
}

@MainActor
final class CameraManager: ObservableObject {
    @Published private(set) var availableCameras: [AVCaptureDevice] = []
    @Published private(set) var currentCamera: AVCaptureDevice?
    @Published private(set) var cameraState: CameraState = .unavailable
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    private let settings: SettingsStore
    private var session: AVCaptureSession?
    private var activeInput: AVCaptureDeviceInput?
    private let discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
        mediaType: .video,
        position: .unspecified
    )

    private var isSessionConfigured = false
    private var reconnectTask: Task<Void, Never>?
    private static let reconnectGracePeriod: TimeInterval = 10.0

    init(settings: SettingsStore) {
        self.settings = settings
        observeNotifications()
        refreshAvailableCameras()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    func startSession() {
        guard !isSessionConfigured else { return }
        checkPermissionAndStart()
    }

    func stopSession() {
        session?.stopRunning()
        session = nil
        activeInput = nil
        previewLayer = nil
        currentCamera = nil
        isSessionConfigured = false
        cameraState = .unavailable
    }

    func selectCamera(by uniqueID: String?) {
        guard let uniqueID else { selectFirstAvailableCamera(); return }
        guard let device = availableCameras.first(where: { $0.uniqueID == uniqueID }) else { return }
        switchToDevice(device)
    }

    private func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:  configureAndStartSession()
        case .notDetermined: cameraState = .notDetermined
        case .denied:       cameraState = .denied
        case .restricted:   cameraState = .restricted
        @unknown default:   cameraState = .unavailable
        }
    }

    private func configureAndStartSession() {
        let newSession = AVCaptureSession()
        newSession.sessionPreset = .medium

        guard selectFirstAvailableCamera(using: newSession) else {
            cameraState = .unavailable
            return
        }

        let layer = AVCaptureVideoPreviewLayer(session: newSession)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer

        session = newSession
        isSessionConfigured = true
        cameraState = .starting
        newSession.startRunning()
        cameraState = .running
    }

    @discardableResult
    private func selectFirstAvailableCamera(using session: AVCaptureSession? = nil) -> Bool {
        refreshAvailableCameras()
        let targetSession = session ?? self.session
        if let preferredID = settings.selectedCameraUniqueID,
           let device = availableCameras.first(where: { $0.uniqueID == preferredID }) {
            return addInput(device: device, to: targetSession)
        }
        guard let defaultDevice = availableCameras.first else { return false }
        return addInput(device: defaultDevice, to: targetSession)
    }

    private func addInput(device: AVCaptureDevice, to session: AVCaptureSession?) -> Bool {
        guard let session else { return false }
        if let existingInput = activeInput {
            session.removeInput(existingInput)
            activeInput = nil
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return false }
            session.addInput(input)
            activeInput = input
            currentCamera = device
            settings.selectedCameraUniqueID = device.uniqueID
            return true
        } catch {
            print("CameraManager: failed to create input: \(error.localizedDescription)")
            return false
        }
    }

    private func switchToDevice(_ device: AVCaptureDevice) {
        guard let session else { return }
        _ = addInput(device: device, to: session)
    }

    func refreshAvailableCameras() {
        availableCameras = discoverySession.devices
    }

    private func observeNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(handleDeviceConnected), name: AVCaptureDevice.wasConnectedNotification, object: nil)
        center.addObserver(self, selector: #selector(handleDeviceDisconnected), name: AVCaptureDevice.wasDisconnectedNotification, object: nil)
        center.addObserver(self, selector: #selector(handleRuntimeError), name: AVCaptureSession.runtimeErrorNotification, object: nil)
    }

    @objc private func handleDeviceConnected(_ notification: Notification) {
        refreshAvailableCameras()
        guard let device = notification.object as? AVCaptureDevice,
              let selectedID = settings.selectedCameraUniqueID,
              device.uniqueID == selectedID, cameraState == .disconnected else { return }
        switchToDevice(device)
        session?.startRunning()
        cameraState = .running
    }

    @objc private func handleDeviceDisconnected(_ notification: Notification) {
        guard let device = notification.object as? AVCaptureDevice,
              device.uniqueID == currentCamera?.uniqueID else { return }
        cameraState = .disconnected
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.reconnectGracePeriod))
        }
    }

    @objc private func handleRuntimeError(_ notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? Error else { return }
        cameraState = .error(error.localizedDescription)
    }

    func handleSleep() {
        reconnectTask?.cancel()
        session?.stopRunning()
    }

    func handleWake() {
        guard isSessionConfigured, cameraState == .running else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.session?.startRunning()
        }
    }
}
