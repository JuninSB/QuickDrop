# QuickDrop

Private Android + Flutter video downloader with native overlay, clipboard detection, foreground downloads, and `yt-dlp` integration.

## Important runtime note

Place an Android-compatible executable `yt-dlp` binary at:

```text
assets/bin/yt-dlp
```

The app extracts it to internal app storage on first download and runs it from a foreground service. A plain desktop Linux `yt-dlp` binary will not run on Android; use a Python-for-Android build, a bundled Android Python runtime, or a native-packaged `yt-dlp` executable suitable for the target ABI.

## Debug build

```bash
flutter pub get
flutter build apk --debug
```

Install:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Release build

```bash
flutter pub get
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions cloud build

This is the recommended path for Termux/proot ARM64 devices. Push this project to GitHub and open:

```text
Actions -> Android Build -> Run workflow
```

The workflow installs Java 17, installs Flutter stable, caches Gradle/Flutter dependencies, runs analysis, builds an Android 13+ compatible ARM64 release APK, and uploads the APK artifact.

Artifact name:

```text
quickdrop-arm64-release-apk
```

APK inside the artifact:

```text
QuickDrop-arm64-release.apk
```

## Optional release signing

Local release builds fall back to debug signing when no release keystore is configured, so you still get an installable APK.

For real release signing, create:

```text
android/key.properties
android/app/upload-keystore.jks
```

Use `android/key.properties.example` as the template.

For GitHub Actions signed builds, add these repository secrets:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

Create `ANDROID_KEYSTORE_BASE64` with:

```bash
base64 -w 0 android/app/upload-keystore.jks
```

## Overlay test

1. Install and open QuickDrop.
2. Grant notification permission when prompted.
3. Tap `Enable overlay` and allow "Display over other apps".
4. Copy a supported URL from Instagram, TikTok, YouTube, X/Twitter, or Facebook.
5. The QuickDrop bubble appears. Drag it, tap it, then press download in the popup.

## Device install

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.quickdrop.app/.MainActivity
```
