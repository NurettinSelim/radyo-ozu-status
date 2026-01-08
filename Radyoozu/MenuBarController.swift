import AppKit
import Combine

@MainActor
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private let maxTitleLength = 40

    @Published var currentSong: String = "Loading..."
    @Published var isLive: Bool = false

    init() {
        setupStatusItem()
        startPolling()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = currentSong
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let songItem = NSMenuItem(title: currentSong, action: nil, keyEquivalent: "")
        songItem.isEnabled = false
        menu.addItem(songItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func startPolling() {
        fetchSong()

        // Poll every 1 second
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchSong()
            }
        }
    }

    private func fetchSong() {
        Task {
            let songInfo = await RadioService.shared.getCurrentSong()
            updateTitle(songInfo.title, isLive: songInfo.isLive)
        }
    }

    private func updateTitle(_ title: String, isLive: Bool) {
        // Only update if changed
        guard title != currentSong || isLive != self.isLive else { return }

        currentSong = title
        self.isLive = isLive

        let displayTitle = truncateTitle(title)

        if let button = statusItem?.button {
            if isLive {
                let liveTitle = "🔴 \(displayTitle)"
                let attributed = NSMutableAttributedString(string: liveTitle)
                attributed.addAttribute(.backgroundColor,
                                        value: NSColor.systemRed.withAlphaComponent(0.3),
                                        range: NSRange(location: 0, length: attributed.length))
                button.attributedTitle = attributed
            } else {
                button.attributedTitle = NSAttributedString(string: displayTitle)
            }
        }

        if let menu = statusItem?.menu, let firstItem = menu.items.first {
            firstItem.title = isLive ? "🔴 LIVE: \(title)" : title
        }
    }

    private func truncateTitle(_ title: String) -> String {
        if title.count <= maxTitleLength {
            return title
        }
        return String(title.prefix(maxTitleLength - 3)) + "..."
    }

    @objc private func refreshNow() {
        fetchSong()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    deinit {
        timer?.invalidate()
    }
}
