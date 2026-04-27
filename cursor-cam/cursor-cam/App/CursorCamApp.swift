import SwiftUI

@main
struct CursorCamApp: App {
    @NSApplicationDelegateAdaptor(CursorCamAppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
