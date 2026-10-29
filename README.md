# Charta Home — mobile

The resident app for Charta Home. Tenants find and rent an apartment, pay rent
by MTN MoMo, Orange Money or card, and report and follow repairs. Flutter,
iOS and Android, French and English.

```bash
flutter pub get
flutter run                              # onboarding → email/password sign-in (demo account in lib/data/mock_data.dart)
flutter run --dart-define=SKIP_AUTH=true # straight into the app
flutter test
```

## Screens

| Tab | What the resident does |
| --- | --- |
| Explore | Search and filter verified listings, open a property, book a visit (calendar + time slot), apply to rent in three steps |
| My home | Rent due card with one-tap pay, quick actions, lease progress, open repairs, visits, applications, building notices |
| Payments | Balance, upcoming charges, pay sheet (choose months → MoMo / OM / card → approve on phone → receipt), history with receipts |
| Repairs | One-tap categories, new request (what / where / photos / urgency), ticket timeline, technician, chat, rating |
| Profile | Saved homes, visits, notifications, language toggle, sign out |

## Layout

```
lib/
  theme/app_theme.dart     brand tokens from the SaaS globals.css (azure #003152, soft #addfe1, white)
  l10n/strings.dart        fr / en strings (fr is the default, as in the SaaS)
  data/models.dart         tenant-side view of the Supabase schema
  data/mock_data.dart      demo content
  state/app_state.dart     every read and mutation the UI makes
  widgets/                 logo, buttons, cards, calendar
  screens/                 one folder per tab, plus auth
```

## Backend

The app uses the same backend as the web dashboard: the Supabase project, plus
the web app's `/api/mobile` routes for PayUnit, Resend and signed photo links.

```bash
flutter run --dart-define-from-file=env/prod.json   # real backend (see env/example.json)
```

Everything the app asks of the server goes through `lib/backend/` (`ChartaBackend`).
`SupabaseBackend` is the real one, and `MockBackend` serves the demo when no env
file is given. The migration, web routes and setup steps are in
[backend/README.md](backend/README.md).

## Publishing

See [store/README.md](store/README.md) for the App Store and Google Play steps
(signing, privacy questionnaires, review account) and
[store/listing.md](store/listing.md) for the listing text in French and
English. The privacy policy, terms and account deletion pages are on
chartahome.com (`/privacy`, `/terms`, `/delete-account`).
