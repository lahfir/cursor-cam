---
title: "feat: Cursor-Cam — Floating Camera That Follows Your Cursor"
type: feat
status: active
date: 2026-04-27
origin: docs/brainstorms/2026-04-27-cursor-cam-requirements.md
---

# feat: Cursor-Cam — Floating Camera That Follows Your Cursor

## Overview

Greenfield macOS menu-bar-only app that renders a floating camera overlay. The cam defaults to following the cursor with spring animation, can be pinned to a screen corner, or free-dragged. A single global hotkey toggles the cam on/off. The cam is a standard borderless `NSWindow` — any screen recorder captures it natively with zero recorder-specific setup.

**Target repo:** cursor-cam (greenfield)

## Problem Frame

Presenters recording their screen (Loom, OBS, Screen Studio, Recordly) pick between three bad options: built-in recorder cam bubbles locked to one tool, manual repositioning, or no cam at all. Cursor-cam solves all three with a recorder-agnostic floating overlay that follows the cursor — putting the presenter's face where the viewer's eyes already track.

See origin document for full problem frame, actors, and flows.

## Requirements Trace

### Window & Recorder Behavior
- R1. Camera preview in borderless transparent window above all apps, non-activating, never steals focus
- R2. Captured by any standard macOS screen recorder (no virtual cam driver, no plugin)

### Hotkey & Toggle
- R3. Single global hotkey toggles cam on/off

### Animations
- R4. Fade in ~250ms, fade out ~400ms, no abrupt pop

### Positioning Modes
- R5. Three positioning modes: Follow cursor (default), Pin to corner (TL/TR/BL/BR), Free drag
- R6. Mode change does not toggle cam off; cam glides to new resting state via spring animation
- R7. Follow-cursor: 60fps polling, spring-animated offset (`response: 0.2`, `dampingFraction: 0.6`), 15px down-right of cursor, always click-through
- R8. Multi-monitor: one overlay per `NSScreen`, only cursor-containing screen renders cam, cross-monitor handoff with fade, only one cam visible globally
- R9. Free-drag: hit-testable window; Follow-cursor and Pin-to-corner: `ignoresMouseEvents = true`

### Camera
- R10. Camera picker enumerates all `AVCaptureDevice` video inputs, selection persists across launches

### Appearance
- R11. Two shapes: circle (default) and rounded square
- R12. Three size presets: S (80px), M (120px, default), L (180px) — diameter for circle, width for rounded square

### Settings & Persistence
- R13. Mirror toggle (default ON, matching FaceTime/Photo Booth convention)
- R14. Settings persist via `UserDefaults`: camera, mode, corner, shape, size, mirror, last free-drag position

### Menu Bar, Lifecycle & Cleanup
- R15. Menu-bar-only (`LSUIElement = true`), no dock icon, no main window. Menu bar icon shows cam visibility state: ON = cam overlay visible, OFF = cam overlay hidden (AVCaptureSession may still be running for warm re-toggle)
- R16. `AVCaptureSession` starts on first toggle-on, stays running across toggle-off (re-toggle is instant), stops only on quit or camera disconnect
- R17. Quitting releases camera and accessibility access

## Scope Boundaries

- v1 is macOS-only (macOS 14.2+)
- v1 ships one hardcoded hotkey, two shapes, three sizes, mirror toggle, camera picker — nothing more
- Direct distribution (notarized DMG), not Mac App Store (CGEvent tap incompatible with sandboxing)
- Cursor-cam never records — it is captured by existing recorders, not by itself
- No virtual cam driver, no NDI, no OBS plugin

### Deferred to Separate Tasks

- Configurable global hotkey (v2)
- Freeform drag-to-resize, opacity slider, custom borders, drop shadows (v1.5+)
- Saved presets, per-app behavior rules, recording auto-detection (v2)
- AI background blur / removal, beauty filters, AR effects (v2+)
- Smart-park zones, multi-camera composite, effects (v2+)
- Cross-platform (Windows, Linux) — v2 rewrite

## Context & Research

### Relevant Code and Patterns

- **Clicky reference (external repo: `/Users/lahfir/Documents/Projects/clicky`):**
  - `leanring-buddy/OverlayWindow.swift` — per-screen `NSWindow` subclass with `level=.screenSaver`, `collectionBehavior=[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`, 60fps cursor polling via `Timer`, spring animation, multi-monitor gating, coordinate conversion
  - `leanring-buddy/CompanionResponseOverlay.swift` — `NSPanel` positioning near cursor, edge-clamping, fade-out lifecycle
  - `leanring-buddy/GlobalPushToTalkShortcutMonitor.swift` — listen-only `CGEvent` tap for global hotkey, modifier chord matching, run-loop attachment, re-enable on timeout
  - `leanring-buddy/WindowPositionManager.swift` — permission flows (Camera, Accessibility, Screen Recording), three-phase request pattern (system prompt → System Settings deep link), polling pattern for live permission status
  - `leanring-buddy/leanring_buddyApp.swift` — `LSUIElement` app entry point, `NSApplicationDelegateAdaptor`, `SMAppService` login item registration
- **Architecture pattern:** AppDelegate → CentralManager (`@MainActor` `ObservableObject`) → sub-managers (overlay, camera, hotkey, permissions)
- **SwiftUI + AppKit bridging:** `NSHostingView` wrapping SwiftUI views into `NSWindow`/`NSPanel` content
- **Convention:** SwiftUI-first for all UI, AppKit only for `NSWindow`/`NSPanel` overlays and `NSStatusItem`

### Institutional Learnings

None — greenfield project. No `docs/solutions/` exists.

### External References

None required. Clicky patterns are directly applicable and sufficient.

## Key Technical Decisions

