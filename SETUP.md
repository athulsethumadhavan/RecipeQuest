# Recipe Quest — Setup Guide

## 1. Firebase Project

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In the project root, connect to your Firebase project
flutterfire configure
```

This generates `lib/firebase_options.dart`. Then uncomment the two lines in `main.dart`:
```dart
// import 'firebase_options.dart';
// options: DefaultFirebaseOptions.currentPlatform,
```

Enable in Firebase Console:
- **Firestore Database** (start in test mode, add rules before release)
- **Authentication** → Anonymous sign-in (needed for entitlement syncing later)
- **Analytics**

## 2. Seed the Database

```bash
cd scripts
npm install firebase-admin
# Download service account key from Firebase Console → Project Settings → Service Accounts
node seed_firestore.js ./serviceAccountKey.json
```

## 3. AdMob

1. Create an AdMob account at admob.google.com
2. Create an Android + iOS app
3. Create three ad units: Banner, Interstitial, Rewarded
4. Replace test IDs in `lib/core/constants/app_constants.dart`
5. Add your AdMob App IDs to `AndroidManifest.xml` and `Info.plist`:

**android/app/src/main/AndroidManifest.xml** (inside `<application>`):
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

**ios/Runner/Info.plist**:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

## 4. In-App Purchases

### Google Play
1. Upload a signed APK/AAB to Play Console
2. Create products under **Monetize → In-app products**:
   - `unlock_chinese_cuisine` — Non-consumable
   - `unlock_continental_cuisine` — Non-consumable
   - `unlock_arabic_cuisine` — Non-consumable
   - `unlock_mexican_cuisine` — Non-consumable
   - `unlock_japanese_cuisine` — Non-consumable
   - `unlock_italian_cuisine` — Non-consumable
   - `unlock_thai_cuisine` — Non-consumable
   - `unlock_all_cuisines` — Non-consumable (bundle price)

### App Store Connect
Create matching products under **Features → In-App Purchases**.

## 5. Run the App

```bash
flutter pub get
flutter run
```

## 6. Firestore Security Rules (before production)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /cuisines/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /recipes/{doc} {
      allow read: if true;
      allow write: if false;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Recommended Build Order

1. ✅ Firebase + seed data
2. ✅ Recipe list/detail UI  
3. ✅ YouTube player
4. ✅ AdMob banners
5. ✅ In-app purchase flow
6. ⬜ Server-side receipt verification (Cloud Function)
7. ⬜ Push notifications (Firebase Messaging) — daily recipe
8. ⬜ Localization / RTL for Arabic
