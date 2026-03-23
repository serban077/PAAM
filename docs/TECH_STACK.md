# Tech Stack

> Read this when: adding a new dependency, debugging a package issue, or onboarding.

---

## Core Dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK ^3.9.0 | UI framework |
| `supabase_flutter` | 2.9.1 | Backend-as-a-Service: PostgreSQL DB, auth, realtime |
| `sizer` | 2.0.15 | Responsive sizing — `%.h`, `%.w`, `%.sp` |
| `dio` | 5.4.0 | HTTP client for Gemini API calls |
| `google_fonts` | 6.1.0 | Typography — no local font files needed |
| `fl_chart` | 0.65.0 | Charts for progress tracking screens |
| `mobile_scanner` | 7.1.4 | Barcode / QR scanning (food barcode lookup — M6) |
| `youtube_player_flutter` | — | Exercise demo videos in ExerciseDetailsScreen (M5) |
| `camera` | — | Photo capture for progress photos |
| `image_picker` | — | Photo library access |
| `cached_network_image` | — | Wrapped by `CustomImageWidget` |
| `connectivity_plus` | — | Network state detection |
| `intl` | — | Date formatting, locale |
| `url_launcher` | — | Open external links |
| `fluttertoast` | — | Toast notifications |
| `before_after` | — | Before/after photo comparison widget (M7) |
| `flutter_svg` | 2.0.9 | SVG asset rendering |
| `permission_handler` | 11.1.0 | Runtime permissions (camera, storage) |

---

## Infrastructure

| Layer | Technology | Notes |
|---|---|---|
| Backend | Supabase (PostgreSQL 15) | Hosted — no self-managed DB |
| Auth | Supabase Auth (email/password) | JWT sessions |
| AI | Google Gemini API | Called via Dio, key in env.json |
| Payments | Stripe | Key configured in env.json — not yet wired to UI |

---

## Dev Dependencies

| Package | Purpose |
|---|---|
| `flutter_test` | Unit + widget testing (tests not yet written — M11) |
| `flutter_lints` | Enforces `analysis_options.yaml` rules |

---

## Platform Targets

| Platform | Status |
|---|---|
| Android | Primary target — APK tested |
| iOS | Configured — not device-tested yet |
| Web | Configured in project — not a focus |

Orientation: **portrait-only** (enforced in `main.dart` via `SystemChrome.setPreferredOrientations`).

---

## Why Sizer over MediaQuery

Sizer (`%.h`, `%.w`, `%.sp`) is used throughout instead of `MediaQuery.of(context).size`.
Switching to MediaQuery for individual values would break the responsive contract.
NEVER mix Sizer and fixed-px values in the same widget tree.

---

## Why No State Management Library

The app uses vanilla `StatefulWidget` + `setState`. This was an intentional choice for simplicity
at university project scale. Do not introduce Provider / Riverpod / Bloc without explicit agreement —
it would require migrating all existing screens.