- **Hotkey chord: `⌃⌥C` (Control+Option+C).** Avoids conflicts with common shortcuts (`⌘⇧C` in Chrome/Firefox, `⌘C` system-wide). Clicky proves Control+Option chords work reliably with CGEvent taps. The `shift` modifier is omitted to keep it a 3-key chord — 4-key chords are harder to press one-handed during recordings.
- **Cam size presets: S=80px, M=120px, L=180px.** Diameter for circle, width for rounded square. At 1080p, the M size occupies ~12.5% of screen height — large enough to see facial expressions, small enough not to obstruct content.
- **Free-drag: full cam is grabbable** (no separate drag handle). Simpler implementation, fewer visual elements. The cam is small enough (80-180px) that mis-clicks are unlikely.
- **Cross-monitor handoff: sequential fade.** Old screen fades to 0 opacity over ~100ms, then after ~50ms gap, new screen fades in over ~100ms. No overlapping visibility — satisfies R8's "only one cam visible globally" constraint (matching acceptance example AE1 from the origin requirements).
- **Non-active screen windows: kept at `alphaValue = 0.0`**, not hidden. Keeping windows in the window list with zero opacity avoids `AVCaptureVideoPreviewLayer` frame drops on re-show (`isHidden = true` may pause the layer).
- **Always start OFF on launch.** Consistent with F1's "cam OFF by default." An auto-starting camera overlay is a privacy concern.
- **Menu bar includes manual toggle item.** Hotkey is a convenience accelerator, not the sole toggle mechanism. Required for users who deny Accessibility (hotkey won't work without it) or have conflicts.
- **Default corner for Pin-to-corner: bottom-right.** Most common face-cam placement in Loom/OBS.
- **Non-1:1 camera aspect ratio: center-crop.** Letterbox wastes preview area on a small cam; center-crop keeps the face centered and fills the shape.

## Open Questions

### Resolved During Planning

- **Hotkey chord (`⌃⌥C`):** Selected for simplicity and lack of known conflicts. See Key Technical Decisions.
- **Pixel sizes (80/120/180px):** Selected for screen-coverage ratios at common resolutions. See Key Technical Decisions.
- **Free-drag interaction model (full-grab):** Entire cam is draggable. See Key Technical Decisions.
- **Cross-monitor fade model (per-screen, sequential):** See Key Technical Decisions.
- **Non-1:1 aspect ratio (center-crop):** See Key Technical Decisions.
- **Default corner (bottom-right):** See Key Technical Decisions.
- **ON/OFF state persistence (always start OFF):** See Key Technical Decisions.
- **Menu bar manual toggle (yes, included):** See Key Technical Decisions.
- **Camera-unavailable UX:** Show a camera-off SF Symbol in the cam window frame; menu bar icon shows warning badge. See Unit 4 and Unit 5.
- **Double-toggle behavior:** Toggle intent is a boolean flip; fade animations are interruptible — reverse direction from current opacity if hotkey is pressed mid-fade. See Unit 6.
- **Free-drag initial position:** First time entering Free-drag: appear at current cursor position. Subsequent times: restore last persisted position. See Unit 5.
- **Pin-to-corner + multi-monitor:** Cam follows the active display (cursor-containing) to that display's corner. Non-active display windows are hidden (`alphaValue = 0`). See Unit 5.

### Deferred to Implementation

- **Screen recorder capture verification.** Test with Loom, Screen Studio, OBS, Recordly on macOS 14+ to confirm `LSUIElement` + `level=.screenSaver` windows are captured. Deferred because it requires runtime testing with commercial software.
- **Cam window composition impact on input latency.** Test with Activity Monitor at 60fps to confirm the performance budget (3-5W on Apple Silicon). Deferred because it requires runtime profiling.
- **iPhone Continuity Camera hot-plug reliability.** `AVCaptureDevice.DiscoverySession` includes Continuity Camera automatically, but the reconnect-on-wake behavior must be tested with a real iPhone. Deferred because it requires physical hardware.
- **Non-uniform DPI (Retina + non-Retina) coordinate mapping.** The Clicky coordinate conversion pattern works for same-DPI setups. Mixed-DPI needs runtime verification. Deferred because it requires specific hardware configurations.
- **Spring animation tuning fine-tuning.** The Clicky parameters (`response: 0.2`, `dampingFraction: 0.6`) are known-good baselines. Final tuning depends on perceived feel on target hardware.
- **Exact method/helper names, file organization details, and exact SwiftUI view hierarchy.** Will be determined during implementation based on what produces the cleanest code.

## Output Structure

```
cursor-cam/
├── CursorCam.xcodeproj/
├── CursorCam/
│   ├── CursorCamApp.swift              # @main entry point, AppDelegate
│   ├── Info.plist                       # Camera usage description, LSUIElement
│   ├── CursorCam.entitlements           # Camera + non-sandboxed + network
│   ├── SettingsStore.swift              # UserDefaults persistence for all settings
│   ├── CameraManager.swift              # AVCaptureSession + device discovery + hot-plug
│   ├── OverlayWindowManager.swift       # Per-screen NSWindow lifecycle, cursor tracking, positioning modes
│   ├── CameraPreviewView.swift          # SwiftUI view with AVCaptureVideoPreviewLayer, shapes, sizes, mirror
│   ├── HotkeyMonitor.swift              # CGEvent tap for global hotkey toggle
│   ├── MenuBarManager.swift             # NSStatusItem + dropdown menu + permission status
│   └── PermissionsManager.swift         # Camera + Accessibility permission flows
├── CursorCamTests/
│   ├── SettingsStoreTests.swift
│   ├── CameraManagerTests.swift
│   ├── OverlayWindowManagerTests.swift
│   └── PositioningModeTests.swift
└── CursorCamUITests/
    └── CursorCamUITests.swift
```

## Implementation Units

### Unit 1: Project scaffolding and build configuration

- [ ] **Unit 1: Project scaffolding and build configuration**

**Goal:** Create the Xcode project with correct build settings, entitlements, and Info.plist entries so the app compiles as a menu-bar-only, non-sandboxed target.

**Requirements:** R15 (LSUIElement), R10 (camera access)

**Dependencies:** None

**Files:**
- Create: `CursorCam/CursorCamApp.swift` (stub with `@main` and `EmptyView()` Settings scene)
- Create: `CursorCam/Info.plist` (or use `INFOPLIST_KEY_*` build settings)
- Create: `CursorCam/CursorCam.entitlements`
- Create: `CursorCam.xcodeproj/` (Xcode project)

**Approach:**
- Set `MACOSX_DEPLOYMENT_TARGET = 14.2`, `SWIFT_VERSION = 5.0`
- Set `INFOPLIST_KEY_LSUIElement = YES`, `ENABLE_APP_SANDBOX = NO`, `ENABLE_HARDENED_RUNTIME = YES`
- Set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (project-wide, matching Clicky)
- Entitlements: `com.apple.security.app-sandbox = false`, `com.apple.security.device.camera = true` (no `network.client` — v1 has no network dependency; the non-sandboxed app already has unrestricted network access)
- Info.plist: `NSCameraUsageDescription` ("Cursor-Cam needs camera access to show your video overlay")
- No `NSMicrophoneUsageDescription` (no audio in v1), no `NSScreenCaptureUsageDescription` (app doesn't capture)
- Single target: `CursorCam` macOS app, with unit test and UI test targets

**Patterns to follow:**
- `clicky/leanring-buddy/leanring_buddyApp.swift:14-26` — minimal `@main` App struct with `NSApplicationDelegateAdaptor`
- `clicky/leanring-buddy/leanring-buddy.entitlements` — entitlement structure
- `clicky/leanring-buddy/Info.plist` — Info.plist key patterns

**Test expectation:** none — pure scaffolding with no behavioral code

**Verification:**
- Project opens in Xcode and builds without errors
- App bundle has `LSUIElement = true` (no dock icon when launched)
- App runs and shows nothing visible (no window, no dock icon) — expected for this scaffolding stage

---

### Unit 2: Settings persistence

- [ ] **Unit 2: Settings persistence**

**Goal:** Implement `SettingsStore` — a single `@MainActor` `ObservableObject` that reads/writes all user preferences to `UserDefaults` and exposes them as `@Published` properties.

**Requirements:** R14 (persistence), R10 (camera selection), R11 (shape), R12 (size), R13 (mirror), R5 (mode, corner), R9 (free-drag position)

**Dependencies:** None

**Files:**
- Create: `CursorCam/SettingsStore.swift`
- Test: `CursorCamTests/SettingsStoreTests.swift`

**Approach:**
- Single `@MainActor` `ObservableObject` class: `SettingsStore`
- Published properties with `didSet` writing to `UserDefaults.standard`:
  - `selectedCameraUniqueID: String?` (nil = default/first available)
  - `positioningMode: PositioningMode` (enum: `followCursor`, `pinToCorner`, `freeDrag`)
  - `pinnedCorner: Corner` (enum: `topLeft`, `topRight`, `bottomLeft`, `bottomRight`)
  - `cameraShape: CameraShape` (enum: `circle`, `roundedSquare`)
  - `cameraSize: CameraSize` (enum: `small`, `medium`, `large`)
  - `isMirrored: Bool`
  - `freeDragPosition: CGPoint?` (nil = not yet positioned)
  - `isCamOn: Bool` (not persisted — always starts false)
- All enums are `String`-backed for `UserDefaults` serialization via `RawRepresentable`
- `CGPoint` stored as two separate `CGFloat` keys (`freeDragPositionX`, `freeDragPositionY`)
- Default values match requirements (M size, circle shape, follow-cursor mode, bottom-right corner, mirror ON)
- `selectedCameraUniqueID = nil` means "auto-select first available camera" — resolved by `CameraManager`

**Patterns to follow:**
- Clicky's direct `UserDefaults.standard` access pattern (no property wrappers, no custom suites)
- `@Published private(set)` for state mutation funneled through dedicated setter methods

**Test scenarios:**
- Happy path: Setting each property writes to UserDefaults and reads back correctly
- Happy path: Default values are correct when no UserDefaults keys exist (fresh install)
- Edge case: `CGPoint` serialization round-trips correctly including negative coordinates
- Edge case: `selectedCameraUniqueID = nil` reads back as nil (not stored as string "nil")
- Edge case: Enum values that don't match any known case (future-proofing) fall back to defaults
- Edge case: Rapid successive writes don't lose values (last write wins)

**Verification:**
- All properties persist across app restarts (write, relaunch, read — manually verified)
- Tests pass for all serialization round-trips and defaults

---

### Unit 3: Camera manager

- [ ] **Unit 3: Camera manager**

**Goal:** Implement `CameraManager` — a `@MainActor` `ObservableObject` that manages `AVCaptureSession` lifecycle, device discovery, hot-plug handling, and exposes a `AVCaptureVideoPreviewLayer` for the overlay to render.

**Requirements:** R10 (camera enumeration), R16 (session lifecycle), R1 (preview layer)

**Dependencies:** Unit 2 (reads `selectedCameraUniqueID` from `SettingsStore`)

**Files:**
- Create: `CursorCam/CameraManager.swift`
- Test: `CursorCamTests/CameraManagerTests.swift`

**Approach:**
- Published properties:
  - `availableCameras: [AVCaptureDevice]` — all video input devices
  - `currentCamera: AVCaptureDevice?` — the active device
  - `cameraState: CameraState` — enum: `unavailable`, `restricted`, `starting`, `running`, `disconnected`, `error`
  - `previewLayer: AVCaptureVideoPreviewLayer?` — created when session starts
- `AVCaptureSession` with preset `.medium` (sufficient for 80-180px preview; 720p is overkill)
- Session starts on first `startSession()` call, stops on `stopSession()` or camera disconnect
- Device discovery via `AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera], mediaType: .video, position: .unspecified)`
- Hot-plug: observe `AVCaptureDevice.wasConnectedNotification` and `wasDisconnectedNotification`
  - On disconnect of active device: set `cameraState = .disconnected`, emit notification for UI
  - On connect of previously-selected device (matched by `uniqueID`): auto-reconnect and resume session
- Camera permission: check `AVCaptureDevice.authorizationStatus(for: .video)`. Handle all cases: `.authorized` (proceed), `.notDetermined` (request), `.denied` (show System Settings link), `.restricted` (parental controls / MDM — set `cameraState = .restricted` with explanatory message)
- `selectCamera(by uniqueID:)` method swaps the active input

**Patterns to follow:**
- Clicky's `CompanionManager.swift` — `@MainActor` `ObservableObject` with sub-system ownership
- Clicky's permission polling pattern (timer-based status checks for live updates)

**Test scenarios:**
- Happy path: `startSession()` creates preview layer, `cameraState` transitions to `.running`
- Happy path: `stopSession()` tears down session, `cameraState` transitions to `.unavailable`
- Happy path: `availableCameras` populates with at least one device on a Mac with a camera
- Edge case: `startSession()` when no camera is available → `cameraState = .unavailable`, no crash
- Edge case: Selecting a camera by `uniqueID` that doesn't exist → no-op, current camera unchanged
- Edge case: Rapid `startSession()`/`stopSession()` calls don't crash (guard against double-start)
- Edge case: `selectedCameraUniqueID = nil` → auto-selects first available camera
- Edge case: Camera permission is `.restricted` (parental controls / MDM) → `cameraState = .restricted`, no camera access possible

**Verification:**
- Preview layer renders live camera feed when session is running
- Camera picker (later, in Unit 5) shows all available cameras including Continuity Camera
- Session stays warm across stop/start (warm re-toggle) — verified by timing in Unit 6

---

### Unit 4: Overlay window system and camera preview

- [ ] **Unit 4: Overlay window system and camera preview**

**Goal:** Implement the per-screen overlay window infrastructure and the camera preview SwiftUI view. This is the visual core of the app — borderless transparent windows that host the camera feed and follow the cursor.

**Requirements:** R1 (borderless transparent window, non-activating, never steals focus), R7 (cursor tracking and spring animation), R8 (multi-monitor), R11 (shapes), R12 (sizes), R13 (mirror), R2 (capturable by screen recorders)

**Dependencies:** Unit 3 (preview layer from `CameraManager`), Unit 2 (shape, size, mirror from `SettingsStore`)

**Files:**
- Create: `CursorCam/OverlayWindowManager.swift` — per-screen `NSWindow` subclass + manager
- Create: `CursorCam/CameraPreviewView.swift` — SwiftUI view with `AVCaptureVideoPreviewLayer` wrapper, shapes, sizes, mirror
- Test: `CursorCamTests/OverlayWindowManagerTests.swift`

**Approach:**

**OverlayWindow (NSWindow subclass):**
- Initialized per `NSScreen` with `contentRect: screen.frame`, `styleMask: .borderless`
- Properties: `isOpaque = false`, `backgroundColor = .clear`, `level = .screenSaver`, `hasShadow = false`, `hidesOnDeactivate = false`
- `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`
- `canBecomeKey = false`, `canBecomeMain = false`
- `ignoresMouseEvents` toggled by positioning mode (true for follow/pin, false for free-drag)
- Hosts the preview view via `NSHostingView`

**OverlayWindowManager:**
- Maintains `[OverlayWindow]` — one per `NSScreen`
- `showOverlay()`: create one `OverlayWindow` per screen, host `CameraPreviewView`, `orderFrontRegardless()`
- `hideOverlay()`: `orderOut(nil)` + nil content view for each window
- `fadeInOverlay(duration: 0.25)`: animate window `alphaValue` from 0 to 1
- `fadeOutOverlay(duration: 0.4)`: animate window `alphaValue` from 1 to 0, then call `hideOverlay()`
- Fade animations are interruptible: check intent flag mid-animation and reverse if toggled
- Non-active display windows: set `alphaValue = 0.0` (not `isHidden = true`) to keep preview layer rendering
- Multi-monitor gating: track which screen contains the cursor, render only on that screen
- Cursor tracking: 60fps `Timer` polling `NSEvent.mouseLocation`
- Coordinate conversion: AppKit bottom-left → SwiftUI top-left (match Clicky's `convertScreenPointToSwiftUICoordinates`)
- Spring animation: `.spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0)` on cam position
- Offset: 15px right, 15px down from cursor (within the 10-20px range from R7)
- `NSScreen.screensDidChangeNotification` observer to handle display connect/disconnect

**CameraPreviewView (SwiftUI):**
- `NSViewRepresentable` wrapping a custom `CameraPreviewNSView: NSView` subclass (following Clicky's `AVPlayerNSView` pattern at `OverlayWindow.swift:861-881`)
- The custom `NSView` subclass owns an `AVCaptureVideoPreviewLayer` (not a player), configured with the session in `init(frame:)`, and overrides `layout()` to keep `previewLayer.frame = bounds`
- The `NSViewRepresentable` wrapper passes the `AVCaptureSession` from `CameraManager` through `updateNSView`
- Shape masking: `.clipShape(Circle())` or `.clipShape(RoundedRectangle(cornerRadius: proportionalToSize))` where corner radius is proportional to cam size: 14px at S, 20px at M, 30px at L
- Size: `frame(width: sizePixels, height: sizePixels)` based on `SettingsStore.cameraSize`
- Mirror: `.scaleEffect(x: isMirrored ? -1 : 1, y: 1)`
- Camera-unavailable overlay: when `cameraState != .running`, show SF Symbol `camera.metering.unknown` for unavailable/restricted, `camera.badge.ellipsis` for error/disconnected — centered in a `RoundedRectangle` with `.ultraThinMaterial`, 60% of cam size, at 24pt with `.secondary` foreground style
- The view fills the entire screen and the cam preview sits at a tracked position offset from the cursor

**Camera-unavailable visual indicator:**
- When `cameraState` is `unavailable`, `disconnected`, `restricted`, or `error`: show the appropriate SF Symbol (see above) in the cam frame (replacing the video feed), centered
- When `cameraState` is `.starting`: show a subtle progress indicator (SF Symbol `circle.dotted` with rotation animation) centered in the cam frame — avoids a black/unresponsive appearance during cold-start
- This ensures the user always sees *something* in the cam window position so they know where the cam would appear — no silent black window

**Patterns to follow:**
- `clicky/leanring-buddy/OverlayWindow.swift:14-53` — `OverlayWindow` NSWindow subclass with identical level/collectionBehavior
- `clicky/leanring-buddy/OverlayWindow.swift:778-840` — `OverlayWindowManager` per-screen lifecycle
- `clicky/leanring-buddy/OverlayWindow.swift:411-451` — cursor tracking timer and coordinate conversion
- `clicky/leanring-buddy/OverlayWindow.swift:844-881` — `NSViewRepresentable` wrapping `AVPlayerLayer` (swap for `AVCaptureVideoPreviewLayer`)

**Test scenarios:**
- Happy path: `showOverlay()` creates exactly one `OverlayWindow` per connected `NSScreen`
- Happy path: `fadeInOverlay()` animates windows from alpha 0 to 1 over ~250ms
- Happy path: `fadeOutOverlay()` animates windows from alpha 1 to 0 over ~400ms, then calls `hideOverlay()`
- Happy path: Camera preview renders in the correct shape (circle/rounded square) at the correct size
- Happy path: Mirror toggle flips the preview horizontally
- Edge case: Cursor on Screen 1 → cam visible on Screen 1 only, Screen 2 window at alpha 0
- Edge case: Cursor moves to Screen 2 → Screen 1 fades out, Screen 2 fades in (sequential, no overlap)
- Edge case: No camera available → camera-off symbol displayed in cam frame, no crash
- Edge case: Single monitor setup → only one overlay window created
- Edge case: `showOverlay()` called when already showing → `hideOverlay()` first, then re-create (idempotent)
- Integration: `CameraPreviewView` receives `previewLayer` from `CameraManager` and displays live feed

**Verification:**
- Cam window appears at cursor position with spring animation when shown
- Cam window is visible above all apps including full-screen apps and Mission Control spaces
- Cam window does not accept keyboard focus or become key
- Screen recorder (at minimum QuickTime Player screen recording) captures the cam window — test manually

---

### Unit 5: Positioning behavior

- [ ] **Unit 5: Positioning behavior**

**Goal:** Implement the three positioning modes (Follow cursor, Pin to corner, Free drag) with mode-switching transitions and multi-monitor awareness.

**Requirements:** R5 (three modes), R6 (glide transitions), R7 (60fps follow + spring), R8 (multi-monitor), R9 (hit-testable for free-drag, click-through for others)

**Dependencies:** Unit 4 (overlay windows exist, cursor tracking infrastructure established)

**Files:**
- Modify: `CursorCam/OverlayWindowManager.swift` — add positioning logic
- Modify: `CursorCam/CameraPreviewView.swift` — add drag gesture for free-drag mode
- Modify: `CursorCam/SettingsStore.swift` — add `freeDragPosition` persistence and positioning mode enum if not already present
- Test: `CursorCamTests/PositioningModeTests.swift`

**Approach:**

**PositioningMode enum:**
```swift
enum PositioningMode: String, CaseIterable {
    case followCursor
    case pinToCorner
    case freeDrag
}
```

**Mode-switching behavior:**
- Switching modes does not toggle cam off (R6)
- Cam glides (spring-animated) from current position to new resting position
- Exception: if distance to target < 10px, snap instantly (no animation for imperceptible moves)
- Mode switch while cam is OFF: mode is set but nothing visible (takes effect on next toggle-on)

**Follow-cursor mode:**
- 60fps `Timer` polls `NSEvent.mouseLocation`
- Cam positioned at cursor + (15, 15) offset in SwiftUI coordinates
- Spring animation: `.spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0)`
- Window `ignoresMouseEvents = true`
- Cursor-on-this-screen gate: `screenFrame.contains(NSEvent.mouseLocation)`
- If cursor exits all screens (non-contiguous display gap): hide all cams (fade to 0) until cursor re-enters a screen

**Pin-to-corner mode:**
- User selects a corner (TL/TR/BL/BR) from menu bar
- Cam glides from current position to the designated corner of the *active* display (cursor-containing)
- Corner position computed with 20px margin from screen edge
- When cursor moves to a different display: cam glides to that display's corresponding corner
- Non-active display windows: `alphaValue = 0`
- Window `ignoresMouseEvents = true`
- Default corner on first use: bottom-right

**Free-drag mode:**
- Window `ignoresMouseEvents = false`
- SwiftUI `DragGesture` on the camera preview view
- On drag end: persist position to `SettingsStore.freeDragPosition`
- First time entering free-drag (no persisted position): cam appears at current cursor position
- Subsequent times: cam appears at last persisted free-drag position
- If the persisted position is on a now-disconnected screen: fall back to cursor position on primary screen
- Multi-monitor: cam stays at its dragged position on whatever screen it was placed on; only that screen's window is visible
- If user is actively dragging and mode is switched away: complete the drag (defer mode switch to mouse-up) to avoid dropping the cam at an unintended intermediate position

**Multi-monitor display changes:**
- `NSScreen.screensDidChangeNotification` → re-sync overlay windows (create/destroy as screens connect/disconnect)
- On screen disconnect: if the active cam was on the disconnected screen, move cam to primary screen's equivalent position
- On screen connect: create new `OverlayWindow` for the new screen, keep it at alpha 0 until cursor enters it

**Patterns to follow:**
- `clicky/leanring-buddy/OverlayWindow.swift:411-451` — cursor tracking timer, coordinate conversion, screen gating
- `clicky/leanring-buddy/CompanionResponseOverlay.swift:120-153` — edge-clamping for panel positioning near cursor

**Test scenarios:**
- Happy path: In follow-cursor mode, cam position updates within one frame of cursor movement
- Happy path: Switching from follow-cursor to pin-to-corner glides cam to designated corner via spring animation
- Happy path: Switching from pin-to-corner to follow-cursor glides cam back to cursor position
- Happy path: In free-drag mode, drag gesture moves cam and persists position on release
- Happy path: Entering free-drag for first time places cam at current cursor position
- Happy path: Entering free-drag after previous drag restores last persisted position
- Edge case: Mode switch when distance to target < 10px → cam snaps instantly (no animation)
- Edge case: Cursor in non-contiguous screen gap → all cam windows at alpha 0
- Edge case: Screen disconnect while cam is on that screen → cam moves to primary screen
- Edge case: Screen connect while cam is on → new overlay window created for new screen
- Edge case: Persisted free-drag position on a now-disconnected screen → falls back to cursor on primary
- Edge case: Rapid mode switches don't produce visual artifacts or flicker
- Integration: `ignoresMouseEvents` is true in follow/pin modes, false in free-drag mode
- Integration: Multi-monitor crossover in follow mode fades old screen out and new screen in sequentially

**Verification:**
- Cam smoothly follows cursor at 60fps with no jank on Apple Silicon
- Cam glides between modes without toggling off
- Free-drag moves cam and position persists
- Only one cam visible at a time across multiple monitors
- Display connect/disconnect doesn't crash or leave orphaned windows

---

### Unit 6: Menu bar app shell, hotkey, and permission onboarding

- [ ] **Unit 6: Menu bar app shell, hotkey, and permission onboarding**

**Goal:** Implement the app entry point with menu bar status item, dropdown menu (mode/camera/shape/size/mirror/toggle), global hotkey toggle, and the first-launch permission onboarding flow.

**Requirements:** R3 (global hotkey), R4 (fade in/out), R5 (mode switching from menu), R10 (camera picker in menu), R11 (shape in menu), R12 (size in menu), R13 (mirror in menu), R15 (menu bar only, ON/OFF icon), R16 (session lifecycle), R17 (quit releases everything)

**Dependencies:** Unit 2 (SettingsStore), Unit 3 (CameraManager), Unit 4 (OverlayWindowManager), Unit 5 (positioning behavior)

**Files:**
- Modify: `CursorCam/CursorCamApp.swift` — wire up AppDelegate with all managers
- Create: `CursorCam/MenuBarManager.swift` — NSStatusItem + dropdown menu
- Create: `CursorCam/HotkeyMonitor.swift` — CGEvent tap for global hotkey
- Create: `CursorCam/PermissionsManager.swift` — Camera + Accessibility permission flows

**Approach:**

**CursorCamApp.swift:**
- `@main` SwiftUI `App` with `NSApplicationDelegateAdaptor(CursorCamAppDelegate.self)`
- AppDelegate creates and owns: `SettingsStore`, `CameraManager`, `OverlayWindowManager`, `HotkeyMonitor`, `MenuBarManager`, `PermissionsManager`
- Settings scene: `EmptyView()` (same pattern as Clicky)
- `applicationDidFinishLaunching`: check permissions, set up menu bar, start hotkey monitor, poll permissions
- `applicationWillTerminate`: stop camera session, stop hotkey monitor, tear down overlay windows

**MenuBarManager:**
- `NSStatusItem` with SF Symbol `camera` (outline) for OFF state
- ON state: `camera.fill` with a green dot overlay (composite image)
- Error/unavailable state: `camera.fill` with yellow warning badge
- Dropdown menu items:
  - "Turn Cam On" / "Turn Cam Off" (manual toggle — primary action)
  - Separator
  - "Positioning Mode" submenu: Follow Cursor, Pin to Corner (with corner submenu: TL/TR/BL/BR), Free Drag
  - "Camera" submenu: dynamically populated from `CameraManager.availableCameras`, checkmark on current
  - "Shape" submenu: Circle, Rounded Square
  - "Size" submenu: Small, Medium, Large
  - "Mirror" toggle item (checkmark)
  - Separator
  - Permission status items (greyed out, showing current status)
  - "Check Permissions..." → opens permission flow
  - Separator
  - "Quit Cursor-Cam"
- Menu rebuild on every open (or observe published changes) to reflect current state

**HotkeyMonitor:**
- Listen-only `CGEvent` tap for `⌃⌥C` (Control+Option+C)
- Same architecture as `clicky/leanring-buddy/GlobalPushToTalkShortcutMonitor.swift:15-132`
- Event mask: `.flagsChanged`, `.keyDown`, `.keyUp`
- Track `isShortcutCurrentlyPressed` state
- On `.keyDown` with matching chord: toggle cam (ON → OFF or OFF → ON)
- The toggle action is a boolean flip — if cam is mid-fade, reverse the animation direction from current opacity
- Guard against double-fire: if hotkey is already pressed, ignore repeated keyDown for the same chord
- Re-enable tap on `.tapDisabledByTimeout` / `.tapDisabledByUserInput`
- `start()` / `stop()` lifecycle methods
- Requires Accessibility permission (`AXIsProcessTrusted()`) — if not granted, hotkey is a no-op, and the menu bar toggle is the only toggle path

**PermissionsManager:**
- Camera permission: `AVCaptureDevice.authorizationStatus(for: .video)` + `requestAccess(for: .video)`
- Accessibility permission: `AXIsProcessTrusted()` + `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`
- Three-phase request pattern (matching Clicky's `WindowPositionManager.swift:19-151`):
  1. Check current permission
  2. If not granted and first attempt → trigger system prompt
  3. If not granted and system prompt already shown → open System Settings deep link
- Onboarding flow on first launch:
  1. Show alert: "Cursor-Cam needs camera access to show your video overlay." → request Camera
  2. After Camera granted (or if already granted): show alert: "Cursor-Cam uses a system-level keyboard listener ONLY to detect the ⌃⌥C hotkey. No keystrokes are ever recorded, stored, or sent anywhere. Without Accessibility access, you can still toggle the cam from the menu bar." → request Accessibility
  3. Poll both permissions every 1.5s via Timer for live status updates
- System Settings deep links:
  - Camera: `x-apple.systempreferences:com.apple.preference.security?Privacy_Camera`
  - Accessibility: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
- Menu bar shows permission warnings when either is missing

**Patterns to follow:**
- `clicky/leanring-buddy/leanring_buddyApp.swift:14-89` — App entry point, AppDelegate, lifecycle, login item
- `clicky/leanring-buddy/GlobalPushToTalkShortcutMonitor.swift` — CGEvent tap (entire file, 132 lines)
- `clicky/leanring-buddy/WindowPositionManager.swift:32-66` — Permission request orchestration
- `clicky/leanring-buddy/MenuBarPanelManager.swift:64-243` — NSStatusItem creation + menu

**Test scenarios:**
- Happy path: App launches with no dock icon, menu bar icon visible
- Happy path: Pressing `⌃⌥C` toggles cam on → cam fades in near cursor over ~250ms
- Happy path: Pressing `⌃⌥C` again toggles cam off → cam fades out over ~400ms
- Happy path: Menu bar "Turn Cam On/Off" toggles cam same as hotkey
- Happy path: Menu bar camera picker shows all available cameras and switches active camera
- Happy path: Menu bar shape/size/mirror changes apply immediately to visible cam
- Happy path: Switching positioning mode from menu applies immediately (no toggle required)
- Happy path: Quit from menu bar releases camera (no green light) and removes menu bar icon
- Edge case: Hotkey press during fade-in → cam reverses and fades out from current opacity
- Edge case: Hotkey press during fade-out → cam reverses and fades in from current opacity
- Edge case: Hotkey chord collision — pressing ⌃⌥C while other modifiers are also held does not trigger (superset guard)
- Edge case: Hotkey monitor does nothing when Accessibility permission is denied
- Edge case: No camera available → menu bar camera submenu shows "No Camera Available" (disabled)
- Error path: Camera permission denied → onboarding shows System Settings link, cam window shows camera-off symbol
- Error path: Accessibility permission denied → hotkey silently non-functional, menu bar shows warning, manual toggle still works
- Error path: Camera disconnected mid-session → cam window shows camera-off symbol, menu bar icon shows warning badge
- Integration: Toggle via hotkey calls `OverlayWindowManager.fadeInOverlay()` / `fadeOutOverlay()` correctly
- Integration: Camera selection from menu calls `CameraManager.selectCamera(by:)` and session updates

**Verification:**
- App appears as menu bar icon only (no dock icon, no main window)
- Hotkey toggles cam on/off with correct fade timing
- Menu bar dropdown reflects current state and all settings changes apply immediately
- First-launch permission flow works (Camera prompt → Accessibility prompt → polling)
- App is visible in System Settings > Privacy for both Camera and Accessibility
- Quitting removes all traces (no residual cam window, no camera green light, menu bar icon removed)

---

### Unit 7: Edge cases, polish, and system lifecycle

- [ ] **Unit 7: Edge cases, polish, and system lifecycle**

**Goal:** Handle system lifecycle events (sleep/wake, display connect/disconnect), rapid interactions, and camera-unavailable states to ensure the app is production-quality.

**Requirements:** All (hardening pass across R1-R17)

**Dependencies:** All previous units

**Files:**
- Modify: `CursorCam/OverlayWindowManager.swift` — sleep/wake handling, display change handling
- Modify: `CursorCam/CameraManager.swift` — sleep/wake handling for AVCaptureSession
- Modify: `CursorCam/HotkeyMonitor.swift` — sleep/wake re-registration for CGEvent tap
- Modify: `CursorCam/CursorCamApp.swift` — system notification observers

**Approach:**

**System sleep/wake:**
- Register for `NSWorkspace.willSleepNotification`:
  - Pause `AVCaptureSession` (preserves device connection)
  - Invalidate cursor polling timer
- Register for `NSWorkspace.didWakeNotification`:
  - Re-validate `NSScreen.screens` list (screens may have changed)
  - Re-sync overlay windows (create/destroy as needed)
  - Re-create CGEvent tap (taps can die during sleep)
  - Resume `AVCaptureSession` if cam was ON before sleep
  - Restart cursor polling timer

**Display connect/disconnect (NSScreen.screensDidChangeNotification):**
- On display connect: create new `OverlayWindow` for the new screen, set alpha 0
- On display disconnect: remove the overlay window for that screen
  - If the cam was positioned on the disconnected screen: reposition to primary screen
  - In free-drag mode: clear persisted position (it was on a now-gone screen)
  - In follow-cursor mode: cursor is now on a remaining screen, tracking continues naturally
  - In pin-to-corner mode: cam moves to primary screen's corner

**Interruptible fade animations:**
- The toggle intent (ON/OFF) is a boolean. Fade animations are purely visual.
- When toggling during a fade: immediately reverse `NSAnimationContext` direction from current `alphaValue`
- Guard: if `alphaValue` is at 0 or 1, the animation has already completed; start new fade normally

**Rapid mode switching guard:**
- Use a `currentModeSwitchTask: Task?` to cancel in-flight mode-switch animations when a new switch arrives
- Cancel the previous animation task, start the new mode-switch from current position

**Cursor-bouncing on screen edge (debounce):**
- When cursor rapidly crosses and recrosses a screen boundary, the cross-monitor fade handoff should debounce
- Simple approach: track `lastScreenSwitchTime`, ignore screen changes within 150ms of the last one

**Camera disconnect/reconnect during session:**
- Disconnect: set `cameraState = .disconnected`, show camera-off symbol in preview
- Reconnect (same `uniqueID` within 10 seconds): attempt reconnection, resume session, restore preview
- Reconnect timeout (no reconnect within 10 seconds): keep showing camera-off symbol, user must manually re-select
- If user manually selected the disconnected camera from the menu bar, keep the selection and attempt reconnect on the same schedule

**AVCaptureSession runtime errors:**
- Observe `AVCaptureSession.runtimeErrorNotification`
- Log the error, set `cameraState = .error`, show camera-off symbol
- User can manually restart via menu bar toggle (off → on cycle restarts session)

**Login item registration (opt-in):**
- Register via `SMAppService.mainApp.register()` on first successful permission grant
- Do NOT auto-register on launch — only after user has completed onboarding (permissions granted)

**Patterns to follow:**
- `clicky/leanring-buddy/GlobalPushToTalkShortcutMonitor.swift:100-107` — CGEvent tap re-enable on disable
- `clicky/leanring-buddy/OverlayWindow.swift:808-835` — fade and hide lifecycle, cleanup on removal

**Test scenarios:**
- Happy path: App survives system sleep/wake cycle, cam resumes if it was ON
- Happy path: External display connect creates new overlay window
- Happy path: External display disconnect cleans up orphaned window
- Edge case: Hotkey pressed during fade-in → animation reverses, cam fades out from current opacity
- Edge case: Hotkey pressed during fade-out → animation reverses, cam fades in from current opacity
- Edge case: Rapid cursor bouncing on screen edge → no flicker, debounce prevents rapid show/hide cycle
- Edge case: Camera disconnects mid-session → camera-off symbol shown, no crash
- Edge case: Camera reconnects within 10s → preview resumes automatically
- Edge case: Camera reconnects after 10s → preview stays off, user must manually re-select
- Error path: AVCaptureSession runtime error → camera-off symbol shown, user can toggle off/on to retry
- Error path: CGEvent tap disabled by timeout → auto-re-enabled, hotkey still works
- Integration: Sleep → wake → cam still works correctly including hotkey

**Verification:**
- `pmset sleepnow` → wake → cam resumes if ON, hotkey still works
- Plug/unplug external display → no crash, windows synced correctly
- Rapid hotkey double-press → clean animation reversal, no glitch
- Unplug camera → camera-off symbol, re-plug → auto-reconnect (within grace period)

## System-Wide Impact

- **Interaction graph:** `HotkeyMonitor` (CGEvent tap) → toggle intent → `OverlayWindowManager` (fade/show/hide) + `CameraManager` (start/stop). `MenuBarManager` (NSStatusItem) → parallel toggle path + settings mutations → `SettingsStore` → `CameraManager` + `OverlayWindowManager`. `PermissionsManager` → polls camera + accessibility status → updates `MenuBarManager` UI.
- **Error propagation:** Camera errors surface in the cam window (camera-off symbol) and menu bar (warning badge). Hotkey silent failure (no Accessibility) is logged and indicated in the menu bar. No modal dialogs during operation (menu-bar-only app).
- **State lifecycle risks:** `AVCaptureSession` held across toggle-off for warm re-toggle — must ensure it's properly released on quit. CGEvent tap must be invalidated on deinit to avoid leaks. `Timer` for cursor polling must be invalidated when overlay is hidden.
- **API surface parity:** No exported API. This is a standalone app with no programmatic interface.
- **Integration coverage:** Hotkey → fade → preview visibility must be tested as an integrated flow (Unit 6 integration scenarios). Camera selection → preview update must be tested end-to-end.
- **Unchanged invariants:** None — greenfield project.

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Screen recorders may not capture `LSUIElement` / `level=.screenSaver` windows | Test with Loom, Screen Studio, OBS, Recordly, QuickTime before shipping. Architecture matches Clicky which is proven with at least one recorder. |
| CGEvent tap may conflict with other apps using the same hotkey chord (`⌃⌥C`) | The hotkey can't be configured in v1, but the menu bar provides a fallback toggle. If conflicts are widespread, v2 hotkey configuration is the fix. |
| `AVCaptureSession` may not survive sleep/wake on all hardware | Test with `pmset sleepnow` on target hardware. Implement pause/resume pattern (not stop/start) to preserve device connection. |
| Performance budget (3-5W) may be exceeded on older Macs | 60fps cursor polling + `AVCaptureSession` at medium preset is lightweight. Profile with Activity Monitor. Spring animation tuning can trade responsiveness for CPU if needed. |
| iPhone Continuity Camera hot-plug reliability varies by iOS/macOS version | Subscribe to device connect/disconnect notifications. Implement reconnect-with-grace-period. If unreliable, v1.5 can add explicit "reconnect" button. |
| Mixed DPI displays (Retina + non-Retina) may cause coordinate misalignment | Clicky's coordinate conversion works for same-DPI. Mixed-DPI needs runtime testing. Fallback: use `NSScreen.backingScaleFactor` for each screen in coordinate math. |

## Documentation / Operational Notes

- No user-facing documentation in v1 (menu-bar-only app is self-documenting through the menu)
- Build output: notarized DMG. Sparkle appcast for updates (matching Clicky's distribution model)
- No server-side components, no API keys, no environment variables — purely local app
- No Cloudflare Worker needed (Clicky requires one for AI APIs; cursor-cam has no network dependency)

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-27-cursor-cam-requirements.md](../brainstorms/2026-04-27-cursor-cam-requirements.md)
- Reference implementation (Clicky): `leanring-buddy/OverlayWindow.swift`, `leanring-buddy/GlobalPushToTalkShortcutMonitor.swift`, `leanring-buddy/WindowPositionManager.swift`, `leanring-buddy/MenuBarPanelManager.swift`, `leanring-buddy/leanring_buddyApp.swift`
- Reference implementation (Clicky) AGENTS.md: conventions for Swift, AppKit bridging, naming, and project structure
