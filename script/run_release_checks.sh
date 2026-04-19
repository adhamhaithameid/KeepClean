#!/usr/bin/env bash
set -euo pipefail

APP_NAME="KeepClean"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/KeepClean.xcodeproj"
RESULT_DIR="$ROOT_DIR/.release-checks"
RESULT_BUNDLE="$RESULT_DIR/KeepCleanTests.xcresult"
TEST_LOG="$RESULT_DIR/unit-tests.log"
SUMMARY_PATH="$RESULT_DIR/summary.txt"
MAX_BUNDLE_MB="${MAX_BUNDLE_MB:-20}"
MAX_RSS_MB="${MAX_RSS_MB:-80}"
MAX_LAUNCH_MS="${MAX_LAUNCH_MS:-4000}"
MAX_NETWORK_SOCKETS="${MAX_NETWORK_SOCKETS:-0}"

generate_project_if_needed() {
  if [[ ! -d "$PROJECT_PATH" || "$ROOT_DIR/project.yml" -nt "$PROJECT_PATH" ]]; then
    xcodegen generate --spec "$ROOT_DIR/project.yml" >/dev/null
  fi
}

measure_now_ms() {
  perl -MTime::HiRes=time -e 'print int(time() * 1000)'
}

kill_running_app() {
  /usr/bin/osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

assert_app_not_running() {
  if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
    echo "$APP_NAME is still running when it should be closed." >&2
    return 1
  fi
}

run_unit_tests() {
  rm -rf "$RESULT_BUNDLE"
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$APP_NAME" \
    -destination 'platform=macOS' \
    -only-testing:KeepCleanTests \
    -resultBundlePath "$RESULT_BUNDLE" \
    test >"$TEST_LOG" 2>&1 || {
      tail -n 200 "$TEST_LOG" >&2
      return 1
    }
}

verify_release_app_footprint() {
  local release_app="$ROOT_DIR/release/$APP_NAME.app"
  local icon_file
  local bundle_kb
  local bundle_mb
  local start_ms
  local end_ms
  local launch_ms
  local pid
  local rss_kb
  local rss_mb
  local network_lines
  local network_socket_count

  [[ -x "$release_app/Contents/MacOS/$APP_NAME" ]]
  [[ -x "$release_app/Contents/Helpers/KeepCleanHelper" ]]
  [[ -f "$release_app/Contents/Resources/profile.png" ]]
  [[ -f "$release_app/Contents/Resources/KeepClean.icns" ]]
  [[ -f "$release_app/Contents/Resources/brand-mark.png" ]]
  icon_file="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$release_app/Contents/Info.plist")"
  [[ "$icon_file" == "KeepClean.icns" ]]
  /usr/bin/codesign --verify --deep --strict "$release_app"

  bundle_kb="$(du -sk "$release_app" | awk '{ print $1 }')"
  bundle_mb="$(( (bundle_kb + 1023) / 1024 ))"
  if (( bundle_mb > MAX_BUNDLE_MB )); then
    echo "Release app bundle is ${bundle_mb}MB, above the ${MAX_BUNDLE_MB}MB budget." >&2
    return 1
  fi

  kill_running_app
  assert_app_not_running
  start_ms="$(measure_now_ms)"
  /usr/bin/open -n "$release_app" --args UITEST_MOCK_INPUT
  for _ in {1..60}; do
    if pid="$(pgrep -n -x "$APP_NAME" 2>/dev/null)"; then
      break
    fi
    sleep 0.1
  done

  if [[ -z "${pid:-}" ]]; then
    echo "Release app did not launch." >&2
    return 1
  fi

  end_ms="$(measure_now_ms)"
  launch_ms="$(( end_ms - start_ms ))"
  if (( launch_ms > MAX_LAUNCH_MS )); then
    echo "Release app launch took ${launch_ms}ms, above the ${MAX_LAUNCH_MS}ms budget." >&2
    return 1
  fi

  sleep 1
  rss_kb="$(ps -o rss= -p "$pid" | awk '{$1=$1; print}')"
  rss_mb="$(( (rss_kb + 1023) / 1024 ))"
  if (( rss_mb > MAX_RSS_MB )); then
    echo "Release app RSS is ${rss_mb}MB, above the ${MAX_RSS_MB}MB budget." >&2
    return 1
  fi

  network_lines="$(/usr/sbin/lsof -Pan -p "$pid" -iTCP -iUDP 2>/dev/null || true)"
  network_socket_count="$(printf '%s\n' "$network_lines" | awk 'NR > 1 && NF { count++ } END { print count + 0 }')"
  if (( network_socket_count > MAX_NETWORK_SOCKETS )); then
    echo "Release app opened ${network_socket_count} network sockets while idle." >&2
    return 1
  fi

  {
    echo "Bundle size: ${bundle_mb}MB"
    echo "Launch time: ${launch_ms}ms"
    echo "RSS after launch: ${rss_mb}MB"
    echo "Idle network sockets: ${network_socket_count}"
  } >"$SUMMARY_PATH"

  kill_running_app
  assert_app_not_running
}

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"
trap kill_running_app EXIT

generate_project_if_needed
"$ROOT_DIR/script/run_logic_checks.sh"
run_unit_tests
xcrun xccov view --report "$RESULT_BUNDLE" >"$RESULT_DIR/coverage.txt"
"$ROOT_DIR/script/build_and_run.sh" --verify
"$ROOT_DIR/script/make_installers.sh" >/dev/null
verify_release_app_footprint

echo "Release checks passed."
cat "$SUMMARY_PATH"
echo "Coverage report: $RESULT_DIR/coverage.txt"
echo "Unit test log: $TEST_LOG"
