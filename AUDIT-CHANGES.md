# Audit Changes — MPorT Browser v11

## CI build fix

Fixed the Gradle configuration error:

`Cannot resolve external dependency org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20 because no repositories are defined.`

### Changes
- Added `google()`, `mavenCentral()`, and `gradlePluginPortal()` to the root `buildscript.repositories` block.
- Kept Kotlin Gradle Plugin pinned at `2.3.20`.
- Kept Android Gradle Plugin at `9.3.0`.
- Kept Gradle wrapper at `9.5.0`.
- Kept Java/JDK target at 17.
- Kept `android.builtInKotlin=true`.
- Kept `android.newDsl=false` compatibility setting from v9.
- No application Dart/source logic was intentionally changed for this fix.

## Verification

- Confirmed the KGP dependency has repositories available to the `buildscript` classpath configuration.
- Confirmed no `2.2.10` KGP reference exists in `android/`.
- ZIP archive integrity verified after repackaging.


## v13 – compileSdk 37 fix
- Updated `android/app/build.gradle` from `compileSdk flutter.compileSdkVersion` (resolved to 36 in CI) to `compileSdk 37`.
- This satisfies `flutter_secure_storage`, which requires Android API 37+.
- Kept minSdk/targetSdk unchanged; compileSdk can be raised independently.
