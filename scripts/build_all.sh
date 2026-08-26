#!/usr/bin/env bash
# Build Android release APK (+ optional AAB)
set -euo pipefail
cd "$(dirname "$0")/.."

MPORT_URL="${MPORT_URL:-https://mandalanet.id}"
MPORT_API_URL="${MPORT_API_URL:-}"

flutter pub get
bash scripts/fix_android_toolchain.sh

flutter build apk --release --tree-shake-icons \
  --dart-define=MPORT_URL="$MPORT_URL" \
  --dart-define=MPORT_API_URL="$MPORT_API_URL" \
  --dart-define=MPORT_AI=true

echo "APK: build/app/outputs/flutter-apk/app-release.apk"

if [[ "${BUILD_AAB:-0}" == "1" ]]; then
  flutter build appbundle --release --tree-shake-icons \
    --dart-define=MPORT_URL="$MPORT_URL" \
    --dart-define=MPORT_API_URL="$MPORT_API_URL" \
    --dart-define=MPORT_AI=true
  echo "AAB: build/app/outputs/bundle/release/app-release.aab"
fi
