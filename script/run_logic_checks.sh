#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
TMP_DIR="$ROOT_DIR/.logic-checks"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

xcrun swiftc \
  -sdk "$SDKROOT" \
  -target arm64-apple-macos13.0 \
  -o "$TMP_DIR/logic-checks" \
  "$ROOT_DIR/script/verify_logic.swift" \
  $(find "$ROOT_DIR/KeepClean/Models" -name '*.swift' | sort)

"$TMP_DIR/logic-checks"
