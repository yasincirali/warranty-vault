# F02 · Fiş & Garanti Kasası — global business (aşama 2)

13 Ekim 2026 · yasin seçti, global düşünülmesini istedi. Çalışma adı: **Kasa** (global ad sonra; ör. "Kept", "Claimbox"; marka kontrolü yapılmadı).

## 1. Kısa sonuç

Pazar **boş değil, kalabalık ama sığ.** 2025–2026'da App Store'a onlarca küçük "warranty tracker" çıktı (Wrnty, KeepSlip, Warranty Wallet, WarrantyVault, Warrantly, Docly, Warranto…); çoğu aynı şeyi yapıyor: fişi tara, bitiş tarihini hatırlat, PDF dışa aktar. Çoğunun puanı/yorumu bile yok.

Bu yüzden **"fişleri sakla" diye girersek kaybederiz.** Kazanılacak boşluk şu:

> **"Hakkını bilen ve senin yerine talep eden" uygulama.** Ürünü kaydetmek kolay; zor olan, bir şey bozulduğunda hâlâ hangi hakkın olduğunu bilmek ve talebi doğru belgeyle doğru yere göndermek.

## 2. Müşteri ihtiyacı (ne yaşıyorlar)

| Dert | Bugün ne oluyor | Kanıt / not |
|---|---|---|
| Fiş kayboluyor, termal fiş siliniyor | Arıza olunca belge yok, talep düşüyor | Tüm rakiplerin ana vaadi bu; ihtiyaç gerçek ama çözümü kopyalanmış |
| **Üretici garantisi ile yasal garanti karıştırılıyor** | "Garantisi bitti" diye ödenmesi gerekmeyen tamir parası ödeniyor | AB'de satıcının yasal sorumluluğu 2 yıl; **31 Temmuz 2026'dan sonra alınıp tamir edilen üründe +1 yıl** (AB Onarım Hakkı Direktifi). İngiltere'de 6 yıla kadar talep hakkı, Avustralya'da süresiz "makul süre", Türkiye'de 2 yıl + 14 gün cayma. Rakiplerin hiçbiri bunu ülkeye göre hesaplamıyor |
| İade penceresi kaçıyor | 14/30 günlük iade süresi fark edilmeden geçiyor | Bazı rakipler tarih tutuyor ama mağaza politikasını bilmiyor |
| Kayıt zahmetli | Kullanıcı fişi çekmeyi unutuyor, uygulama boş kalıyor, terk ediliyor | Rakiplerin çoğu yalnız kamera; e-posta faturası otomatik gelmiyor (Slice gibi e-posta tarayan eski servisler sahneden çekildi) |
| Talep süreci yorucu | Hangi belge, hangi adres, hangi dil, ne yazılacak? | Rakipler en fazla "PDF dışa aktar" diyor |
| Geri çağırma (recall) haberi kaçıyor | Sahip olunan üründe güvenlik geri çağırması olduğunu bilmiyorlar | ABD'de CPSC, AB'de Safety Gate verisi açık; kişinin eşyalarıyla eşleştiren yaygın bir uygulama yok |
| Aile ortak eşya | Fiş eşte, ürün evde, kimse bilmiyor | Aile paylaşımı rakiplerde nadir ve ücretli |
| Küçük istekler (yorumlardan) | Bir üründe birden çok garanti (parça/motor), "ömür boyu" seçeneği, bildirim zamanını ayarlama | Warranty Keeper yorumları |

## 3. Farklılaşma — bizim sunacağımız 6 şey

