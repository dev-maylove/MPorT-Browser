# MPorT Browser — CI/Build Audit

## Latest toolchain update

Updated the Android build toolchain to the currently documented stable combination:
- Android Gradle Plugin (AGP): **9.3.0**
- Gradle: **9.5.0**
- Java/JDK: **17**
- Kotlin: **built-in Kotlin via AGP 9** (no explicit `org.jetbrains.kotlin.android` plugin)
- Android DSL: **new DSL enabled** (`android.newDsl=true`)
- Flutter CI: stable channel

This removes the previous explicit KGP 2.2.10/2.3.20 mismatch and avoids applying the legacy Kotlin Gradle Plugin with AGP 9.

## CI error addressed

The previous build failed because Flutter detected Kotlin Gradle Plugin 2.2.10:
`Your project's Kotlin version (2.2.10) is lower than Flutter's minimum supported version of 2.2.20.`

The project now uses AGP's built-in Kotlin integration instead of declaring `org.jetbrains.kotlin.android` in the Android app.

## Files changed

- `android/settings.gradle`
- `android/app/build.gradle`
- `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.properties`

No Dart source, assets, signing credentials, or application security configuration was intentionally changed.

## Validation

- ZIP extraction/repackaging verified.
- No `2.2.10` reference remains in Android build configuration.
- No explicit `org.jetbrains.kotlin.android` application remains in the Android project.
- Gradle wrapper points to Gradle 9.5.0.
- AGP plugin points to 9.3.0.

A full `flutter build apk --release` still requires a Flutter/Android SDK environment and signing secrets, so this package has not been claimed as a locally produced APK.
