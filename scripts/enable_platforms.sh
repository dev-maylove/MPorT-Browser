#!/usr/bin/env bash
set -euo pipefail

# Non-destructive validation. Never run `flutter create .` over an existing project.
[[ -f pubspec.yaml ]] || { echo 'pubspec.yaml not found'; exit 1; }
[[ -d android ]] || { echo 'android directory not found'; exit 1; }
[[ -f android/app/build.gradle ]] || { echo 'android/app/build.gradle not found'; exit 1; }
echo 'MPorT Android platform is already present; no files were regenerated.'
