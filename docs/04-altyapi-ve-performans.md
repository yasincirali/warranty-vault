# Altyapı ve performans: rakip kıyası önerileri (17 Ekim 2026)

Rakip kıyasından çıkan dört eksik bu turda eklendi: hatırlatma, fiş/belge,
arama, yedek. Her biri için "uygulamayı yavaşlatır mı, telefonu yorar mı"
sorusu önce soruldu; aşağıdaki kararlar bunun cevabı. Ölçümler testlerde
kilitli (sayılar CI makinesinde, JIT/debug; telefonda AOT daha hızlıdır).

## Mevcut altyapı (değişmeyen)

- Kasa yerel: `Application Support/vault/vault.json` + `photos/`. Yazma
  "geçici dosya + rename" ile atomik. Sunucu yok; `Env.hasBackend` boş.
- Hesaplar `itemViewsProvider`'da bir kez yapılır; ekran yalnız okur.
- AI fiş okuma (`fis-oku`) hâlâ `DemoReceiptReader`: uygulamanın kendi
  Supabase projesi ve secret'ları açılmadan bağlanamaz (yasin'in adımı).

## 1. Hatırlatma (`lib/features/reminders/`)

| Karar | Neden |
|---|---|
| Plan saf Dart (`planReminders`), platform yalnız sonucu alır | Kurallar telefonsuz test edilir; eklenti çağrısı tek yerde |
| En fazla 48 bekleyen bildirim | iOS 64'ten fazlasını sessizce atar; her açılışta plan yenilenir, sonrakiler sıraya girer |
| 800 ms birleştirme + plan imzası | Raf sürükleme gibi süreleri değiştirmeyen işlemler platforma hiç gitmez (test: `moves send nothing`) |
| Adaylar UTC gün olarak karşılaştırılır, yerel saat yalnız tutulan 48'e | Yerel saat dönüşümü pahalı; 1 000 ürün 17,9 ms → 4,3 ms (JIT) |
| Mutlak an (UTC) ile zamanlama, saat dilimi veritabanı yok | ~400 KB veri ve açılışta yükleme maliyeti yok |
| İzin ilk ürün kaydedildikten sonra, bir kez | Açılışta izin isteyen uygulama reddedilir; bağlamda sorulan kabul edilir |
| Süreler: iade 3 ve 1 gün, garanti/yasal hak 30 ve 7 gün, ispat yükü 14 gün önce, saat 10:00 | İade 14 günlük; bir ay önce uyarmak alış günü uyarmak olurdu |

Ölçüm: `planReminders(1000 ürün)` 4,3 ms; yalnız değişiklikte, karede değil.

## 2. Fiş, fatura, kılavuz (`ItemDoc`, `documents.dart`)

- Fotoğraf platform seçicisinde küçültülür (2000 px, JPEG %85): Dart'ta
  görüntü işleme yok, ana iş parçacığı boş kalır. Termal fiş okunur kalır,
  dosya ~300–600 KB.
- PDF 20 MB sınırı; sistem görüntüleyicide açılır (Quick Look), uygulamaya
  PDF motoru eklenmedi (ikili boyut büyümez).
- Küçük resimler `ResizeImage` ile ekran boyutunda çözülür: 2000 px'lik
  fiş görüntü önbelleğinde tam boyutta durmaz.
- Eski `invoicePath` alanı okunurken fişe çevrilir (veri kaybı yok).

## 3. Arama (`lib/features/search/`)

- Ürün başına tek katlanmış metin (ad, mağaza, seri no, raf) kasa
  değişince bir kez kurulur; tuş basışında yalnız `contains`.
- Türkçe harfler ve büyük/küçük harf katlanır ("sarj" → "Şarj").
- Ölçüm: 5 000 ürün, tuş başına 5,2 ms (JIT).

## 4. Yedek (`lib/features/backup/`)

- Arka plan isolate'inde, dosyadan dosyaya akış: arşiv belleğe alınmaz.
- Fotoğraf/PDF sıkıştırılmadan saklanır (zaten sıkışık; deflate saniyeler
  harcar, %1 kazandırır), yalnız JSON sıkıştırılır.
- Geri yükleme önce yan klasöre açılır, doğrulanır, kullanıcı onaylar,
  sonra iki `rename` ile değişir: yarıda kalırsa ya eski ya yeni kasa.
- Zip içinde yalnız `vault.json`, `backup.json`, `photos/*`, `docs/*`
  yazılır (zip slip koruması). Daha yeni biçimli yedek reddedilir.
- Ölçüm: 150 fotoğraf / 60 MB yedek 341 ms, açma 280 ms.
- **Şifreleme yok (bilinçli).** Uygulamanın kendi şifrelemesi App Store
  ihracat uyumu cevabını (`ITSAppUsesNonExemptEncryption`) değiştirir;
  ayrıca saf Dart ChaCha20 ~20 MB/s, AES-GCM ~8 MB/s ölçüldü (CI
  makinesinde, AOT; telefonda ölçülmedi)
  (60 MB'lık kasada 3–8 sn). Dosya iCloud Drive/Dosyalar'da durur; ekranda
  "düz zip, kendine ait bir yerde tut" diye yazıyor. Karar yasin'de.

## Dokunulmayanlar / sonraki adımlar

- Barkod/etiket tarama, ana ekran widget'ı, e-postayla fiş iletme, aile
  paylaşımı, geri çağırma uyarısı: kıyasta "sonra" listesinde.
- Ürün düzenleme (detaydaki kalem düğmesi) ve "Bu bilgi nereden?" düğmesi
  hâlâ boş; ayrı iş.
