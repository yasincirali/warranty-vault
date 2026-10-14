# Warranty Vault

Working name for F02 · Fiş & Garanti Kasası: keep every receipt, and know on
any day which protection you still have (return window, legal right,
manufacturer or extended warranty), who has to prove the fault, and what to do
when something breaks.

- Rights engine: `lib/rights/` + `assets/rules/rules.json` (EU/DE verified; GB, TR, US unverified; AU no fixed end)
- App: Flutter + Riverpod, light/dark, English + Turkish
- Backend: Supabase (`supabase/migrations/0001_base.sql`), receipt reader edge function `supabase/functions/fis-oku`

Run on demo data (no keys needed):

```bash
flutter pub get && flutter run
```

With a backend: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

Rules for contributors (and Claude) are in `CLAUDE.md`; product docs in `docs/`.
