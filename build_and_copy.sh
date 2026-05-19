#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="/storage/emulated/0/Codex/build"
APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"

cd "$PROJECT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is not installed or not in PATH" >&2
  exit 127
fi

mkdir -p "$DEST_DIR"
flutter pub get
flutter build apk --release
cp -f "$APK" "$DEST_DIR/QuickDrop-release.apk"
echo "$DEST_DIR/QuickDrop-release.apk"
