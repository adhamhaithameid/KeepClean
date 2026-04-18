#!/usr/bin/env bash
set -euo pipefail

APP_NAME="KeepClean"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/KeepClean.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.derived-data-release"
RELEASE_DIR="$ROOT_DIR/release"
DMG_ROOT="$RELEASE_DIR/.dmg-root"
DMG_MOUNT="/private/tmp/KeepClean-dmg-mount"
DMG_BACKGROUND="$DMG_ROOT/.background/installer-background.png"
TEMP_DMG="$RELEASE_DIR/$APP_NAME-temp.dmg"
BUILD_LOG="$RELEASE_DIR/release-build.log"
DMG_DEVICE=""

version_from_project() {
  awk '/MARKETING_VERSION:/ { print $2; exit }' "$ROOT_DIR/project.yml"
}

VERSION="$(version_from_project)"
BUILD_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
RELEASE_APP="$RELEASE_DIR/$APP_NAME.app"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macOS.zip"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macOS.dmg"
CHECKSUM_PATH="$RELEASE_DIR/SHA256SUMS.txt"

generate_project_if_needed() {
  if [[ ! -d "$PROJECT_PATH" || "$ROOT_DIR/project.yml" -nt "$PROJECT_PATH" ]]; then
    xcodegen generate --spec "$ROOT_DIR/project.yml" >/dev/null
  fi
}

build_release_app() {
  rm -rf "$BUILD_APP"
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA" \
    -destination 'platform=macOS' \
    build >"$BUILD_LOG" 2>&1 || {
      tail -n 200 "$BUILD_LOG" >&2
      return 1
    }
}

verify_bundle_contents() {
  [[ -x "$RELEASE_APP/Contents/MacOS/$APP_NAME" ]]
  [[ -x "$RELEASE_APP/Contents/Helpers/KeepCleanHelper" ]]
  [[ -f "$RELEASE_APP/Contents/Resources/profile.png" ]]
  [[ -f "$RELEASE_APP/Contents/Resources/KeepClean.icns" ]]
}

create_dmg_background() {
  /usr/bin/env swift "$ROOT_DIR/script/create_dmg_background.swift" "$DMG_BACKGROUND"
}

detach_dmg_mount() {
  local attempt

  for attempt in 1 2 3 4 5; do
    if [[ -z "$DMG_DEVICE" ]] && ! mount | grep -F "on $DMG_MOUNT " >/dev/null 2>&1; then
      return 0
    fi

    if [[ -n "$DMG_DEVICE" ]]; then
      if hdiutil detach "$DMG_DEVICE" -quiet >/dev/null 2>&1; then
        DMG_DEVICE=""
        return 0
      fi
    elif hdiutil detach "$DMG_MOUNT" -quiet >/dev/null 2>&1; then
      return 0
    fi

    sleep 1
  done

  if [[ -n "$DMG_DEVICE" ]]; then
    hdiutil detach "$DMG_DEVICE" -force -quiet >/dev/null 2>&1 || true
    DMG_DEVICE=""
  elif mount | grep -F "on $DMG_MOUNT " >/dev/null 2>&1; then
    hdiutil detach "$DMG_MOUNT" -force -quiet >/dev/null 2>&1 || true
  fi
}

customize_dmg_window() {
  detach_dmg_mount
  rm -rf "$DMG_MOUNT" >/dev/null 2>&1 || true
  mkdir -p "$DMG_MOUNT"

  DMG_DEVICE="$(
    hdiutil attach "$TEMP_DMG" -mountpoint "$DMG_MOUNT" -readwrite -noverify -noautoopen |
      awk '/^\/dev\// { device = $1 } END { print device }'
  )"

  osascript <<EOF >/dev/null
tell application "Finder"
  set mountedFolder to POSIX file "$DMG_MOUNT" as alias
  open mountedFolder
  delay 1
  set dmgWindow to container window of mountedFolder
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set bounds of dmgWindow to {120, 120, 820, 540}
  set theViewOptions to the icon view options of dmgWindow
  set arrangement of theViewOptions to not arranged
  set icon size of theViewOptions to 112
  set text size of theViewOptions to 14
  set background picture of theViewOptions to POSIX file "$DMG_MOUNT/.background/installer-background.png" as alias
  set position of item "$APP_NAME.app" of mountedFolder to {180, 232}
  set position of item "Applications" of mountedFolder to {500, 232}
  close dmgWindow
  open mountedFolder
  delay 1
  set dmgWindow to container window of mountedFolder
  close dmgWindow
end tell
EOF

  /usr/bin/SetFile -a V "$DMG_MOUNT/.background" >/dev/null 2>&1 || true
  sync
  sleep 1
  detach_dmg_mount
}

verify_dmg_contents() {
  detach_dmg_mount
  rm -rf "$DMG_MOUNT" >/dev/null 2>&1 || true
  mkdir -p "$DMG_MOUNT"

  hdiutil attach "$DMG_PATH" -mountpoint "$DMG_MOUNT" -readonly -noverify -noautoopen -quiet
  [[ -d "$DMG_MOUNT/$APP_NAME.app" ]]
  [[ -L "$DMG_MOUNT/Applications" ]]
  [[ -f "$DMG_MOUNT/.background/installer-background.png" ]]
  detach_dmg_mount
}

cleanup() {
  detach_dmg_mount
  rm -f "$TEMP_DMG"
  rm -rf "$DMG_MOUNT" >/dev/null 2>&1 || true
}

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
trap cleanup EXIT

generate_project_if_needed
build_release_app

ditto "$BUILD_APP" "$RELEASE_APP"
/usr/bin/codesign --force --sign - --deep --timestamp=none "$RELEASE_APP" >/dev/null
/usr/bin/codesign --verify --deep --strict "$RELEASE_APP"
verify_bundle_contents

ditto -c -k --sequesterRsrc --keepParent "$RELEASE_APP" "$ZIP_PATH"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT/.background"
ditto "$RELEASE_APP" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"
create_dmg_background

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDRW \
  "$TEMP_DMG" >/dev/null
customize_dmg_window
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH" >/dev/null
verify_dmg_contents

shasum -a 256 "$ZIP_PATH" "$DMG_PATH" >"$CHECKSUM_PATH"

echo "Created local installable artifacts (ad hoc signed):"
echo "  $RELEASE_APP"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo "  $CHECKSUM_PATH"
echo "For public notarized builds, run ./script/notarize_release.sh with Developer ID credentials configured."
