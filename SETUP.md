# Recipe Quest — Setup Guide

## Prerequisites

- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Xcode (for iOS) / Android Studio (for Android)
- A [Supabase](https://supabase.com) account
- An [AdMob](https://admob.google.com) account

---

## 1. Supabase

### 1a. Create a project

1. Go to [supabase.com](https://supabase.com) → New Project
2. Name it **Recipe Quest**
3. Choose a region close to your users (e.g. `ap-northeast-1` for Asia)
4. Copy your **Project URL** and **anon public key**

### 1b. Configure credentials

Open `lib/core/constants/supabase_config.dart` and fill in:

```dart
static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
static const String anonKey = 'YOUR_ANON_KEY';
```

### 1c. Create tables

Run the following SQL in the Supabase SQL editor:

```sql
-- User profiles (extra data beyond Supabase Auth)
CREATE TABLE public.user_profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name         TEXT,
  phone        TEXT,
  country_code TEXT DEFAULT '+1',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- User favourites
CREATE TABLE public.user_favorites (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dish_id         INTEGER NOT NULL,
  dish_name       TEXT,
  thumbnail_url   TEXT,
  cuisine_name    TEXT,
  short_description TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, dish_id)
);

ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own favourites"
  ON public.user_favorites FOR ALL
  USING (auth.uid() = user_id);
```

### 1d. Create the auto-profile trigger

This trigger creates a `user_profiles` row automatically on signup (bypasses RLS):

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, name, phone, country_code)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', ''),
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    COALESCE(new.raw_user_meta_data->>'country_code', '+1')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 1e. Disable email confirmation (development)

Dashboard → **Authentication → Sign In / Providers → Email** → toggle **Confirm email** OFF.

For production, configure a custom SMTP provider under **Authentication → Settings → SMTP**.

---

## 2. AdMob

1. Create an app at [admob.google.com](https://admob.google.com)
2. Create ad units: **Banner** and **Rewarded**
3. Replace the test IDs in `lib/data/services/ad_service.dart` with your real ad unit IDs

### Android — `android/app/src/main/AndroidManifest.xml`

Inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

---

## 3. In-App Purchases

Create these products in both **Google Play Console** (Monetize → In-app products) and **App Store Connect** (Features → In-App Purchases):

| Product ID | Type | Price |
|---|---|---|
| `dish_unlock` | Consumable | $0.99 |
| `cuisine_unlock` | Consumable | $9.99 |

> IAP can only be tested on physical devices with a signed build. Use sandbox testers for both platforms.

---

## 4. App Drawer — Replace Placeholder URLs

Open `lib/presentation/views/home/widgets/app_drawer.dart` and update:

```dart
static const _privacyUrl    = 'https://yourwebsite.com/privacy'; // hosted privacy_policy.html
static const _supportEmail  = 'support@yourapp.com';
static const _appStoreUrl   = 'https://apps.apple.com/app/your-app-id';
static const _playStoreUrl  = 'https://play.google.com/store/apps/details?id=com.your.package';
```

---

## 5. Run the App

```bash
flutter pub get
flutter run
```

For a release build:

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

---

## 6. Seed the Local SQLite Database

The app ships with a pre-populated SQLite database in `assets/`. To update it, modify `lib/data/database/app_database.dart` and bump the schema version to trigger a migration on next launch.

---

## Recommended Build Order for New Features

1. ✅ Supabase backend + tables
2. ✅ SQLite local database + seed data
3. ✅ Auth (register / login / logout)
4. ✅ Browse cuisines & dishes
5. ✅ YouTube video player (10 languages)
6. ✅ AdMob banner + rewarded ads
7. ✅ In-app purchase flow (dish + cuisine unlock)
8. ✅ Favourites sync (local + Supabase)
9. ✅ Side drawer (profile, subscription, privacy, about, help, rate)
10. ⬜ Push notifications (daily recipe suggestion)
11. ⬜ Localisation / RTL layout for Arabic
12. ⬜ Server-side IAP receipt verification
