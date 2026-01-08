#!/bin/bash
set -e

APP_NAME="Radyo ÖzÜ Status"
APP_PATH=".build/$APP_NAME.app"

# Kill existing instance
pkill -f "$APP_NAME" 2>/dev/null || true

# Build
swift build

# Copy binary, plist, and resources
cp .build/debug/Radyoozu "$APP_PATH/Contents/MacOS/"
cp Radyoozu/Info.plist "$APP_PATH/Contents/"
cp -r .build/debug/Radyoozu_Radyoozu.bundle "$APP_PATH/Contents/Resources/" 2>/dev/null || true

# Sign and run
codesign --force --deep --sign - "$APP_PATH"
open "$APP_PATH"

echo "✅ $APP_NAME is running"
