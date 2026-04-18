#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="KeepClean"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/KeepClean.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.derived-data"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_HELPERS="$APP_CONTENTS/Helpers"
APP_RESOURCES="$APP_CONTENTS/Resources"
INFO_PLIST="$APP_CONTENTS/Info.plist"
SWIFT_BUILD_DIR="$ROOT_DIR/.swift-build"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ ! -d "$PROJECT_PATH" || "$ROOT_DIR/project.yml" -nt "$PROJECT_PATH" ]]; then
  xcodegen generate --spec "$ROOT_DIR/project.yml" >/dev/null
fi

build_with_xcode() {
  local xcode_app_bundle="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
  local xcode_app_binary="$xcode_app_bundle/Contents/MacOS/$APP_NAME"

  rm -rf "$xcode_app_bundle"

  if xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$APP_NAME" \
    -configuration Debug \
    -derivedDataPath "$DERIVED_DATA" \
    build >/dev/null; then
    APP_BUNDLE="$xcode_app_bundle"
    APP_BINARY="$xcode_app_binary"
    return 0
  fi

  return 1
}

build_with_swiftc() {
  SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
  APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
  APP_CONTENTS="$APP_BUNDLE/Contents"
  APP_MACOS="$APP_CONTENTS/MacOS"
  APP_HELPERS="$APP_CONTENTS/Helpers"
  APP_RESOURCES="$APP_CONTENTS/Resources"
  INFO_PLIST="$APP_CONTENTS/Info.plist"
  APP_BINARY="$SWIFT_BUILD_DIR/$APP_NAME"
  HELPER_BINARY="$SWIFT_BUILD_DIR/KeepCleanHelper"

  mkdir -p "$SWIFT_BUILD_DIR"

  xcrun swiftc \
    -parse-as-library \
    -sdk "$SDKROOT" \
    -target arm64-apple-macos15.0 \
    -framework CoreHID \
    -o "$HELPER_BINARY" \
    "$ROOT_DIR/KeepCleanHelper/main.swift" \
    $(find "$ROOT_DIR/KeepClean/Models" -name '*.swift' | sort) \
    "$ROOT_DIR/KeepClean/Support/AppError.swift" \
    "$ROOT_DIR/KeepClean/Services/BuiltInInputControlling.swift" \
    "$ROOT_DIR/KeepClean/Services/LiveBuiltInInputController.swift"

  xcrun swiftc \
    -sdk "$SDKROOT" \
    -target arm64-apple-macos15.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework CoreHID \
    -o "$APP_BINARY" \
    $(find "$ROOT_DIR/KeepClean" -name '*.swift' | sort)

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_HELPERS" "$APP_RESOURCES"
  cp "$APP_BINARY" "$APP_MACOS/$APP_NAME"
  cp "$HELPER_BINARY" "$APP_HELPERS/KeepCleanHelper"
  chmod +x "$APP_MACOS/$APP_NAME" "$APP_HELPERS/KeepCleanHelper"
  cp "$ROOT_DIR/KeepClean/Resources/profile.png" "$APP_RESOURCES/profile.png"
  cp "$ROOT_DIR/KeepClean/Resources/KeepClean.icns" "$APP_RESOURCES/KeepClean.icns"
  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>KeepClean.icns</string>
  <key>CFBundleIdentifier</key>
  <string>com.adhamhaithameid.keepclean</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

if ! build_with_xcode 2>/tmp/keepclean-xcodebuild.err; then
  build_with_swiftc
else
  APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"com.adhamhaithameid.keepclean\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
