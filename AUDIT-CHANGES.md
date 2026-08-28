# MPorT Browser — v9 CI fix

## Fixed

- Fixed Flutter 3.47.2 + AGP 9 build failure caused by the Flutter Gradle plugin receiving an AGP 9 `ApplicationExtensionImpl` while legacy DSL access was enabled incorrectly.
- Changed `android.newDsl=true` to `android.newDsl=false` so Flutter 3.47.2 uses its AGP-9 compatibility path for legacy DSL types.
- Kept Built-in Kotlin enabled with `android.builtInKotlin=true`.
- Kept the latest selected Android toolchain from v8: AGP 9.3.0, Gradle 9.5.0, JDK 17.
- No `org.jetbrains.kotlin.android` plugin is applied by the app.

## Rationale

The CI error was:
`ApplicationExtensionImpl$AgpDecorated_Decorated cannot be cast to AbstractAppExtension`.

Flutter's migration documentation states that AGP 9 uses the new DSL interfaces and that Flutter provides a compatibility path for legacy DSL types; the `android.newDsl` flag controls this migration path. For Flutter 3.47.x, disabling the new DSL avoids the class-cast failure while keeping AGP 9 and built-in Kotlin enabled.

## Verification

- ZIP extraction/repack integrity checked.
- Android configuration checked for stale Kotlin plugin declarations and conflicting DSL flags.
- `android.newDsl=false` and `android.builtInKotlin=true` are the only active migration flags.


## v10 — Flutter 3.47.2 KGP compatibility fix

- Fixed CI failure where AGP 9 built-in Kotlin exposed bundled KGP 2.2.10, below Flutter 3.47.2 minimum 2.2.20.
- Explicitly pins `org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20` in the root Gradle buildscript, as supported for overriding AGP's bundled KGP.
- Kept AGP 9.3.0, Gradle 9.5.0, Java 17, `android.builtInKotlin=true`, and `android.newDsl=false`.
- No `org.jetbrains.kotlin.android` plugin is applied by the app.
