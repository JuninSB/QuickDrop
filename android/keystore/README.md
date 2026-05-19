# Release signing

Do not commit real keystores.

For local signed release builds:

```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias quickdrop

cp android/key.properties.example android/key.properties
```

Then edit `android/key.properties` with the real passwords.

For GitHub Actions signing, create repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
