#!/usr/bin/env bash
# build.sh — UDFViewer.app'i SwiftPM (yalnızca Command Line Tools) ile derler,
# .app + iki .appex paketini elle monte eder ve ad-hoc imzalar. Tam Xcode GEREKMEZ.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
APP="$ROOT/build/UDFViewer.app"
BIN="$ROOT/.build/release"

echo "[1/4] swift build -c release"
swift build -c release

echo "[2/4] .app paketini monte et"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
PREV="$APP/Contents/PlugIns/QuickLookPreview.appex"
THUMB="$APP/Contents/PlugIns/QuickLookThumbnail.appex"
mkdir -p "$PREV/Contents/MacOS" "$THUMB/Contents/MacOS"

# Host app
cp "$BIN/UDFViewer" "$APP/Contents/MacOS/UDFViewer"
cp "$ROOT/HostApp/Info.plist" "$APP/Contents/Info.plist"

# Ikon: depoda hazir yoksa uret, Resources'a gom (UYAP-editor ailesi stili)
mkdir -p "$APP/Contents/Resources"
if [ ! -f "$ROOT/assets/UDFViewer.icns" ]; then
  swift "$ROOT/scripts/make-icon.swift"
fi
cp "$ROOT/assets/UDFViewer.icns" "$APP/Contents/Resources/UDFViewer.icns"

# Preview extension
cp "$BIN/QuickLookPreview" "$PREV/Contents/MacOS/QuickLookPreview"
cp "$ROOT/QuickLookPreview/Info.plist" "$PREV/Contents/Info.plist"

# Thumbnail extension
cp "$BIN/QuickLookThumbnail" "$THUMB/Contents/MacOS/QuickLookThumbnail"
cp "$ROOT/QuickLookThumbnail/Info.plist" "$THUMB/Contents/Info.plist"

echo "[3/4] ad-hoc imzala (içten dışa: önce .appex'ler, sonra .app)"
codesign --force --sign - --timestamp=none \
  --entitlements "$ROOT/QuickLookPreview/QuickLookPreview.entitlements" "$PREV"
codesign --force --sign - --timestamp=none \
  --entitlements "$ROOT/QuickLookThumbnail/QuickLookThumbnail.entitlements" "$THUMB"
codesign --force --sign - --timestamp=none "$APP"

echo "[4/4] imza doğrulama"
codesign --verify --deep --strict "$APP"
echo "OK: $APP"
