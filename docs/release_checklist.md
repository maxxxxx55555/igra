# Release Checklist — The Last Streetlight

## Build Format
- [ ] AAB format required for Google Play Store
- [ ] APK for sideloading/testing only

## Target API Level
- [ ] Target SDK: 34 (Android 14)
- [ ] Compile SDK: 34
- [ ] Min SDK: 21 (Android 5.0)
- TARGET_SDK_VERIFY: Update targetSdkVersion in AndroidManifest.xml / gradle build config

## Privacy Policy
- [ ] Placeholder privacy policy text ready
- [ ] URL for in-app privacy policy link configured
- [ ] Update in Google Play Console

## Data Safety
- [ ] Fill Data Safety form in Google Play Console
- [ ] No personal data collected (offline game)
- [ ] No analytics SDKs included

## IARC Rating
- [ ] Complete IARC rating questionnaire
- [ ] Expected: 12+ (horror themes, mild violence)
- [ ] Submit via Google Play Console

## ASO (App Store Optimization)
- [ ] Icon: 512x512px PNG
- [ ] Feature Graphic: 1024x500px
- [ ] Screenshots: at least 4 (landscape, 1920x1080)
- [ ] Description: RU + EN versions
- [ ] Short description: RU + EN

## Version Naming
- [ ] versionName: "1.0.0"
- [ ] versionCode: 1 (increment per build)

## Testing Tracks
- [ ] Internal testing (up to 100 testers)
- [ ] Closed testing (up to 2000 testers)
- [ ] Production release

## Keystore
```bash
keytool -genkey -v -keystore tls_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tls_key
```
- [ ] Keystore generated and backed up
- [ ] Keystore password stored securely
- [ ] Key alias and password stored securely
