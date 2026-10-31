import SwiftUI

@main
struct OzDoroApp: App {
    @NSApplicationDelegateAdaptor(OzDoroAppDelegate.self)
    private var appDelegate

    // The application has no main window or Dock icon. The AppKit status item
    // is managed by the app delegate; the popover's content remains SwiftUI.
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
