#!/usr/bin/env bash
set -euo pipefail

# Non-destructive toolchain check. This script never deletes or regenerates Gradle files.
command -v flutter >/dev/null || { echo 'Flutter is required'; exit 1; }
flutter --version
[[ -f android/gradle/wrapper/gradle-wrapper.properties ]] || { echo 'Gradle wrapper missing'; exit 1; }
[[ -f android/app/build.gradle ]] || { echo 'Android build file missing'; exit 1; }
echo 'Android toolchain files validated; no files were rewritten.'
