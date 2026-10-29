# Publishing Charta Home on the App Store and Google Play

Everything to upload is in this folder:

| File | Where it goes |
| --- | --- |
| [listing.md](listing.md) | Store text, FR and EN |
| `screenshots/{fr,en}/ios-6.9/` | App Store, iPhone 6.9" (1320×2868), 10 each |
| `screenshots/{fr,en}/ios-6.5/` | App Store, iPhone 6.5" (1284×2778), optional |
| `screenshots/{fr,en}/android-phone/` | Google Play, phone (1080×1920) |
| `feature-graphic-{fr,en}.png` | Google Play feature graphic (1024×500) |
| `play-icon-512.png` | Google Play app icon |
| `raw/` | The plain simulator captures, if you want to redo the frames |

The screenshots come from the app's demo data on an iPhone 16 Pro Max. The legal pages live on the website and are linked
from the app (Profile, sign-up):

- Privacy policy: https://www.chartahome.com/fr/privacy (and `/en/privacy`)
- Terms of use: https://www.chartahome.com/fr/terms
- Account deletion: https://www.chartahome.com/fr/delete-account

## 0. Before the first submission

1. **Deploy the website** with the legal pages and `DELETE /api/mobile/account`.
2. **Run the migration** `supabase/migrations/20261019120000_resident_account_deletion.sql`
   on the live database (SQL editor, like the resident-app one). Without it,
   deleting an account erases the agency's gateway payment records.
3. **A review account with data.** Run
   `backend/supabase/seed/app_review_account.sql` in the SQL editor. It
   creates a separate agency "Charta Home Démo" with a leased home (three
   months paid, this month due), a repair in progress and two listed homes,
   one bookable for short stays. Then sign up in the app with
   `review@chartahome.com` and a password you choose; give that password in
   the review notes only. Unlist the demo homes once real agencies publish
   (SQL at the bottom of the file).
4. **Google and Apple sign-in.** The buttons are hidden unless
   `"SOCIAL_SIGN_IN": true` is in `env/prod.json`. Turn it on only after both
   providers work in Supabase. Apple requires Sign in with Apple whenever
   Google sign-in is offered, so both go on together.
5. **Fill in the legal entity.** The pages say "Charta Home, Conakry,
   République de Guinée". Add the registered company name, RCCM number and
   address to `lib/legal.ts` in the web repo if you have them, and have a
   lawyer read the pages once.

## 1. Version

`pubspec.yaml` → `version: 1.0.0+1`. Raise the part after `+` for every
upload (both stores refuse a build number they have already seen).

## 2. iOS (App Store Connect)

Bundle id `com.chartahome.app`, team T933A8G3N6.

```bash
flutter build ipa --release --dart-define-from-file=env/prod.json
```

Exporting the .ipa needs your Apple account in Xcode (Xcode › Settings ›
Accounts). The simplest path: open `build/ios/archive/Runner.xcarchive`
(double-click it), then in Organizer choose **Distribute App › App Store
Connect › Upload**. Xcode registers `com.chartahome.app` and creates the
signing profiles itself. Create the app in App Store Connect first (My Apps ›
+ › New App, bundle id `com.chartahome.app`, SKU `chartahome-ios`).

Already set in the project: the app icon, the display name, camera and photo
library usage texts, `ITSAppUsesNonExemptEncryption = false` (HTTPS only, so
no export compliance questions), the `chartahome://` URL scheme. The plugins
ship their own privacy manifests.

**App Privacy** (App Store Connect › App Privacy). Tracking: **No**.
Data linked to the user, none used for tracking:

| Data type | Purpose |
| --- | --- |
| Contact info › Name | App functionality |
| Contact info › Email address | App functionality |
| Contact info › Phone number | App functionality (entered by the agency) |
| Financial info › Other financial info (rent, payments, amounts) | App functionality |
| User content › Photos | App functionality (repair photos) |
| User content › Other user content (repair descriptions, messages) | App functionality |
| Identifiers › User ID | App functionality |
| Identifiers › Device ID (push token) | App functionality |

Not collected: location, contacts, browsing or search history, health,
payment card numbers (PayUnit collects them on its own page), diagnostics,
usage data, advertising data.

**Review notes** (App Review Information):

> Charta Home is the resident app of the Charta Home property management
> platform. Agencies manage homes in our web dashboard; residents use this app
> to browse published homes, book short stays, pay rent and report repairs.
> Demo account: review@chartahome.com / (password). Rent and stay payments
> are real-world services (housing), paid through PayUnit (mobile money or
> card) in an in-app browser, so they are outside In-App Purchase (guideline
> 3.1.5(a)). Account deletion: Profile › Delete my account.

Screenshots: 6.9" (1320×2868) is required; 6.5" optional. The app is set
to iPhone only (its layouts are designed for phones), so no iPad
screenshots are needed. It still runs on iPad in iPhone mode.

## 3. Android (Google Play Console)

Application id `com.chartahome.app`.

**Upload key**: already created at `~/charta-home-upload.jks`, with its
password in `android/key.properties` (git-ignored). Back both up somewhere
safe (a password manager). If they are lost, Google can reset the upload key,
but it takes days. SHA-256 of the key:
`E4:E9:D5:1E:8C:D1:B9:CE:9E:45:6B:06:D3:68:F3:AA:FB:84:31:BC:98:AC:32:58:CD:56:C4:F8:AD:E1:4E:D3`

Build the bundle and upload it to a testing track first:

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

File: `build/app/outputs/bundle/release/app-release.aab`. Enrol in Play App
Signing when asked.

**App content** answers:

- Privacy policy: the URL above.
- Ads: **No**.
- App access: **Some functionality is restricted** → give the review account.
- Content rating: questionnaire, category "Utility / productivity"; no
  violence, no user-to-user public sharing, no gambling → Everyone.
- Target audience: 18 and over.
- Financial features: none of the listed ones (no loans, no trading); payments
  for rent go through a licensed payment provider.
- Data safety:
  - Collected: Name, Email, Phone number, User IDs (Personal info);
    Other financial info (Financial info); Photos (Photos and videos); Other
    in-app messages (Messages); Device or other IDs (push token).
  - All are **collected**, **not shared** (service providers do not count as
    sharing), **encrypted in transit**, used for **App functionality** and
    **Account management**. Photos and push tokens are **optional**.
  - Users can **request deletion**: in the app, and at the delete-account URL.
- Account deletion URL: https://www.chartahome.com/fr/delete-account

Google requires a closed test with at least 12 testers for 14 days before
production for new personal developer accounts. Organisation accounts do not
have this rule.

Screenshots: phone, at least 2 (1080×1920 or larger). Feature graphic
1024×500 is required.

## 4. Screenshots to take

On the iPhone 16 Pro Max simulator (6.9") with the review account:

1. Explore (featured homes)
2. A home's page with the map and price
3. Short stay: nights and calendar
4. Review booking
5. My home overview
6. Payments (blue header) and the pay sheet with several months
7. New repair request

```bash
xcrun simctl io booted screenshot ~/Desktop/charta-1.png
```

## 5. After release

- Push notifications from the server need Firebase (see `backend/README.md`, step 5).
- Update `lib/legal.ts` (web) whenever the app collects something new, and
  the App Privacy / Data safety answers with it.
