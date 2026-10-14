# F02 · Fiş & Garanti Kasası — planlama ve teknik gereksinimler (aşama 3)

13 Ekim 2026 · yasin kararı: F02'de kal, global, hak motoruyla. Önceki aşama: [01-business.md](01-business.md).

**Ürün tek cümle:** Aldığın her ürün için "şu an hangi hakkın var, ne zaman bitiyor, bozulursa ne yapmalısın" sorusunu ülkenin hukukuna göre cevaplayan ve talebi senin yerine hazırlayan uygulama.

---

## 1. Fazlar

| Faz | Ne | Süre (akşam/hafta sonu temposu) | Çıkış ölçütü |
|---|---|---|---|
| **0 · Doğrulama** | "Hâlâ garantide mi?" web aracı (İngiltere, Almanya, Türkiye) + bekleme listesi | 2 hafta yapım + 2 hafta ölçüm | 300+ araç kullanımı, 100+ bekleme kaydı |
| **1 · MVP** | Uygulama: kayıt, AI fiş okuma, hak ekranı, hatırlatma, e-posta iletme | 8–10 hafta | TestFlight + kapalı Android testi, 50 aktif test kullanıcısı |
| **2 · Talep + geri çağırma** | Talep asistanı (AI e-posta + belge paketi + takip), CPSC/Safety Gate eşleşmesi, Premium açılışı | 4–6 hafta | İlk ödeme yapan 100 kullanıcı |
| **3 · Genişleme** | Aile paylaşımı, kılavuz bulma, ikinci el devir bağlantısı, yeni ülkeler, ömür boyu satın alma | sürekli | Ödeme oranı %3+ |

Kaba takvim (bugün 13 Ekim): Faz 0 ekim sonu–kasım ortası, MVP kasım–ocak, mağaza çıkışı **şubat 2027**, Faz 2 mart 2027.

## 2. MVP kapsamı

**Var**
- Ürün ekleme: fiş/fatura fotoğrafı veya PDF → AI ürün, marka, model, mağaza, tarih, tutar, para birimi, ülke çıkarır; kullanıcı onaylar.
- Kişiye özel iletme adresi (`kod@in.<alan-adı>`): e-posta faturası gelince ürün taslağı oluşur.
- Bir üründe birden çok koruma: üretici garantisi, uzatılmış garanti, yasal garanti, iade penceresi; "ömür boyu" ve "garantisiz" seçenekleri (rakip yorumlarında istenen).
- **Hak ekranı:** zaman çizelgesi + "bugün ne yapabilirsin" kartı (iade / değişim / tamir / fiyat indirimi) ve kaynak bağlantısı.
- Hatırlatmalar: kullanıcı seçer (30/7/1 gün önce, saat ayarı).
- Arama, kategori, PDF/ZIP dışa aktarma.
- Diller: İngilizce, Almanca, Türkçe.
- Ücretsiz sınır: 10 ürün (Premium kapalı olsa bile sınır kodda hazır).

**Yok (bilerek)**
- Gmail/Outlook doğrudan tarama (Google kısıtlı kapsam güvenlik denetimi yıllık ve pahalı; iletme adresi yeterli).
- Talep asistanı, geri çağırma, aile paylaşımı (Faz 2–3).
- Web panosu (Faz 0 aracı dışında).

## 3. Hak motoru

### 3.1 İlk kural seti (Faz 0 + MVP)

