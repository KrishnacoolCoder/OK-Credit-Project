<div align="center">

# Sangam
### सबका एक हिसाब — *One ledger for everyone*

**A full-stack, unified kirana (shop) ledger app.**
An OkCredit-style credit/khata tracker built with Flutter and Firebase —
track customer dues, capture UPI payments automatically, bill customers,
manage stock, and run an entire shop's accounting from one app.

![Flutter](https://img.shields.io/badge/Flutter-3.3%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-3DDC84?logo=android&logoColor=white)
![State management](https://img.shields.io/badge/State-Riverpod-1B1B1B)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen)

</div>

---

## Table of contents

- [About](#about)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Packages & dependencies](#packages--dependencies)
- [Cloud Functions](#cloud-functions)
- [Getting started](#getting-started)
- [Enabling automatic UPI capture](#enabling-automatic-upi-capture)
- [Building for release](#building-for-release)
- [Data model](#data-model)
- [Privacy](#privacy)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## About

Millions of small shop owners in India still track customer credit
("*udhaar*") in a paper notebook — the *khata*. **Sangam** digitizes that
notebook: a fast, offline-friendly Flutter app backed by Firebase, purpose
built for a single shop owner and their staff to record transactions,
reconcile UPI payments without manual entry, and keep the whole team on the
same ledger in real time.

It's designed around three ideas:

- **Speed over ceremony.** Adding a transaction should take seconds, not
  navigating five screens.
- **Payments should reconcile themselves.** UPI notification capture reads
  incoming GPay/PhonePe/Paytm payment alerts and queues them for one-tap
  confirmation instead of manual re-entry.
- **A shop is a team, not one person.** Owners and staff share one ledger
  with granular, rule-enforced permissions — no separate backend needed.

## Features

| | |
|---|---|
| 📒 **Customer ledger** | Add customers, log transactions, and see a running balance of who owes what. |
| ⚡ **Automatic UPI capture** | An Android notification-listener service detects GPay / PhonePe / Paytm payment alerts and queues them for review — nothing posts to a customer's account without your confirmation. |
| 🧾 **Billing** | Build itemized bills from a product/template list, add charges, and share them directly with a customer. |
| 📦 **Stock tracking** | Keep shop inventory in sync with what's sold. |
| 👥 **Multi-user shops** | One owner account plus staff accounts, onboarded with a self-serve invite code — no server setup required. |
| 🔐 **Granular staff permissions** | Owners can flip a staff member to view-only, restore edit access, trigger a password reset, or remove them — all enforced by Firestore security rules. |
| 📊 **Reports & dashboard** | Chart-driven overview of shop performance at a glance. |
| ⏰ **Auto payment reminders** | Nudges for outstanding dues. |
| 🔒 **Biometric app lock** | Keep the ledger private on a shared device. |
| 🌐 **English / Hindi toggle** | Full bilingual UI. |
| ☁️ **Cloud sync** | Firestore keeps every device current; secure local storage keeps the app usable offline. |

## Screenshots

> _Add screenshots or a short demo GIF here — drop images into `assets/images/`
> or a `docs/` folder and reference them below, e.g._
>
> ```md
> <p align="center">
>   <img src="docs/screenshot_dashboard.png" width="220" />
>   <img src="docs/screenshot_bill.png" width="220" />
>   <img src="docs/screenshot_ledger.png" width="220" />
> </p>
> ```

## Tech stack

| Layer | Technology |
|---|---|
| App framework | [Flutter](https://flutter.dev) (Dart ≥ 3.3) |
| State management | [Riverpod](https://riverpod.dev) (`flutter_riverpod`) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| Auth | Firebase Authentication (email/password — owner sign-in and self-serve staff onboarding via invite code) |
| Database | Cloud Firestore, secured by rule-based access control (`firestore.rules`) |
| Serverless backend | Firebase Cloud Functions (Node.js) for staff account lifecycle operations |
| Native Android | Kotlin `NotificationListenerService` + Flutter `EventChannel` for real-time UPI payment capture |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Local persistence | `flutter_secure_storage`, `shared_preferences` |

## Architecture

The `lib/` folder follows a **Clean Architecture**-influenced layering:

- **`domain/`** — framework-agnostic business logic: `entities/` (the core
  models of the app) and `usecases/` (single-purpose operations on those
  entities).
- **`models/`** — data-layer models used to talk to Firestore/local storage.
- **`services/`** — integrations with the outside world: auth, cloud sync,
  SMS/notification reading, UPI payment capture.
- **`presentation/`** — everything UI: `screens/` (one folder per feature —
  dashboard, billing, customers, staff, stock, reports, settings, and more),
  `providers/` (Riverpod state), and `widgets/` (shared UI components).
- **`core/`** — cross-cutting concerns shared across the app.

This keeps business rules independent of Flutter widgets and Firebase SDKs,
so either can be swapped or tested in isolation.

## Project structure

```
sangam_okcredit/
├── android/                  # Native Android project
│   └── app/src/main/kotlin/…/UpiNotificationListenerService.kt
├── functions/                 # Firebase Cloud Functions (Node.js)
│   └── index.js
├── assets/                   # Images, icons, onboarding illustrations
├── web/                       # Flutter web target
├── test/                     # Widget tests
├── tool/                      # Icon/mipmap generation scripts
├── lib/
│   ├── core/
│   ├── domain/
│   │   ├── entities/
│   │   └── usecases/
│   ├── models/
│   ├── services/              # auth, cloud sync, notifications, UPI capture
│   ├── providers/
│   ├── presentation/
│   │   ├── providers/
│   │   ├── widgets/
│   │   └── screens/
│   │       ├── splash/  onboarding/  auth/  store_setup/  store_details/
│   │       ├── dashboard/  customers/  add_transaction/  bill/  stock/
│   │       ├── report/  sms_queue/  paste_sms/  notifications/
│   │       ├── auto_reminder/  staff/  multi_device/  account/
│   │       ├── profile/  settings/  help/
│   └── widgets/
├── firestore.rules
├── firebase.json
├── .firebaserc
├── pubspec.yaml
├── build_apk.sh / build_apk.bat
└── PRIVACY_POLICY.md
```

## Packages & dependencies

<details>
<summary><strong>Click to expand the full dependency list</strong> (from <code>pubspec.yaml</code>)</summary>

| Category | Packages |
|---|---|
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Local storage | `shared_preferences`, `flutter_secure_storage` |
| Auth & security | `local_auth` (biometrics), `pin_code_fields`, `crypto` (legacy password hashing, kept for migration), `google_sign_in` |
| SMS / notifications | `another_telephony` (legacy SMS auto-read), `flutter_local_notifications` |
| Charts | `fl_chart` |
| Animations | `flutter_animate`, `lottie`, `animated_text_kit`, `shimmer`, `confetti` |
| UI | `google_fonts`, `cached_network_image`, `flutter_svg`, `cupertino_icons` |
| Sensors | `sensors_plus` |
| Permissions | `permission_handler` |
| Networking | `http` |
| Utilities | `intl`, `url_launcher`, `share_plus`, `uuid`, `timeago`, `collection` |
| Dev tools | `flutter_test`, `flutter_lints`, `flutter_launcher_icons` |

</details>

## Cloud Functions

Deployed from `functions/index.js`, these callable functions handle staff
account lifecycle operations that need to run with elevated (admin)
privileges rather than directly from the client:

| Function | Purpose |
|---|---|
| `claimShop` | Lets an owner claim/initialize their shop record. |
| `createStaffAccount` | Creates a new staff login from an invite code. |
| `updateStaffAccess` | Toggles a staff member between view-only and edit access. |
| `removeStaffAccount` | Revokes a staff member's access to shop data. |
| `resetStaffPassword` | Sends a password-reset flow for a staff account. |

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.3.0
- A [Firebase](https://console.firebase.google.com/) project with
  **Authentication → Email/Password** and **Firestore** enabled
- Android Studio (Android build) and/or Xcode (iOS build)

### 1. Clone

```bash
git clone https://github.com/Dipanshur19/sangam_okcredit.git
cd sangam_okcredit
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. Download your project's `google-services.json` from the Firebase console
   and place it at `android/app/google-services.json`.
   *This file is intentionally listed in `.gitignore` — never commit it.*
2. Update `.firebaserc` with your own Firebase project ID.
3. Deploy the Firestore security rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

4. *(Optional)* Deploy the Cloud Functions used for staff management:

   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

### 4. Run

```bash
flutter run
```

## Enabling automatic UPI capture

After installing the app, go to **Settings → Notification Access** and
enable Sangam. This allows the app to read incoming UPI payment
notifications (GPay, PhonePe, Paytm) and add them to a review queue — you
choose which customer each payment belongs to before anything is recorded.

## Building for release

```bash
./build_apk.sh      # macOS/Linux
build_apk.bat         # Windows
```

Both scripts pass the Firebase Android client configuration via
`--dart-define` at build time, so the app only initializes Firebase when
those values are supplied.

## Data model

Shop data lives in Firestore under a per-shop namespace, roughly:

```
shops/{shopId}/
├── customers/{customerId}
├── transactions/{transactionId}
├── products/{productId}
└── staff/{staffId}
```

Access is enforced by `firestore.rules` — an owner has full read/write
access to their shop's subtree, and staff access is scoped by the
permission level (`view` / `edit`) set on their staff record.

## Privacy

See [`PRIVACY_POLICY.md`](./PRIVACY_POLICY.md) for details on what data the
app reads (notification content for UPI capture, contact/customer data you
enter) and how it's stored and used.

## Roadmap

- [ ] iOS build support
- [ ] Export ledger to PDF/Excel
- [ ] WhatsApp payment reminders
- [ ] Multi-shop support for a single owner account

## Contributing

Issues and pull requests are welcome. If you're planning a larger change,
please open an issue first to discuss what you'd like to change.

```bash
# fork, then:
git checkout -b feature/your-feature-name
git commit -m "Add: your feature"
git push origin feature/your-feature-name
# open a pull request
```

## License

No license has been added yet. Add one (MIT, Apache-2.0, GPL-3.0, etc.)
before accepting outside contributions or distributing the app publicly —
without a license, default copyright law applies and others technically
can't legally use, modify, or redistribute the code.

---

<div align="center">

Built by [Dipanshu Raj](https://github.com/Dipanshur19), [Ayush Badgujar](https://github.com/DrWrytaker)

</div>
