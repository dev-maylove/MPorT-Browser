#!/usr/bin/env bash
# Ensure Android platform only
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create . --project-name browser --org id.mport --platforms=android
bash scripts/fix_android_toolchain.sh
flutter pub get
echo "Android platform ready."
