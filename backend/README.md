# Connecting the app to the Charta Home backend

The resident app uses **the same backend as the web dashboard**: the same
Supabase project (auth, database, storage), the same Next.js app on Vercel
(PayUnit, Resend, signed photo links), and the same rules. Nothing an agency
does in the dashboard changes.

This folder holds what the web project needs. Each file sits at the path it
goes to in the web repo (`~/Charta Home`).

| File | What it does |
| --- | --- |
| `supabase/migrations/20260808123000_resident_app.sql` | Lets a resident see only their own lease, rent, payments, repairs and stays (row level security). Adds published listings, holding a short stay (same clash lock as `create_stay`), package pricing (`stay_quote`), app repair tickets, rental requests, `resident_payments` with an idempotent settlement, and device tokens. |
| `scripts/verify-resident-app.mjs` | Applies every migration in PGlite and tests the new functions: 16 checks covering prices, holds, clashes, profile claiming, tickets and settlement. |
| `web/lib/mobile.ts` | Checks the app's Supabase token and builds listing JSON with signed photo URLs. |
| `web/lib/resident-payments.ts`, `web/lib/resident-emails.ts` | Settles app payments after asking PayUnit, then emails the receipt through Resend. |
| `web/app/api/mobile/listings` | `GET`: published homes, public. |
| `web/app/api/mobile/me` | `GET`: the signed-in resident's home, rent, payments, repairs and stays. |
| `web/app/api/mobile/payments` | `POST`: opens a PayUnit checkout for rent or a stay. The amount is computed on the server. |
| `web/app/api/mobile/payments/[ref]` | `GET`: the app polls this. It asks PayUnit and settles the payment. |
| `web/app/api/mobile/pay-return` | PayUnit's https return address, which bounces to `chartahome://payment-return`. |
| `web/app/api/payunit/notify/route.ts` | Replaces the existing notify route so it settles app payments as well as subscriptions. |

## 1. Database

```bash
cp backend/supabase/migrations/20260808123000_resident_app.sql "../Charta Home/supabase/migrations/"
cp backend/scripts/verify-resident-app.mjs "../Charta Home/scripts/"
cd "../Charta Home"
node scripts/verify-resident-app.mjs   # all 16 checks should pass
npm run db:check                       # the project's own checks
supabase db push                       # or apply bundle.sql as usual
```

Agencies publish a home by setting `apartments.listed = true`. For short
stays they also need `short_stay = true` and at least one row in `stay_rates`.
Fill `buildings.latitude/longitude` and `neighborhood` so the map shows. The
dashboard does not have a toggle for these yet; until it does, set them with
SQL or the Supabase table editor.

## 2. Web routes

```bash
cp -R backend/web/lib/* "../Charta Home/lib/"
cp -R backend/web/app/* "../Charta Home/app/"
```

No new environment variables. These routes use what the web app already has:
`NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PAYUNIT_*`,
`RESEND_API_KEY`, `EMAIL_FROM` and `NEXT_PUBLIC_SITE_URL`. The routes use an
untyped admin client (`mobileDb()`), because `lib/supabase/types.ts` is
written by hand. Once you regenerate the types after the migration, switch
them to `createAdminClient()`.

## 3. Supabase settings (dashboard)

- **Authentication › URL Configuration › Redirect URLs:** add
  `chartahome://**`. Social sign-in and email confirmation return to the app
  through it.
- **Authentication › Emails › SMTP:** send auth emails through Resend:
  host `smtp.resend.com`, port `465`, user `resend`, password your
  `RESEND_API_KEY`, sender your `EMAIL_FROM`. Without this, Supabase's shared
  sender is rate limited to a few emails an hour.
- **Authentication › Emails › Templates › Reset password:** the app asks for
  a 6-digit code, so the template must show `{{ .Token }}`, for example
  "Your Charta Home code: {{ .Token }}". Set **Email OTP length** to 6.
- **Authentication › Providers:** turn on Google and Apple to make the
  buttons work. Google needs a Web client ID (plus an iOS client ID for iOS).
  Apple needs a Services ID and key. For both, the callback is Supabase's own
  `/auth/v1/callback`.

## 4. The app

```bash
cp env/example.json env/prod.json   # fill in the three values
flutter run --dart-define-from-file=env/prod.json
flutter build ipa --dart-define-from-file=env/prod.json
flutter build appbundle --dart-define-from-file=env/prod.json
```

With no env file, the app runs on demo data, so it can always be tried.
`API_BASE_URL` is the web app's address, for example `https://chartahome.com`.
Every call that needs a secret (PayUnit, Resend, the service role) goes
there. The app only ever holds the public anon key.

## 5. Push notifications (next step)

The app already asks permission after onboarding and saves the device in
`resident_devices`. Remote push (rent reminders, ticket updates) also needs
Firebase Cloud Messaging:

1. Create a Firebase project. Add the iOS and Android apps
   (`com.chartahome.app`) and drop in `GoogleService-Info.plist` and
   `google-services.json`.
2. Add `firebase_core` and `firebase_messaging`. After sign-in, pass
   `FirebaseMessaging.instance.getToken()` to `AppState.registerPushToken`.
3. On the server, send to the tokens in `resident_devices`, for example from
   the existing `/api/cron/reminders` job, alongside the WhatsApp and email
   reminders.

## How a payment flows

1. The app calls `POST /api/mobile/payments`. The server checks the charges
   or the stay belong to this user, computes the amount, writes a
   `resident_payments` row and opens a PayUnit transaction.
2. The app opens PayUnit's page in an in-app browser. The resident picks MTN
   MoMo, Orange Money or a card there and approves the payment.
3. The app polls `GET /api/mobile/payments/{ref}`, and PayUnit calls
   `/api/payunit/notify`. Each one only prompts the server to ask PayUnit for
   the status. `settle_resident_payment` records the outcome once: a
   `payments` row allocated oldest charge first (creating any months paid
   ahead), or `stays.paid`. The receipt goes out through Resend.
4. The dashboard sees the payment like any other.

A short stay is held for 15 minutes while it is paid, extended to 20 minutes
once checkout opens. A hold that lapses unpaid is cancelled the next time
anyone books that unit, so it never blocks the calendar.