1. **Hak motoru (ana fark):** Ülke + satın alma tarihi + ürün türüne göre "şu an hangi hakların var" ekranı: üretici garantisi, yasal garanti, iade penceresi, onarım sonrası uzama. "Üretici garantisi bitti ama satıcıya karşı 9 ay daha hakkın var" cümlesini kuran tek uygulama olmak. Başlangıç ülkeleri: AB (27), İngiltere, Türkiye, ABD, Avustralya.
2. **Talep asistanı:** Arıza olunca tek düğme: fiş + seri no + fotoğraf + video paketini hazırlar, satıcıya/üreticiye ülkesinin hukukuna atıflı, kendi dilinde e-posta taslağı yazar (AI), talebin durumunu takip eder, cevap gelmezse bir sonraki adımı (tüketici hakem heyeti, ECC-Net, Small Claims) söyler.
3. **Zahmetsiz kayıt:** (a) Kişiye özel iletme adresi: `ad@kasa.app`'e faturayı ilet, AI okur. (b) Paylaş menüsünden Amazon/Trendyol sipariş sayfası. (c) Fiş fotoğrafı + ürünün kendisinin fotoğrafı, AI marka/model/seri no okur. Gmail'i doğrudan taramayı ilk sürümde **yapmıyoruz** (Google'ın kısıtlı kapsam güvenlik denetimi yıllık pahalı; iletme adresi aynı işi görür).
4. **Geri çağırma uyarısı:** Kayıtlı ürünler CPSC (ABD) ve Safety Gate (AB) verisiyle her gün eşleşir; eşleşme olursa bildirim.
5. **Ürün kartı:** Kılavuz PDF'i otomatik bulunur, filtre/bakım hatırlatması, ikinci el satarken "satın alma belgesi + garanti devri" paylaşım bağlantısı, sigorta için ev envanteri dışa aktarımı.
6. **Gizlilik önde:** Cihazda OCR seçeneği, şifreli yedek; "verini satmıyoruz" (Slice'ın e-posta verisini satma geçmişi bu kitlede hassas konu).

## 4. Hedef müşteri

- **Birincil:** 28–45 yaş, ev kurmuş, yılda birkaç elektronik/beyaz eşya alan haneler; AB + İngiltere + ABD.
- **İkincil:** Expatlar (ülke değiştirince hakları bilmiyor; çok dilli olmamız avantaj), Türkiye.
- **Sonra (B2B2C):** Sigorta şirketleri (ev envanteri), perakendeciler (dijital fiş), kredi kartı programları (uzatılmış garanti). İlk sürümde değil.

## 5. İş modeli

- **Ücretsiz:** 10 ürün, hatırlatmalar, hak ekranı (temel).
- **Premium:** sınırsız ürün, talep asistanı (AI), geri çağırma uyarısı, aile paylaşımı, e-posta iletme. Öneri: **$2,99/ay, $19,99/yıl**, aile $29,99/yıl. Rakiplerde ömür boyu satın alma yaygın, **bir "ömür boyu" seçeneği de koyalım** (~$49).
- AI maliyeti düşük: ürün başına bir kez okuma (Haiku/Sonnet), talep taslağı nadir. Kullanıcı başı ayda birkaç sent.
- Gelir senaryosu (varsayım, doğrulanmadı): 50 bin indirme × %3 ödeme × $20/yıl ≈ $30 bin/yıl. Hak motoru ve SEO tutarsa daha yüksek; tutmazsa diğer klonlar gibi küçük kalır.

## 6. Pazara giriş

- **"Hâlâ garantide mi?" ücretsiz web aracı:** ülke + tarih + ürün gir, haklarını gör. Her ülke × ürün türü için bir sayfa (SEO). "warranty tracker" anahtar kelimesi mağazada kalabalık; arama motorunda "is my laptop still under guarantee UK" gibi sorular boş → huni buradan gelir.
- Haber kancası: AB Onarım Hakkı (Temmuz 2026'dan sonraki alımlar), tüketici dernekleri ve expat siteleri.
- Diller: İngilizce, Almanca, Türkçe ile başla; Fransızca/İspanyolca/Felemenkçe hızlı ekle (AI çeviri + hukuk tablosu).

## 7. Riskler

| Risk | Etki | Önlem |
|---|---|---|
| Kalabalık, kolay kopyalanır | Yüksek | Hak motoru + talep asistanı + SEO içeriği kopyalanması zor kısım |
| Ülke hukuku yanlış hesaplanırsa | Yüksek | "Bilgi amaçlıdır", resmi kaynağa bağlantı, ülke tablosunu sürümle; ilk 5 bölgeyle sınırla |
| Kullanım sıklığı düşük (ayda bir açılır) | Orta | Değer anı (arıza) nadir ama büyük; yıllık abonelik + ömür boyu; geri çağırma ve iade uyarısı arada değer üretir |
| E-posta/fiş verisi hassas | Orta | Cihazda OCR, şifreleme, veri satışı yok; GDPR uyumu baştan |
| Tek kişi + maaşlı iş | Orta | MVP'yi dar tut: kayıt + hak ekranı + hatırlatma + talep taslağı |

## 8. Doğrulama deneyi (planlamadan önce, 2 hafta)

1. "Hâlâ garantide mi?" web aracını 3 ülke (İngiltere, Almanya, Türkiye) için tek sayfa yap.
2. r/BuyItForLife, r/LegalAdviceUK, r/germany, Ekşi gibi yerlerde gerçek sorulara araçla cevap ver.
3. Bekleme listesi topla. **Başarı ölçütü:** 2 haftada 300+ araç kullanımı ve 100+ bekleme listesi kaydı. Altındaysa konumlandırmayı yeniden düşün.

## 9. Senden karar

- **A) Doğrulama deneyiyle başla** (önerim): web aracı + bekleme listesi, sonra planlama.
- B) Doğrudan planlama ve teknik gereksinimlere geç.
- C) Konumlandırmayı değiştir (ör. yalnız ev envanteri/sigorta, ya da yalnız expat).

