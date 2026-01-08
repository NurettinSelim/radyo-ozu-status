# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Build the app
swift build

# Build and run (create app bundle first time)
swift build && mkdir -p .build/Radyoozu.app/Contents/MacOS && cp .build/debug/Radyoozu .build/Radyoozu.app/Contents/MacOS/ && cp Radyoozu/Info.plist .build/Radyoozu.app/Contents/ && echo -n 'APPL????' > .build/Radyoozu.app/Contents/PkgInfo && codesign --force --deep --sign - .build/Radyoozu.app && open .build/Radyoozu.app

# Quick rebuild and run (after initial setup)
swift build && cp .build/debug/Radyoozu .build/Radyoozu.app/Contents/MacOS/ && open .build/Radyoozu.app

# Stop the app
pkill Radyoozu
```

## Architecture

Native macOS menubar app (Swift 5.9, macOS 13+) displaying Radyo ÖzÜ radio station status.

**Data Flow:**
```
Radio.co API → RadioService → MenuBarController → NSStatusItem
```

**Components:**
- `RadyoozuApp.swift` - SwiftUI app entry with NSApplicationDelegateAdaptor for AppKit integration
- `MenuBarController.swift` - NSStatusItem management, 1-second polling loop, live indicator UI
- `RadioService.swift` - Async API client (actor-based) fetching from radio.co
- `RadioStatus.swift` - Codable models for API response with snake_case mapping

**Key Behaviors:**
- Polls `https://public.radio.co/stations/s3ab6bdcb9/status` every second
- Shows 🔴 with red background when `source.type == "live"`
- Menubar-only app (LSUIElement=true in Info.plist, no dock icon)
- Updates only when title or live status changes (debounced)
