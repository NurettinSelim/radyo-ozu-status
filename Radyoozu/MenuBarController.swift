import AppKit
import AVFoundation
import Combine
import UserNotifications

@MainActor
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var pulseTimer: Timer?
    private let maxTitleLength = 40
    private var pulseAlpha: CGFloat = 0.0
    private var pulseDirection: CGFloat = 0.03
    private var audioPlayer: AVAudioPlayer?

    @Published var currentSong: String = "Loading..."
    @Published var isLive: Bool = false
    private var wasLive: Bool = false

    init() {
        setupStatusItem()
        requestNotificationPermission()
        startPolling()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = currentSong
            button.imagePosition = .imageLeft
            button.wantsLayer = true
            button.layer?.cornerRadius = 4
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

        // Detect live state transition
        if isLive && !wasLive {
            sendLiveNotification()
            startPulseAnimation()
        } else if !isLive && wasLive {
            stopPulseAnimation()
            playLiveEndedSound()
        } else if isLive && title != currentSong {
            // Title changed while live
            sendSongChangeNotification(title)
        }
        wasLive = isLive

        currentSong = title
        self.isLive = isLive

        updateButtonAppearance()

        if let menu = statusItem?.menu, let firstItem = menu.items.first {
            firstItem.title = isLive ? "🔴 LIVE: \(title)" : title
        }
    }

    private func updateButtonAppearance() {
        guard let button = statusItem?.button else { return }

        let displayTitle = truncateTitle(currentSong)

        // Create SF Symbol image
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let symbolName = "antenna.radiowaves.left.and.right"
        var icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Radio")?.withSymbolConfiguration(config)

        if isLive {
            // Tint icon red when live
            icon = icon?.tinted(with: .systemRed)
            // Pulse background
            button.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(pulseAlpha * 0.5).cgColor
            // Show icon when live
            button.image = icon
            button.imagePosition = .imageLeft
            button.title = " \(displayTitle)"
        } else {
            // Clear background when not live
            button.layer?.backgroundColor = NSColor.clear.cgColor
            // Hide icon when not live
            button.image = nil
            button.title = displayTitle
        }
    }

    // MARK: - Pulse Animation

    private func startPulseAnimation() {
        stopPulseAnimation()

        pulseAlpha = 0.0
        pulseDirection = 0.03

        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.animatePulse()
            }
        }
    }

    private func stopPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = nil
        pulseAlpha = 0.0

        if let button = statusItem?.button {
            button.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    private func animatePulse() {
        pulseAlpha += pulseDirection

        if pulseAlpha >= 1.0 {
            pulseDirection = -0.03
        } else if pulseAlpha <= 0.0 {
            pulseDirection = 0.03
        }

        if let button = statusItem?.button, isLive {
            button.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(pulseAlpha * 0.5).cgColor
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func sendLiveNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Radyo ÖzÜ is LIVE!"
        content.body = currentSong
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    private func sendSongChangeNotification(_ title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Now Playing"
        content.body = title
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }

    private func playLiveEndedSound() {
        guard let url = Bundle.main.url(forResource: "alert", withExtension: "mp3", subdirectory: "Resources") else {
            print("Sound file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }

    // MARK: - Helpers

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
        pulseTimer?.invalidate()
    }
}

// MARK: - NSImage Extension for Tinting

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}
