# MPorT Browser Pro — Security & Architecture Changes

## Applied
- Removed client-side Gemini API calls and API-key UI/storage.
- AI now uses MPorT AI Gateway (`MPORT_API_URL`).
- Auth token moved from SharedPreferences to `flutter_secure_storage` 11.0.0.
- Added migration of legacy token and removal of legacy Gemini key.
- Disabled Android cleartext traffic globally and added deny-by-default Network Security Config.
- HTTP is disabled by default at build time and HTTP address-bar input is upgraded to HTTPS.
- Android WebView mixed content is set to `neverAllow`.
- Added WebView camera/microphone permission callback and Android runtime permission checks.
- Added geolocation permission callback with persisted host rules.
- Added persisted permission rules.
- Added tab session restore for up to 12 non-private tabs.
- Private tabs are excluded from history and session persistence.
- Private WebViews receive best-effort ephemeral settings: no DOM storage/database, no cache, no file/content access, no third-party cookies.
- Expanded conservative tracker navigation blocklist.
- Release builds now fail when signing configuration is missing; no debug-signing fallback.
- CI runs analyze + tests, requires signing secrets, builds APK/AAB, and verifies APK certificate against the release keystore.
- Removed destructive `flutter create .` behavior from platform/toolchain scripts.

## Known platform limitation
`webview_flutter` exposes navigation and permission callbacks, but not a stable Dart API for Android `WebViewClient.shouldInterceptRequest`. Therefore the current tracker blocker is navigation-level, not a complete network-resource blocker. A future dedicated WebView plugin/native fork can add full resource interception and Service Worker interception. Android supports both native callbacks; see the official Android WebView documentation.

Private browsing is hardened but is not a separate Chromium data-directory profile because Android WebView data-directory suffixes must be selected before WebView creation and the current Flutter WebView plugin owns WebView creation. Do not advertise this as forensic-grade anonymity.

## Verification required
Run locally or in GitHub Actions:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

## Native resource-level blocker (2026-08-27)

- Added `ResourceBlocker.kt` for host/path/query filtering at Android WebView resource level.
- Added `BlockingWebViewClient.kt` using `WebViewClient.shouldInterceptRequest(WebResourceRequest)`.
- Added Service Worker interception using `ServiceWorkerController` / `ServiceWorkerClient`.
- Added native navigation blocking for known tracker hosts and HTTP when cleartext is disabled.
- Added Flutter ↔ Android web-event bridge for page start/finish/error events.
- Android tabs now use the native WebViewClient so subresources can be intercepted instead of relying only on Flutter navigation callbacks.
- iOS/other native platforms retain the existing Dart navigation delegate.
- Blocked-resource requests return an empty 204 response and never leave the WebView.
- Kept the blocklist conservative for main-frame URLs to reduce accidental site breakage.

### Important platform limitation

Android documents that `shouldInterceptRequest` is not called for `javascript:`, `blob:` and some local asset URLs, and redirect interception only covers the initial resource URL. Service Worker interception is installed separately. This is therefore a WebView-level resource blocker, not a device-wide VPN/DNS blocker.

## CI/CD hardening (2026-08-27)

- GitHub Actions now validates required HTTPS repository variables before building.
- Removed `GEMINI_MODEL` from client build defines; model selection belongs to the server-side AI gateway.
- Release keystore is written under `$RUNNER_TEMP`, not the source tree.
- Added Flutter doctor and lockfile validation.
- APK/AAB builds require release signing secrets and never fall back to debug signing.
- APK signing certificate is compared with the configured release keystore.
- Signing material is deleted in an `always()` cleanup step.


## Latest CI repair
- Fixed TrackerBlocker host-specific path matching for subdomains (e.g. www.facebook.com/tr).
- Fixed native Android ResourceBlocker to recognize host-specific tracking endpoints such as facebook.com/tr on subresources.
- Existing normal facebook.com navigation remains allowed.
