# 🍽️ Recipe Quest

A Flutter recipe discovery app that lets users explore global cuisines, watch cooking videos, unlock dishes via in-app purchase, and save their favourites — with a full Supabase-powered auth and sync backend.

---

## Features

- **Browse cuisines & dishes** — curated content stored in a local SQLite database (no internet required to browse)
- **Video guides** — embedded YouTube player with 10-language support (EN, HI, TA, ML, AR, DE, FR, ES, IT, ZH)
- **In-app purchases** — unlock individual dishes ($1) or entire cuisines ($10) via Google Play / App Store
- **Rewarded ads** — watch an ad to preview a locked video for free
- **Auth system** — register/login with email & password (bcrypt via Supabase Auth), phone + country picker, password strength indicator
- **Favourites sync** — saved locally (SharedPreferences) when logged out; synced to Supabase when logged in; merged on login
- **Side drawer** — Profile, Subscription info, Privacy Policy, About, Help & Support, Rate the App, Logout
- **Persistent banner ad** — shown on all main screens via a `ShellRoute` wrapper
- **Admin screen** — hidden behind a triple-tap on the title (for internal use)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart ≥3.0) |
| State management | `provider` ^6.1.2 — MVVM with `ChangeNotifier` |
| Navigation | `go_router` ^13.2.1 — `ShellRoute` for persistent ad banner |
| Local database | `sqflite` ^2.3.3 — SQLite v7 schema |
| Remote backend | `supabase_flutter` ^2.5.6 — Auth, Postgres, RLS |
| In-app purchases | `in_app_purchase` ^3.2.0 |
| Ads | `google_mobile_ads` ^5.1.0 |
| Video player | `youtube_player_flutter` ^9.1.1 |
| Image caching | `cached_network_image` ^3.3.1 |
| Local storage | `shared_preferences` ^2.2.3 |
| URL handling | `url_launcher` ^6.2.6 |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/        # AppColors, AppStrings, SupabaseConfig
│   ├── router/           # AppRouter (go_router config + ShellRoute)
│   ├── theme/            # AppTheme
│   └── widgets/          # BannerAdWidget
├── data/
│   ├── database/         # AppDatabase (SQLite schema & queries)
│   ├── models/           # Cuisine, Dish, DishDetail models
│   ├── repositories/     # CuisineRepository, FavoritesRepository, PreferenceRepository
│   └── services/         # AuthService, AdService, PaymentService, SyncService
└── presentation/
    ├── viewmodels/        # HomeViewModel, DetailViewModel, etc.
    └── views/
        ├── auth/          # AuthBottomSheet (login + register)
        ├── home/          # HomeScreen + widgets (AppDrawer, RecipeCard, …)
        ├── cuisine/       # CuisineListScreen, CuisineMealsScreen
        ├── detail/        # DetailScreen
        ├── favorites/     # FavoritesScreen
        ├── video/         # VideoPlayerScreen
        ├── search/        # SearchScreen
        ├── onboarding/    # CuisinePreferenceScreen
        ├── admin/         # AdminScreen
        └── splash/        # SplashScreen
```

---

## Supabase Schema

### `user_profiles`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | References `auth.users` |
| `name` | TEXT | |
| `phone` | TEXT | |
| `country_code` | TEXT | Default `'+1'` |
| `created_at` | TIMESTAMPTZ | |

### `user_favorites`
| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT IDENTITY PK | |
| `user_id` | UUID | References `auth.users` |
| `dish_id` | INTEGER | References `dishes` |
| `dish_name` | TEXT | |
| `thumbnail_url` | TEXT | |
| `cuisine_name` | TEXT | |
| `created_at` | TIMESTAMPTZ | |
| _(unique)_ | | `(user_id, dish_id)` |

RLS is enabled on both tables. A `SECURITY DEFINER` trigger (`on_auth_user_created`) automatically creates the `user_profiles` row on signup, reading from Supabase Auth user metadata — no client-side insert needed.

---

## Password Policy

Passwords must contain at least 8 characters including:
- One uppercase letter (A–Z)
- One lowercase letter (a–z)
- One digit (0–9)
- One symbol from `@$!%*?&#^()-_+=<>`

Hashing is handled server-side by Supabase Auth (bcrypt). Passwords are never stored in the app or database.

---

## IAP Product IDs

| Product | ID | Price |
|---|---|---|
| Dish unlock | `dish_unlock` | $1 (consumable) |
| Cuisine unlock | `cuisine_unlock` | $10 (consumable) |

Create these products in Google Play Console and App Store Connect before release.

---

## Privacy Policy

The privacy policy is located at [`privacy_policy.html`](https://athulsethumadhavan.github.io/RecipeQuest/privacy_policy.html) in the project root.

> **Before release:** host this file (e.g. on GitHub Pages or your website) and update `_privacyUrl` in `lib/presentation/views/home/widgets/app_drawer.dart` with the public URL.

---

## Getting Started

See [SETUP.md](./SETUP.md) for full setup instructions.

```bash
flutter pub get
flutter run
```

---

## Before Release Checklist

- [ ] Replace test AdMob IDs with real ones (`lib/data/services/ad_service.dart` + `AndroidManifest.xml` + `Info.plist`)
- [ ] Create `dish_unlock` and `cuisine_unlock` IAP products in Play Console and App Store Connect
- [ ] Disable Supabase email confirmation for development; configure custom SMTP for production
- [ ] Update placeholder URLs in `lib/presentation/views/home/widgets/app_drawer.dart` (`_privacyUrl`, `_supportEmail`, `_appStoreUrl`, `_playStoreUrl`)
- [ ] Host `privacy_policy.html` and update the URL in the drawer
- [ ] Enable Supabase RLS policies and review before going live
- [ ] Set `flutter run --release` and test IAP on physical devices

---

## License

Private — all rights reserved.
