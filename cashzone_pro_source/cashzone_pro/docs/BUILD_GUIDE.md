# ============================================================
#  CashZone Pro  –  Complete Build & Deploy Guide
#  APK Build Instructions + CI/CD with GitHub Actions
# ============================================================

---

## STEP 1 – Prerequisites

Install these tools on your machine:

```bash
# 1. Flutter SDK (3.19+ recommended)
# Download: https://docs.flutter.dev/get-started/install/windows

# 2. Android Studio (for SDK + emulator)
# Download: https://developer.android.com/studio

# 3. Java 17 (required by Gradle)
# Download: https://adoptium.net/

# 4. Firebase CLI
npm install -g firebase-tools

# 5. FlutterFire CLI
dart pub global activate flutterfire_cli

# Verify everything works:
flutter doctor -v
```

---

## STEP 2 – Firebase Project Setup

```bash
# Login to Firebase
firebase login

# Create a new project at https://console.firebase.google.com
# Project name: cashzone-pro

# Enable these services in Firebase Console:
#  ✅ Authentication  →  Email/Password + Google Sign-in
#  ✅ Firestore Database  →  Start in production mode
#  ✅ Cloud Messaging  →  (for push notifications)
#  ✅ Hosting  →  (for admin panel deployment)

# Connect Flutter app to Firebase
cd cashzone_pro
flutterfire configure --project=cashzone-pro
# This generates: lib/firebase_options.dart
# Select: Android + Web (for admin panel)
```

---

## STEP 3 – Google Sign-in Setup

```bash
# Get your SHA-1 fingerprint (debug)
cd android
./gradlew signingReport

# Copy the SHA-1 value and add it in:
# Firebase Console → Project Settings → Your Android App → Add fingerprint

# For release APK you'll need the release keystore SHA-1 too (see Step 6)
```

---

## STEP 4 – Ad Network Setup

### Google AdMob (Recommended for testing)
1. Create account at https://admob.google.com
2. Add App → Android → Enter package name: `com.yourname.cashzone_pro`
3. Create 3 ad units: Interstitial, Rewarded, Banner
4. Copy Ad Unit IDs into `lib/services/ad_service.dart`
5. Add App ID to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### AppLovin MAX (Higher eCPM)
```bash
# Add to pubspec.yaml:
applovin_max: ^3.2.0

# In main.dart, after Firebase init:
await AppLovinMAX.initialize("YOUR_SDK_KEY");
```

---

## STEP 5 – Configure App

### Update package name
Edit `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.yourname.cashzonepro"   // ← your unique ID
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### Update AndroidManifest.xml permissions
`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<application
    android:name="${applicationName}"
    android:label="CashZone Pro"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="false">

    <!-- AdMob App ID -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-XXXXXXXX~XXXXXXXX"/>
</application>
```

---

## STEP 6 – Create Release Keystore

```bash
# Run once – store the keystore file safely!
keytool -genkey -v \
  -keystore cashzone_release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias cashzone \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=CashZone Pro, OU=Games, O=YourCompany, L=City, S=State, C=PK"

# Move keystore to android/app/
mv cashzone_release.jks android/app/

# Create android/key.properties:
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=cashzone
storeFile=cashzone_release.jks
```

Update `android/app/build.gradle` to use keystore:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## STEP 7 – Deploy Firestore Rules

```bash
cd cashzone_pro
firebase deploy --only firestore:rules
```

---

## STEP 8 – Create Admin User

```bash
# 1. Open Firebase Console → Authentication
# 2. Add user manually:
#    Email: Ayanboy1019@gmail.com
#    Password: admin@1122
# 3. Copy the UID from Authentication tab
# 4. Open Firestore → users collection
# 5. Create document with that UID containing:
{
  "email": "Ayanboy1019@gmail.com",
  "displayName": "Admin",
  "isAdmin": true,
  "isBanned": false,
  "coins": 0,
  "totalEarned": 0,
  "dailyEarned": 0,
  "dailyLimit": 10000,
  "referralCode": "ADMIN001",
  "referralCount": 0,
  "referralEarnings": 0,
  "loginStreak": 1,
  "createdAt": "<server timestamp>"
}
```

---

## STEP 9 – Build Debug APK (for testing)

```bash
cd cashzone_pro

# Get all packages
flutter pub get

# Run on device/emulator (for testing)
flutter run

# Build debug APK
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

---

## STEP 10 – Build Release APK

```bash
# Full release APK (single universal APK)
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
# Size: ~20-35 MB typical

# Split by ABI (smaller APKs per device architecture – RECOMMENDED)
flutter build apk --split-per-abi --release
# Outputs:
#   app-arm64-v8a-release.apk   (modern phones)
#   app-armeabi-v7a-release.apk (older phones)
#   app-x86_64-release.apk      (emulators/tablets)

# App Bundle (for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## STEP 11 – Deploy Admin Panel

```bash
# Build admin panel as Flutter web
cd cashzone_pro/admin_panel

# Create separate Flutter project for admin
flutter create . --platforms=web
# Copy admin_panel/main.dart → lib/main.dart
# Copy pubspec with firebase packages

flutter pub get
flutter build web --release

# Deploy to Firebase Hosting
firebase init hosting
# Public directory: build/web
# Configure as single-page app: yes

