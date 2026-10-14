# Claude Development Guidelines — Warranty Vault (F02 · Fiş & Garanti Kasası)

## Proje

Global fiş/fatura ve garanti kasası. Fark yaratan parça **hak motoru**: alış
tarihi + ülke + kanal → bugün hangi korumaların sürdüğü (iade, yasal hak,
üretici garantisi, uzatılmış garanti), ispat yükünün kimde olduğu ve "bir sorun
var" dendiğinde tek önerilen yol.

Flutter + **Riverpod 3**; **Supabase** (Postgres + RLS, Edge Functions);
AI fiş okuma `supabase/functions/fis-oku` (Claude). sandık'tan **tamamen ayrı**:
ayrı repo, ayrı bundle ID, ayrı Supabase projesi, ayrı mağaza hattı.
sandikapp'in release workflow'larına, secret'larına, Supabase projelerine
dokunulmaz.

Ürün kararları: `docs/01-business.md`, `docs/02-planlama-teknik.md`,
`docs/03-tasarim-yonleri.md` (C2 yönü + satıcı paneli).

## Çalışma biçimi

1. Değişiklikleri onay beklemeden yap, sonunda Türkçe özetle (yasin toplu inceler).
2. Kaynak yorumları karar kaydıdır ("ne" değil "neden"). Var olan gerekçeyi silme, güncelle.
3. Skill'ler `.claude/skills/` altında (sandikapp'ten seçilmiş kopya). Skill bu
   dosyayla çelişirse **bu dosya kazanır**: `flutter-expert` Bloc/GoRouter önerir,
   burada Riverpod + `Navigator`; ham `Colors.*`/`fontSize:` üretir, burada token.

### Push saatleri (kullanıcı kuralı, tüm repolar)
Hafta içi 09:00–18:30 TR arası **push, PR açma/güncelleme, merge yok**. Gündüz
yerel commit + `git format-patch` yedeği; akşam push. `main`'e doğrudan push yok,
iş dalda ve PR'da.

## Mimari

```
assets/rules/rules.json   Ülke kuralları — TEK kaynak (uygulama, sunucu, web aracı aynı dosya)
lib/rights/               Saf Dart hak motoru: rule_set, rights_engine, advice. Flutter importu YOK.
lib/features/<özellik>/   domain/ (model), data/ (repo arayüzü + Demo + Supabase), ui/, providers.dart
lib/core/theme/           tokens.dart (VColors/VText/VSpace/VRadius/VSize, context.c / context.t), app_theme
lib/core/ui/              VCard, SectionTitle, ItemThumb, VIconButton — ortak bileşenler
lib/core/config/env.dart  --dart-define; fallback literal YOK. Anahtar yoksa demo veriyle açılır.
lib/l10n/                 app_en.arb (şablon) + app_tr.arb → generated/ (commit'li)
supabase/migrations/      Şema kaynağı. Her tabloda RLS + GRANT, sonda doğrulama bloğu.
supabase/functions/       Deno. Anahtarlar yalnız function secret'larından.
```

Katmanlama: ekran `Supabase.instance`/`http` görmez; repo arayüzü üzerinden.
Hesaplama `build()` içinde değil: `itemViewsProvider` korumaları bir kez hesaplar,
ekran `ItemView` okur. "Bugün" `clockProvider`'dan gelir (test/screenshot deterministik).

## Kurallar

**Hukuki doğruluk.** Doğrulanmamış bölge (`verified: false`) asla yasal hak
iddia etmez; "doğrulanmadı" görünür ve öneri resmi tüketici kurumuna yönlendirir.
Bir kuralı `verified: true` yapmak için `sources` alanına resmi kaynak yazılır
(`rights_engine_test` kaynaksız doğrulanmış bölgeyi kırar). Tamir uzatması
(AB 2024/825) `repairExtensionVerified` açılana kadar hesaba girmez.
Ekranda "hukuki tavsiye değildir" notu kalır.

**Tasarım (C2).** Her öğe bir işe hizmet eder; süs yok. Renk yalnızca anlam
taşır: accent = birincil eylem, deadline = 30 gün içinde biten koruma, muted =
bitmiş. Durum hiçbir yerde yalnızca renkle verilmez (cümle/ikon da var). Renk
`context.c.*`, tipografi `context.t.*`, boşluk `VSpace`, köşe `VRadius`; ham
`Colors.*` (transparent hariç), `Color(0x…)`, `fontSize:` ekranda yazılmaz.

**Apple HIG kontrolü.** Her UI değişikliğinde: dokunma ≥44 pt, Dynamic Type
(3.1×'e kadar taşma yok — `home_smoke_test` kilitli), kontrast, renk körlüğü,
güvenli alan, standart geri, sheet/modal, haptic, erişilebilirlik etiketi
(`VIconButton` etiketi zorunlu), hareketi azalt, sistem kalıbı. PR'a ve
yasin'e gösterilen artifact'e kısa **"HIG kontrolü"** bölümü yazılır.

**AI.** Fiş okuma önce Haiku 5.5, emin değilse Sonnet 5.5. Alan başına güven
puanı; 0.85 altı kullanıcıya "emin değiliz" diye gösterilir, sessizce kaydedilmez.
Sunucu AI'ı `FIS_OKU_ACIK=1` olmadan para harcamaz (fail-closed). Yanıtta
sağlayıcı hata metni/anahtar/ham çıktı dönmez.

**Gizli anahtar.** Repoya asla: `.env`, `google-services.json`,
`GoogleService-Info.plist`, `key.properties`, keystore, p8/p12, Supabase/Anthropic
anahtarları. Actions loglarına secret basılmaz.

**i18n.** Kullanıcıya görünen her metin iki .arb'da; ekranda ham literal yok.
Para `fmtMoney`, tarih `fmtDate` (`lib/core/format.dart`), ülke yerel ayarına göre.

## Doğrulama

```bash
flutter gen-l10n && flutter analyze lib/ test/ && flutter test
deno check supabase/functions/*/index.ts   # deno yoksa: npx -y deno@2 check ...
```
Bulut oturumu kurulumu: `bash tool/bulut_kurulum.sh` (sandikapp'teki betiğin kopyası).
