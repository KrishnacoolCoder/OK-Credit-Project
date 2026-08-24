# Sangam — Firebase Authentication backend (free Spark plan)

Both the owner and staff sign in with **email + password**. Staff
self-register using a one-time invite code the owner generates. Everything
runs on Firebase's free Spark plan — no Cloud Functions, no billing account,
no phone/SMS involved at all (Google requires the paid Blaze plan for real
phone-number verification, which is why this version doesn't use it).

---

## Why not phone OTP?

We tried that first. Turns out Google changed policy: real SMS verification
now requires the Blaze plan even for a single message — it's not just a
quota thing anymore. Since you'd rather not have billing enabled, owner
login now uses email + password too, exactly like staff already do.

## 1. Sign-in providers

Firebase console → **Authentication** → **Sign-in method** → make sure
**Email/Password** is enabled. (You can leave Phone enabled too, or disable
it — the app no longer uses it either way.)

## 2. Deploy the Firestore rules

```powershell
cd C:\src\flutter\sangam_pro
firebase deploy --only firestore:rules
```

## 3. Get dependencies and rebuild

```powershell
flutter clean
flutter pub get
.\build_apk.bat
```

---

## Test flow

1. **Login → Owner tab → Create new shop** → fill in shop name, owner name,
   location (optional), your email, and a password (6+ characters) →
   **Create shop & start**
2. Add a customer, transaction, product — pushes to Firestore automatically
   (check Firebase console → Firestore Database → `shops/{your-uid}/...`)
3. **Settings → Team → Invite a staff member** → name + edit access →
   **Generate code** → share the 6-character code however you like
4. On a second device (or after logging out): **Login → Staff tab → "New
   staff? Enter your invite code"** → their own name, email, password, and
   the code → **Join shop**
5. Confirm they see the same customers, transactions, and products
6. From **Settings → Team**: "Make view-only" / "Allow editing", "Send
   password reset email", "Remove staff" — all direct, rule-checked
   Firestore operations, no server needed

---

## What's true about "removing" staff

There's no Admin SDK, so "Remove staff" revokes their access to your shop
data immediately (enforced by Firestore rules), but can't delete their
underlying Firebase login. For a small shop team this is a low-risk edge
case, but worth knowing.
