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
    private var hasCompletedOnboarding = false

    private let defaultsKey = "com.cursorcam.hasCompletedOnboarding"

    var needsOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: defaultsKey)
    }

    deinit {
        permissionPollTimer?.invalidate()
    }

    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func refreshPermissions() {
        cameraPermissionGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        accessibilityPermissionGranted = Self.hasAccessibilityPermission()
    }

    func requestOnFirstLaunch() {
        guard needsOnboarding else {
            refreshPermissions()
            return
        }
        requestPermissions()
    }

    func requestPermissions() {
        refreshPermissions()

        if !cameraPermissionGranted {
            requestCameraPermission()
        }

        if !accessibilityPermissionGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.requestAccessibilityPermission()
            }
        }

        startPolling()
    }

    private func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            if !hasRequestedCameraSystemPrompt {
                hasRequestedCameraSystemPrompt = true
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    Task { @MainActor in
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

    private func requestAccessibilityPermission() {
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
            Task { @MainActor in
                self?.pollPermissions()
            }
        }
    }

    private func pollPermissions() {
        let cameraNow = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let accessibilityNow = Self.hasAccessibilityPermission()

        cameraPermissionGranted = cameraNow
        accessibilityPermissionGranted = accessibilityNow

        if cameraNow && accessibilityNow && !hasCompletedOnboarding {
            hasCompletedOnboarding = true
            UserDefaults.standard.set(true, forKey: defaultsKey)
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