| Bölge | Yasal sorumluluk | Ayıbın baştan var sayıldığı süre | Diğer | Kaynak / durum |
|---|---|---|---|---|
| AB tabanı (2019/771) | 2 yıl (satıcıya karşı) | en az 1 yıl (ülke 2 yıla çıkarabilir: Portekiz 2 yıl) | Onarım seçilirse +12 ay (2024/1799, ülkelerin iç hukukuna aktarma tarihi 31 Temmuz 2026); internetten alımda 14 gün cayma | Komisyon ülke tablosu ([Madde 8a](https://commission.europa.eu/law/law-topic/consumer-protection-law/consumer-contract-law/consumer-sales-and-guarantees/article-8a-consumer-sales-and-guarantees-directive_en)) — doğrulandı |
| Almanya | 2 yıl | 1 yıl (2022'den beri) | — | [Advant Beiten](https://advant-beiten.com/en/blogs/cma/aenderungen-im-deutschen-kaufrecht-anpassungsbedarf-fuer-agb) — doğrulandı |
| İngiltere | 6 yıla kadar talep (İskoçya 5) | 6 ay | 30 gün kısa dönem iade hakkı; sonra tamir/değişim, olmazsa indirim/iade | [Trading Standards Wales](https://tradingstandards.gov.wales/en/consumer-advice/detail/indispute/122503/is-the-trader-right), [NI Business Info](https://www.nibusinessinfo.co.uk/content/what-do-if-problems-arise-supplied-goods) — 30 gün ve 6 ay doğrulandı; 6/5 yıl Limitation Act'ten **doğrulanacak** |
| Türkiye (6502) | 2 yıl ayıplı mal sorumluluğu; garanti belgesi en az 2 yıl | 6 ay | Mesafeli satışta 14 gün cayma; tamir süresi 20 iş günü, tamirde geçen süre garantiye eklenir; tekrarlayan arızada değişim | Genel bilgi — mevzuat metninden **doğrulanacak** |
| Avustralya (ACL) | Sabit süre yok; ürünün "makul" ömrü boyunca | — | Tüketici garantileri üretici garantisinden bağımsız ve otomatik | [NT Gov](https://nt.gov.au/law/rights/consumer-guarantees-under-australian-law), [WA Commerce](https://commerce.wa.gov.au/consumer-protection/guarantees-and-warranties-0) — doğrulandı |
| ABD | Federal yasal garanti yok; eyalete göre zımni garanti (UCC 2-725: 4 yıl dava süresi); Magnuson-Moss yazılı garantiyi düzenler | — | Eyalet farkları büyük | Genel bilgi — **doğrulanacak**; MVP'de ABD yalnız üretici garantisi + iade penceresi |

Kural: bir bölgenin kuralı resmi kaynaktan doğrulanmadan uygulamada "hak" olarak gösterilmez; yalnız "üretici garantisi" gösterilir.

### 3.2 Model

- `kural_seti` tablosu sürümlü: `bolge`, `gecerlilik_baslangic` (alım tarihine göre hangi kural geçerli), `urun_turu` (yeni/ikinci el/dijital içerik/araç), `sureler` JSON, `kaynak_url`, `dogrulandi_tarih`.
- Saf fonksiyon `haklariHesapla(alim, bolge, bugun, olaylar[])` → `[{tur, baslangic, bitis, ispat_yuku, yapilabilecekler[], kaynak}]`. `olaylar` = tamir, değişim, talep (AB +12 ay ve TR tamir süresi eklemesi buradan gelir).
- **Tek kaynak:** kurallar bir JSON dosyasında yaşar; uygulama, sunucu ve Faz 0 web aracı aynı dosyayı okur. Kural değişince bütün yüzeyler birlikte değişir.
- Test: her bölge için tablo testleri (alım tarihi × olay × bugün); sınır günleri (tam 2. yıl, 30. gün) ayrı test.

## 4. Mimari

```
Flutter (iOS/Android) ──► Supabase (AB bölgesi, Frankfurt)
  Riverpod                  Postgres + RLS (her satır sahibine)
  yerel önbellek            Storage: fiş görselleri (özel bucket, imzalı URL)
                            Edge Functions:
                              fis-oku        (Claude vision → yapılandırılmış JSON)
                              eposta-al      (gelen e-posta webhook → taslak ürün)
                              hatirlatma     (cron → FCM/APNs)
                              geri-cagirma   (Faz 2: CPSC + Safety Gate günlük senkron)
                              talep-yaz      (Faz 2: AI talep e-postası)
Faz 0 web aracı: statik site (kural JSON'u + küçük JS), GitHub Pages / Cloudflare Pages
Ödeme: RevenueCat · Hata: Crashlytics · Analitik: Firebase Analytics
Gelen e-posta: Postmark veya Cloudflare Email Routing → webhook
```

SANDIK'tan doğrudan taşınacaklar: Supabase + RLS + GRANT kalıbı, `requireCronSecret`, RevenueCat kurulumu, Remote Config bayrakları, l10n (gen-l10n), tasarım token sistemi ve HIG testleri, push altyapısı.

### 4.1 Tablolar (MVP)

`profiles` (ülke, dil, iletme_kodu) · `urunler` (ad, marka, model, seri_no, kategori, alim_tarihi, tutar, para_birimi, magaza, alim_kanali: magaza/internet, bolge) · `belgeler` (urun_id, tur: fis/fatura/garanti/kılavuz, storage_yolu, ai_cikti JSON) · `korumalar` (urun_id, tur: uretici/uzatilmis/yasal/iade, bitis, kaynak: kullanıcı/kural) · `olaylar` (urun_id, tur: ariza/tamir/degisim/talep, tarih) · `hatirlatmalar` · `kural_seti`.

### 4.2 AI

- Fiş okuma: önce Haiku 5.5, düşük güvenli alanlarda Sonnet 5.5'e yükselt; ürün başına tek çağrı, sonuç saklanır (yeniden okunmaz).
- Tahmini maliyet: ürün başına ~1 sent altı; aktif kullanıcı başına ayda birkaç sent.
- Kullanıcı onayı olmadan AI çıktısı kesinleşmez (yanlış tarih = yanlış hak).

## 5. Gizlilik ve uyum

- Veri AB'de (GDPR); KVKK için aydınlatma + açık rıza metni; ABD için gizlilik politikası. Veri satışı yok, reklam yok.
- Fiş görselleri özel bucket'ta; isteğe bağlı "yalnız cihazda sakla" modu (Faz 3).
- Her hak ekranında: "Bilgi amaçlıdır, hukuki tavsiye değildir" + resmi kaynak bağlantısı.
- Hesap silme uygulama içinden (App Store şartı).
- Gelir: mağaza geliri yurt dışından da gelecek; 20/B kapsamı ve döviz gelirinin beyanı mali müşavirle teyit edilmeli (SANDIK'taki "20/B ve kurumsal iş" konuşmasıyla birlikte).

## 6. Aylık maliyet (MVP sonrası, ilk 1.000 kullanıcı)

| Kalem | Tahmin |
|---|---|
| Supabase Pro | $25 |
| Alan adı + e-posta alma | ~$2 + ücretsiz katman |
| AI (fiş okuma) | $5–15 |
| RevenueCat | $2.5k gelire kadar ücretsiz |
| Apple/Google geliştirici hesabı | mevcut |
| **Toplam** | **~$35–45/ay** |

## 7. Ölçümler

Faz 0: araç kullanımı, bekleme listesi dönüşümü, ülke dağılımı. MVP: ilk hafta 3+ ürün ekleyen kullanıcı oranı (ana aktivasyon), iletme adresi kullanımı, 30 günlük tutunma. Faz 2: talep asistanı kullanımı, ödeme oranı, iade oranı.

## 8. Riskler

| Risk | Önlem |
|---|---|
| Yanlış hak hesabı | Doğrulanmamış bölge gösterilmez; kural sürümleri + tablo testleri; kaynak bağlantısı |
| Kalabalık pazar, kopyalanma | Hak motoru + çok dilli SEO içeriği + talep asistanı birlikte; Faz 0 ölçütü tutmazsa durup yeniden konumlan |
| Senin zamanın (maaşlı iş + SANDIK) | MVP dar; Faz 0 ölçütü tutmazsa MVP'ye hiç başlanmaz |
| Kullanıcı ürün eklemeyi bırakır | İletme adresi + paylaş menüsü; ilk açılışta "son aldığın 3 şeyi ekle" akışı |

## 9. Senden kararlar

1. **Faz 0'a başlayalım mı?** Önerim evet; web aracını ben yazarım, yeni bir repo ve alan adı gerekir.
2. **Çalışma adı ve alan adı:** Önerilerim: Kept, Claimbox, Warrantly benzeri değil, kısa ve ülke bağımsız bir ad. İstersen 10 aday + alan adı müsaitliği çıkarırım.
3. **İlk ülkeler:** İngiltere + Almanya + Türkiye (önerim). Alternatif: tüm AB tek pakette (AB tabanı + ülke farkları).
