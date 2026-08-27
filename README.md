# MPorT Browser (Android)

Flutter browser for the **MandalaNet / MPorT ISP** ecosystem — **Android only**.

- **App name:** MPorT Browser  
- **applicationId:** `id.mport.browser`  
- **Version:** 2.0.1+2  

---

## Requirements

- Flutter stable (3.47+)
- Java 17
- Android SDK

```bash
flutter pub get
chmod +x scripts/*.sh
./scripts/enable_platforms.sh   # ensure android/ + toolchain
```

## Configure backend (optional)

```bash
export MPORT_URL=https://mandalanet.id
export MPORT_API_URL=https://portal.example/api
export MPORT_AI=true
```

## Local build

```bash
# APK
./scripts/build_all.sh

# APK + AAB
BUILD_AAB=1 ./scripts/build_all.sh

# Manual
flutter build apk --release --tree-shake-icons \
  --dart-define=MPORT_URL=$MPORT_URL \
  --dart-define=MPORT_API_URL=$MPORT_API_URL

flutter build appbundle --release
```

**Output**

| Artifact | Path |
|----------|------|
| APK | `build/app/outputs/flutter-apk/app-release.apk` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

---

## GitHub Actions

**Workflow:** `.github/workflows/build-android.yml`  
**Name:** MPorT Browser Android  

**Triggers**

- Push to `main`
- Manual **Run workflow**

**Artifacts**

- `MPorT-Android-APK` → `app-release.apk`
- `MPorT-Android-AAB` → `app-release.aab`

Set repository **Variables** (optional): `MPORT_URL`, `MPORT_API_URL`.

---

## Install APK on device

1. Download `app-release.apk` from Actions artifacts (or local build).
2. On phone: allow **Install unknown apps**.
3. Open the APK → **Install**.

**ADB**

```bash
adb install -r app-release.apk
```

## Play Store (AAB)

1. [Play Console](https://play.google.com/console) → app **MPorT Browser**
2. Create release → upload `app-release.aab`

---

## Android toolchain

| Component | Version |
|-----------|---------|
| **AGP** | 9.1.1 |
| **Kotlin** | 2.2.20 + builtInKotlin=true |
| **Gradle** | 9.3.1 |
| **Java** | 17 |
| **minSdk** | 24 |
| **applicationId** | `id.mport.browser` |

---

## Project layout

```text
android/          # Native Android
lib/              # Dart UI & browser logic
assets/images/    # Logo & branding
scripts/          # enable_platforms, fix_android_toolchain, build_all
.github/workflows/build-android.yml
```

Other platforms (iOS / web / desktop) have been removed from this repo.


---

## Engine browser (Android)

**webview_flutter 4.14.1** (official Flutter team, System WebView / Chromium).


MPorT memakai **Android System WebView berbasis Chromium** lewat `webview_flutter`
(standar industri untuk browser Flutter mobile, setara Chrome mobile API).

**Bukan** embed Chromium/CEF penuh:
- CEF (`webview_cef`) hanya untuk **desktop** (Windows/macOS/Linux)
- Ekstensi Chrome (`.crx` / Add to Chrome) **tidak didukung** di WebView Android

## MPorT AI (Gemini — gratis)

MPorT AI memakai **Google Gemini free tier** saja (provider berbayar dihapus).

1. Buat key gratis: https://aistudio.google.com/apikey
2. Di app: **MPorT AI → ikon key** → tempel API key
3. Atau build-time:

```bash
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=YOUR_KEY \
  --dart-define=GEMINI_MODEL=gemini-3.7-flash
```

Model default: `gemini-3.7-flash` (stable, free tier).

GitHub Actions: tambahkan repository **Secret** `GEMINI_API_KEY` (dan optional Variable `GEMINI_MODEL`).

Fallback: jika `MPORT_API_URL` di-set, Laravel `/api/v1/ai/chat` dipakai saat Gemini gagal atau belum ada key.