firebase deploy --only hosting
# Admin panel live at: https://cashzone-pro.web.app
```

---

## STEP 12 – GitHub Actions CI/CD (Auto-build on push)

Create `.github/workflows/build.yml`:

```yaml
name: Build CashZone Pro APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'

      - name: Get dependencies
        run: flutter pub get

      - name: Decode Keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/cashzone_release.jks

      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.STORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=cashzone" >> android/key.properties
          echo "storeFile=cashzone_release.jks" >> android/key.properties

      - name: Create firebase_options.dart
        run: echo "${{ secrets.FIREBASE_OPTIONS }}" > lib/firebase_options.dart

      - name: Run tests
        run: flutter test

      - name: Build Release APK
        run: flutter build apk --release --split-per-abi

      - name: Upload APK artifacts
        uses: actions/upload-artifact@v4
        with:
          name: release-apks
          path: build/app/outputs/flutter-apk/*.apk

      - name: Create GitHub Release
        if: github.ref == 'refs/heads/main'
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ github.run_number }}
          name: CashZone Pro v${{ github.run_number }}
          files: build/app/outputs/flutter-apk/*.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### GitHub Secrets to configure:
Go to GitHub Repo → Settings → Secrets and add:

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | `base64 cashzone_release.jks` (run this command) |
| `STORE_PASSWORD` | Your keystore store password |
| `KEY_PASSWORD` | Your key password |
| `FIREBASE_OPTIONS` | Full contents of lib/firebase_options.dart |

---

## STEP 13 – Push Notifications Setup

```bash
# In Firebase Console → Cloud Messaging → Web Push certificates
# Generate a VAPID key pair

# In AndroidManifest.xml add:
# <service android:name=".MyFirebaseMessagingService" ...>

# Example Cloud Function to send daily reminder:
# functions/index.js:
```

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Runs every day at 10 AM PKT (5 AM UTC)
exports.dailyReminder = functions.pubsub
  .schedule("0 5 * * *")
  .timeZone("Asia/Karachi")
  .onRun(async () => {
    const message = {
      notification: {
        title: "🎁 Daily Reward Ready!",
        body: "Your daily coins and free spin are waiting. Come earn now!",
      },
      topic: "all_users",
    };
    await admin.messaging().send(message);
  });
```

---

## Quick Reference – Project File Structure

```
cashzone_pro/
├── lib/
│   ├── main.dart                    ← App entry + providers
│   ├── firebase_options.dart        ← Generated by FlutterFire CLI
│   ├── models/
│   │   ├── user_model.dart
│   │   └── withdrawal_model.dart
│   ├── services/
│   │   ├── auth_service.dart        ← Firebase Auth + Google
│   │   ├── coin_service.dart        ← Coin logic + anti-cheat
│   │   ├── ad_service.dart          ← AdMob / AppLovin
│   │   └── user_service.dart        ← Withdrawals, referrals
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── dashboard_tab.dart
│   │   ├── games/
│   │   │   ├── games_tab.dart       ← All 10 game cards
│   │   │   ├── scratch_to_win_game.dart
│   │   │   ├── spin_wheel_game.dart
│   │   │   ├── tap_tap_game.dart
│   │   │   ├── bird_shooting_game.dart
│   │   │   ├── mind_puzzle_game.dart
│   │   │   ├── lucky_number_game.dart
│   │   │   ├── card_flip_game.dart
│   │   │   ├── advanced_wheel_game.dart
│   │   │   ├── quiz_game.dart
│   │   │   └── endless_runner_game.dart
│   │   ├── earn/
│   │   │   └── earn_tab.dart        ← Watch ads, daily reward, spin
│   │   ├── wallet/
│   │   │   └── wallet_tab.dart      ← Withdrawals
│   │   └── profile/
│   │       └── profile_tab.dart
│   └── utils/
│       └── app_theme.dart           ← Full dark purple/neon theme
├── admin_panel/
│   └── main.dart                    ← Full admin web dashboard
├── firebase/
│   └── firestore.rules              ← Security rules
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   ├── cashzone_release.jks     ← Your keystore (gitignore!)
│   │   └── src/main/AndroidManifest.xml
│   └── key.properties               ← Passwords (gitignore!)
├── pubspec.yaml
└── .github/workflows/build.yml      ← CI/CD auto-build
```

---

## Important Security Notes

```
⚠️  NEVER commit these to git:
  - android/key.properties
  - android/app/*.jks
  - lib/firebase_options.dart (contains API keys)
  - google-services.json

Add to .gitignore:
  android/key.properties
  android/app/*.jks
  lib/firebase_options.dart
  *.jks
```

---

## Estimated APK Size

| Component | Size |
|-----------|------|
| Flutter framework | ~7 MB |
| Firebase SDKs | ~4 MB |
| AdMob SDK | ~3 MB |
| App code + assets | ~3 MB |
| **Total (arm64)** | **~17 MB** |

---

## After First Build Checklist

- [ ] Replace all test ad unit IDs with real AdMob IDs
- [ ] Test all 10 games on a real device
- [ ] Test withdrawal flow end-to-end
- [ ] Verify daily limit resets at midnight
- [ ] Test referral code system
- [ ] Verify admin panel can approve/reject withdrawals
- [ ] Test push notification delivery
- [ ] Enable ProGuard in release build
- [ ] Add app icon (replace assets/images/app_icon.png)
- [ ] Set up Firebase Analytics events
