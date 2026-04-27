import SwiftUI
import AVFoundation

struct SettingsPanelView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var overlayManager: OverlayWindowManager
    @ObservedObject var permissionsManager: PermissionsManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Group {
                    section("Appearance") {
                        row("Shape") {
                            Picker("", selection: $settings.cameraShape) {
                                Text("Circle").tag(CameraShape.circle)
                                Text("Rounded").tag(CameraShape.roundedSquare)
                                Text("Wide").tag(CameraShape.horizontal)
                                Text("Tall").tag(CameraShape.vertical)
                            }
                            .pickerStyle(.segmented)
                        }
                        row("Size") {
                            Picker("", selection: $settings.cameraSize) {
                                Text("S").tag(CameraSize.small)
                                Text("M").tag(CameraSize.medium)
                                Text("L").tag(CameraSize.large)
                            }
                            .pickerStyle(.segmented)
                        }
                        row("Mirror") { Toggle("", isOn: $settings.isMirrored).labelsHidden() }
                        row("Opacity") {
                            HStack(spacing: 8) {
                                Slider(value: $settings.baseOpacity, in: 0.2...1.0)
                                Text("\(Int(settings.baseOpacity * 100))%").font(.caption2.monospacedDigit()).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
                            }
                        }
                        row("Shadow") {
                            HStack(spacing: 8) {
                                Toggle("", isOn: $settings.shadowEnabled).labelsHidden().frame(width: 40)
                                if settings.shadowEnabled {
                                    Picker("", selection: $settings.shadowIntensity) {
                                        Text("Light").tag(ShadowIntensity.light)
                                        Text("Med").tag(ShadowIntensity.medium)
                                        Text("Heavy").tag(ShadowIntensity.heavy)
                                    }
                                    .pickerStyle(.segmented)
                                    .transition(.opacity.combined(with: .scale))
                                }
                            }
                        }
                    }

                    section("Positioning") {
                        row("Mode") {
                            Picker("", selection: $settings.positioningMode) {
                                Text("Follow").tag(PositioningMode.followCursor)
                                Text("Pin").tag(PositioningMode.pinToCorner)
                                Text("Drag").tag(PositioningMode.freeDrag)
                            }
                            .pickerStyle(.segmented)
                        }
                        if settings.positioningMode == .pinToCorner {
                            row("Corner") {
                                Picker("", selection: $settings.pinnedCorner) {
                                    Text("TL").tag(Corner.topLeft)
                                    Text("TR").tag(Corner.topRight)
                                    Text("BL").tag(Corner.bottomLeft)
                                    Text("BR").tag(Corner.bottomRight)
                                }
                                .pickerStyle(.segmented)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        if settings.positioningMode == .followCursor {
                            row("Offset") {
                                Picker("", selection: $settings.cursorPosition) {
                                    Text("Ctr").tag(CursorPosition.center)
                                    Text("TL").tag(CursorPosition.topLeft)
                                    Text("TR").tag(CursorPosition.topRight)
                                    Text("BL").tag(CursorPosition.bottomLeft)
                                    Text("BR").tag(CursorPosition.bottomRight)
                                }
                                .pickerStyle(.segmented)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    section("Behavior") {
                        row("Velocity") { Toggle("", isOn: $settings.velocityScalingEnabled).labelsHidden() }
                        row("Idle Dim") { Toggle("", isOn: $settings.idleDimEnabled).labelsHidden() }
                        if settings.idleDimEnabled {
                            row("Timeout") {
                                HStack(spacing: 8) {
                                    Slider(value: $settings.idleTimeoutSeconds, in: 1...10, step: 1)
                                    Text("\(Int(settings.idleTimeoutSeconds))s").font(.caption2.monospacedDigit()).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                            row("Dimmed") {
                                HStack(spacing: 8) {
                                    Slider(value: $settings.idleDimmedOpacity, in: 0.15...0.8)
                                    Text("\(Int(settings.idleDimmedOpacity * 100))%").font(.caption2.monospacedDigit()).foregroundStyle(.secondary).frame(width: 32, alignment: .trailing)
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            row("Click Ring") {
                                Toggle("", isOn: $settings.clickFeedbackEnabled)
                                    .labelsHidden()
                                    .disabled(!permissionsManager.accessibilityPermissionGranted)
                            }
                            if !permissionsManager.accessibilityPermissionGranted {
                                Text("Requires Accessibility permission").font(.caption2).foregroundStyle(.secondary).padding(.leading, 100)
                            }
                        }
                    }

                    section("Camera") {
                        if cameraManager.availableCameras.isEmpty {
                            Text("No Camera Available").font(.caption).foregroundStyle(.secondary).padding(.leading, 100)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(cameraManager.availableCameras.enumerated()), id: \.element.uniqueID) { index, device in
                                    let selected = cameraManager.currentCamera?.uniqueID == device.uniqueID
                                    Button {
                                        cameraManager.selectCamera(by: device.uniqueID)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "video.fill").font(.caption2).foregroundStyle(selected ? Color(nsColor: .controlAccentColor) : .secondary).frame(width: 16)
                                            Text(device.localizedName).font(.system(size: 12, weight: selected ? .medium : .regular))
                                            Spacer()
                                            if selected { Image(systemName: "checkmark").font(.caption2.weight(.bold)).foregroundStyle(Color(nsColor: .controlAccentColor)) }
                                        }
                                        .padding(.vertical, 4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(selected ? .primary : .secondary)
                                    if index < cameraManager.availableCameras.count - 1 { Divider().padding(.leading, 100) }
                                }
                            }
                        }
                    }
                }

                HStack {
                    HStack(spacing: 4) {
                        badge("⌃"); badge("⌥"); badge("C")
                    }
                    Spacer()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(20)
        }
        .frame(width: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { settings.isCamOn },
                set: { on in
                    settings.isCamOn = on
                    on ? cameraManager.startSession() : overlayManager.hide()
                    if on { overlayManager.show() }
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.isCamOn ? "Camera On" : "Camera Off").font(.system(size: 15, weight: .semibold))
                Text(settings.isCamOn ? "Active" : "Disabled").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            PanelPreviewView(cameraManager: cameraManager, settings: settings)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase).tracking(0.5)
            content()
        }
    }

    private func row<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            Text(label).font(.system(size: 12)).foregroundStyle(.primary).frame(width: 90, alignment: .trailing).padding(.trailing, 12)
            content().frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 22)
    }

    private func badge(_ key: String) -> some View {
        Text(key).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            .frame(minWidth: 20, minHeight: 18)
            .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)).overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)))
    }
}
