#!/usr/bin/env bash
set -euo pipefail

APP_NAME="KeepClean"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
DMG_ROOT="$RELEASE_DIR/.dmg-root"
NOTARY_LOG_DIR="$RELEASE_DIR/notary-logs"

version_from_project() {
  awk '/MARKETING_VERSION:/ { print $2; exit }' "$ROOT_DIR/project.yml"
}

VERSION="$(version_from_project)"
RELEASE_APP="$RELEASE_DIR/$APP_NAME.app"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macOS.zip"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macOS.dmg"
CHECKSUM_PATH="$RELEASE_DIR/SHA256SUMS.txt"

DEVELOPER_ID_APPLICATION="${DEVELOPER_ID_APPLICATION:-}"
NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"

require_env() {
  if [[ -z "$DEVELOPER_ID_APPLICATION" ]]; then
    echo "Set DEVELOPER_ID_APPLICATION to your Developer ID Application certificate name." >&2
    exit 2
  fi

  if [[ -z "$NOTARY_KEYCHAIN_PROFILE" ]]; then
    echo "Set NOTARY_KEYCHAIN_PROFILE to the saved notarytool keychain profile name." >&2
    exit 2
  fi
}

verify_signing_identity() {
  if ! security find-identity -v -p codesigning | grep -F "$DEVELOPER_ID_APPLICATION" >/dev/null; then
    echo "Developer ID identity '$DEVELOPER_ID_APPLICATION' was not found in the local keychain." >&2
    exit 3
  fi
}

rebuild_archives() {
  rm -f "$ZIP_PATH" "$DMG_PATH"

  ditto -c -k --sequesterRsrc --keepParent "$RELEASE_APP" "$ZIP_PATH"

  rm -rf "$DMG_ROOT"
  mkdir -p "$DMG_ROOT"
  ditto "$RELEASE_APP" "$DMG_ROOT/$APP_NAME.app"
  ln -s /Applications "$DMG_ROOT/Applications"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null
}

sign_release_app() {
  /usr/bin/codesign \
    --force \
    --sign "$DEVELOPER_ID_APPLICATION" \
    --timestamp \
    --options runtime \
    "$RELEASE_APP/Contents/Helpers/KeepCleanHelper"

  /usr/bin/codesign \
    --force \
    --sign "$DEVELOPER_ID_APPLICATION" \
    --timestamp \
    --options runtime \
    "$RELEASE_APP"

  /usr/bin/codesign --verify --deep --strict "$RELEASE_APP"
}

submit_for_notarization() {
  local artifact_path="$1"
  local label="$2"
  local log_path="$NOTARY_LOG_DIR/$label.json"

  xcrun notarytool submit \
    "$artifact_path" \
    --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
    --wait \
    --output-format json >"$log_path"
}

staple_artifact() {
  xcrun stapler staple "$1" >/dev/null
}

require_env
verify_signing_identity

"$ROOT_DIR/script/make_installers.sh" >/dev/null

if [[ ! -d "$RELEASE_APP" ]]; then
  echo "Expected release app at $RELEASE_APP, but it was not created." >&2
  exit 4
fi

mkdir -p "$NOTARY_LOG_DIR"

sign_release_app
rebuild_archives

submit_for_notarization "$ZIP_PATH" "zip"
staple_artifact "$RELEASE_APP"
rebuild_archives

submit_for_notarization "$DMG_PATH" "dmg"
staple_artifact "$DMG_PATH"

spctl --assess --type execute --verbose=4 "$RELEASE_APP"
shasum -a 256 "$ZIP_PATH" "$DMG_PATH" >"$CHECKSUM_PATH"

echo "Notarized release artifacts:"
echo "  $RELEASE_APP"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo "Notary logs:"
echo "  $NOTARY_LOG_DIR/zip.json"
echo "  $NOTARY_LOG_DIR/dmg.json"
