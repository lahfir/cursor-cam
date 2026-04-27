import AppKit
import AVFoundation
import Combine
import ServiceManagement

@MainActor
final class PermissionsManager: ObservableObject {
    @Published private(set) var cameraPermissionGranted = false
    @Published private(set) var accessibilityPermissionGranted = false

    private var hasRequestedCameraSystemPrompt = false
    private var hasRequestedAccessibilitySystemPrompt = false
    private var permissionPollTimer: Timer?

    private static let onboardingCompleteKey = "com.cursorcam.hasCompletedOnboarding"

    private var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Self.onboardingCompleteKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.onboardingCompleteKey) }
    }

    var needsOnboarding: Bool { !hasCompletedOnboarding }

    deinit {
        permissionPollTimer?.invalidate()
    }

    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    static func cameraPermissionGranted() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    func refreshPermissions() {
        cameraPermissionGranted = Self.cameraPermissionGranted()
        accessibilityPermissionGranted = Self.hasAccessibilityPermission()
    }

    func requestOnFirstLaunch() {
        refreshPermissions()

        if cameraPermissionGranted && accessibilityPermissionGranted {
            hasCompletedOnboarding = true
            return
        }

        requestPermissions()
    }

    func requestPermissions() {
        refreshPermissions()

        if !cameraPermissionGranted {
            presentCameraPermissionRequest()
        }

        if !accessibilityPermissionGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.presentAccessibilityPermissionRequest()
            }
        }

        startPolling()
    }

    private func presentCameraPermissionRequest() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            if !hasRequestedCameraSystemPrompt {
                hasRequestedCameraSystemPrompt = true
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.cameraPermissionGranted = granted
                    }
                }
            } else {
                openCameraSettings()
            }
        case .denied:
            openCameraSettings()
        case .restricted:
            break
        @unknown default:
            break
        }
    }

    private func presentAccessibilityPermissionRequest() {
        if Self.hasAccessibilityPermission() {
            accessibilityPermissionGranted = true
            return
        }

        if !hasRequestedAccessibilitySystemPrompt {
            hasRequestedAccessibilitySystemPrompt = true
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            accessibilityPermissionGranted = AXIsProcessTrustedWithOptions(options)
        } else {
            openAccessibilitySettings()
        }
    }

    private func startPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.pollPermissions()
            }
        }
    }

    private func pollPermissions() {
        let cameraNow = Self.cameraPermissionGranted()
        let accessibilityNow = Self.hasAccessibilityPermission()

        let wasMissing = !cameraPermissionGranted || !accessibilityPermissionGranted
        cameraPermissionGranted = cameraNow
        accessibilityPermissionGranted = accessibilityNow

        if cameraNow && accessibilityNow && wasMissing {
            hasCompletedOnboarding = true
            registerAsLoginItem()
            permissionPollTimer?.invalidate()
            permissionPollTimer = nil
        }
    }

    private func openCameraSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") else { return }
        NSWorkspace.shared.open(url)
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func registerAsLoginItem() {
        let service = SMAppService.mainApp
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            print("PermissionsManager: Failed to register login item: \(error)")
        }
    }
}
