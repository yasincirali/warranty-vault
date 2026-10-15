# YAPMAN GEREKENLER — Garanti Kasası

Yalnız yasin'in yapabileceği adımlar. Sıra önemlidir.

## TestFlight'a ilk build için (hepsi gerekli)

1. **GitHub deposu**: `yasincirali/warranty-vault` (private, **boş** — README/
   .gitignore/lisans ekleme) oluştur. Claude GitHub App'e erişim ver:
   https://github.com/apps/claude/installations/select_target → `yasincirali` →
   *Only select repositories* → `warranty-vault`. Sonra Claude Projects ›
   Project settings › Resources'a ekle. Yerel depo hazır; depo açılınca push edilir.
2. **Apple Developer › Identifiers**: `com.sandik.warrantyvault` App ID
   (capability yok).
3. **App Store Connect › Apps › +**: ad **"Garanti Kasası"** (alınmışsa
   "Garanti Kasası: Fiş" gibi bir yedek). Ad **geçicidir** — marka kararı
   (Recourse/Coverline) verilince değişir; bundle id değişmez. Bundle id yukarıdaki,
   SKU `warrantyvault`, birincil dil Türkçe, kategori **Utilities** (ikincil
   Productivity). TestFlight › Test Information'ı doldur.
4. **GitHub secrets** (yeni depoya, sandık'takilerle AYNI değerler): `APPLE_ID`,
   `APPLE_TEAM_ID`, `ITC_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`,
   `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTH`, `MATCH_PASSWORD`.
5. **Actions › "iOS — Setup Match (one-time)"** çalıştır: yeni bundle id'nin profilini
   sandık'ın match deposuna yazar (sertifika ortak, yalnız profil eklenir).
6. `main`'e ilk push/birleşme → "iOS — TestFlight" build'i yükler. TestFlight'ta
   dahili gruba kendini ekle.

Supabase ilk TF build'i için **gerekmez**: uygulama yerel-öncelikli, sunucusuz çalışır.
