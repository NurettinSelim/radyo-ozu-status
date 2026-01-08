# Radyo ÖzÜ Status

macOS menubar app to track Radyo ÖzÜ radio station status.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- 🎵 Shows current song in menubar
- 📡 Live indicator (antenna icon + pulsing red background) when broadcasting live
- 🔔 macOS notification when station goes live
- 🎶 Notification on song change while live
- 🔊 Alert sound when live broadcast ends

## Requirements

- macOS 13.0 (Ventura) or later

## Installation

1. Download the latest release
2. Unzip and move `Radyo ÖzÜ Status.app` to Applications
3. Right-click → Open (required first time for unsigned app)
4. Optional: Add to Login Items in System Settings for auto-start

## Building from Source

```bash
# Clone the repository
git clone https://github.com/NurettinSelim/radyo-ozu-status.git
cd radyo-ozu-status

# Build and run
swift build
./build.sh
```

## License

MIT