## Kaynaklar

- Rakip listeleri: [VaultlyKeep karşılaştırması](https://www.vaultlykeep.com/blog/best-receipt-tracker-apps), [WarrantyTracker 2026 listesi](https://warrantytracker.cloud/blog/best-warranty-tracker-apps-2026), [Wrnty](https://apps.apple.com/si/app/wrnty-warranty-receipts/id6747742961), [KeepSlip](https://apps.apple.com/us/app/keepslip/id6757175734), [Warranty Wallet](https://apps.apple.com/us/app/-/id6754895555), [WarrantyVault](https://apps.apple.com/app/id6758866183), [Warrantly](https://apps.apple.com/us/app/-/id6758876669), [Docly](https://apps.apple.com/app/docly/id6756065053), [Warranto](https://apps.apple.com/app/warranto/id6758460594), [Warranty Keeper yorumları](https://play.google.com/store/apps/details?id=com.warranty_keeper&hl=en-US), [Warranti](https://play.google.com/store/apps/details?id=com.ashadul95.WarrantiHomeInventoryReceiptManager&hl=en_US)
- E-posta tabanlı eski servisler: [Slice (Rakuten)](https://legacy.xconomy.com/?p=287298), [AlternativeTo](https://alternativeto.net/software/slice)
- AB Onarım Hakkı: [IamExpat](https://www.iamexpat.nl/expat-info/dutch-news/eu-right-repair-pushes-manufacturers-repair-devices-even-after-warranty), [IamExpat DE](https://www.iamexpat.ch/expat-info/germany-news/eu-right-repair-law-takes-effect-what-it-means-you), [Cooley](https://products.cooley.com/2024/07/11/spanner-in-the-works-eu-right-to-repair-directive-imposes-obligations-to-drive-circular-economy/)
- Geri çağırma: [CPSC recall app](https://www.cpsc.gov/es/Newsroom/News-Releases/2019/CPSC-Releases-New-Recall-App), [PIRG](https://publicinterestnetwork.org/?p=11569)
- Ev envanteri: [Encircle (Capterra)](https://www.capterra.co.nz/software/160202/encircle), [ev envanteri uygulamaları](https://greatguysmoving.com/blog/reviews-best-home-inventory-apps)

Not: Ülke sürelerinin (İngiltere 6 yıl, Avustralya, ABD) bir kısmı genel bilgiye dayanır; planlama aşamasında resmi metinlerden tek tek doğrulanacak. Yorum/şikâyet verisi zayıf çıktı (Reddit sonuçları gelmedi); doğrulama deneyi bu boşluğu da kapatır.
