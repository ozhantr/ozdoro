import AppKit
import Combine
import SwiftUI

/// Owns the stable menu-bar item, independently from SwiftUI view updates.
/// Changing its button title never recreates a menu or the SwiftUI popover.
@MainActor
final class OzDoroAppDelegate: NSObject, NSApplicationDelegate {
    private let timer = PomodoroTimer()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configurePopover()
        observeTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cancellables.removeAll()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = item.button else { return }

        button.imagePosition = .imageLeading
        button.font = NSFont.monospacedDigitSystemFont(
            ofSize: NSFont.systemFontSize,
            weight: .medium
        )
        button.toolTip = L10n.appTooltip
        button.title = timer.formattedRemaining
        updateIcon(for: timer.phase, button: button)
        button.target = self
        button.action = #selector(togglePopover(_:))
        statusItem = item
    }

    private func configurePopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContent(timer: timer)
        )
        self.popover = popover
    }

    private func observeTimer() {
        // @Published sends the new value BEFORE the property is assigned.
        // Use the emitted value rather than reading timer.remainingSeconds.
        timer.$remainingSeconds
            .map { seconds in
                String(format: "%02d:%02d", seconds / 60, seconds % 60)
            }
            .removeDuplicates()
            .sink { [weak self] title in
                self?.statusItem?.button?.title = title
            }
            .store(in: &cancellables)

        timer.$cycle
            .map(\.phase)
            .removeDuplicates()
            .sink { [weak self] phase in
                guard let button = self?.statusItem?.button else { return }
                self?.updateIcon(for: phase, button: button)
            }
            .store(in: &cancellables)
    }

    private func updateIcon(for phase: PomodoroPhase, button: NSStatusBarButton) {
        let image = NSImage(
            systemSymbolName: phase.symbol,
            accessibilityDescription: L10n.phaseTitle(phase)
        )
        image?.isTemplate = true
        button.image = image
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
