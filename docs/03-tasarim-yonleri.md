# F02 · Tasarım yönleri (13 Ekim 2026)

Canvas: https://claude.ai/artifact/QGJ86eWeeGdjJ4Rx7i3Api — üç yön, her birinde 3 telefon ekranı. Örnek ürün hepsinde aynı (MacBook Air, Saturn Berlin, 10.11.2024; üretici garantisi bitti, yasal hak 28 gün) ki karşılaştırma adil olsun.

| Yön | Fikir | İmza öğe | Yazı tipi | Renk |
|---|---|---|---|---|
| A · Fiş | Uygulama bir fiş defteri; her eşya yırtık kenarlı bir fiş | Fiş kâğıdı + noktalı "defter satırı" hak listesi + barkod (seri no) | Familjen Grotesk + IBM Plex Mono | Gece mavisi zemin, fiş beyazı, turuncu vurgu |
| B · Kalkan | Koruma katmanları iç içe halka | Üç halka: iade / garanti / yasal hak; kalan süre renkli yay | Bricolage Grotesque + Geist Mono | Koyu yeşil-siyah, nane yeşili + kehribar |
| C · Vitrin | Eşyalar müze kataloğu gibi; nesne önde | Pastel ürün karoları + Gantt zaman çizelgesi + büyük sayaç | Instrument Sans | Açık gri zemin, kobalt vurgu |

Ekranlar: A = Kasa, Ürün kartı, Talep asistanı (e-posta taslağı). B = Kasa (koruma skoru), Ürün halkaları, Talep takibi. C = Vitrin ızgarası, Ürün + zaman çizelgesi, Fatura okuma onayı.
Karar bekleniyor: yasin hangi yönü seçecek (ya da karışım).

## C2 · Vitrin, işlev odaklı (yasin 13 Ekim 22:40: "Vitrin'e yakın; her öğe bir işleve hizmet etsin, AI slop olmasın, UX odaklı, amacını net ve kolay karşılasın")

Üç ana iş: (1) eşyayı 10 saniyede ekle, (2) neyle ilgilenmem gerektiğini tek bakışta gör, (3) bir şey bozulunca ne yapacağımı bil ve yap.

| Öğe | İşlevi | v1'den farkı |
|---|---|---|
| "İlgilen" bölümü en üstte | Süresi 30 günden az kalanları tam cümleyle söyler; listeyi taramaya gerek kalmaz | v1'de yoktu, sadece filtre vardı |
| Durum cümlesi ("İade süresi 4 gün sonra bitiyor") | Rozet yerine okunur cevap; renk körü için de anlamlı | v1'de renkli hap |
| Nötr ürün karosu (gerçek ürün fotoğrafı gelecek) | Eşyayı görerek tanıma | v1'deki rastgele pastel zeminler kaldırıldı (anlam taşımıyordu) |
| Renk = anlam | Mavi yalnız ana eylem; kahverengi-turuncu yalnız yaklaşan süre; gri biten | v1'de renk süstü |
| Altta tam genişlik "Fiş ya da fatura ekle" | En sık iş, başparmak bölgesinde | v1'de sağ üstte küçük + |
| Ürün: "Bugünkü durumun" kartı önce | Kullanıcının asıl sorusunun cevabı | v1'de büyük sayı vardı ama hangi hak olduğu ikincildi |
| Hak satırları (bitiş tarihli liste) | Gantt'tan daha hızlı okunur, ekran okuyucuya uygun | v1'deki zaman çizelgesi kaldırıldı |
| Fatura / Seri no kısayolları | Mağazada ya da serviste kanıtı tek dokunuşla göstermek | yeni |
| "Bir sorun var" → "Ne oldu?" → önerilen yol | Hukuku kullanıcıya öğretmeden doğru adımı söyler | v1'de akış yoktu |
| Ekleme: "Doğru mu?" + şüpheli alanda uyarı ikonu | AI hatası yanlış hak hesabına dönüşmesin; kullanıcı yalnız şüpheliye bakar | v1'de "kontrol et" hapı vardı, ikon + etiketle sadeleşti |
| Sekme çubuğu yok | Tek ana ekran; talepler "İlgilen"de görünür | v1'de vardı (A/B'de) |

Not: "tamir edilirse hakkın 1 yıl uzar" metni AB 2024/1799'a dayanır; Almanya'nın iç hukuka aktarması doğrulanmadı, ürüne girmeden önce kontrol edilecek.

## SaaS açıları (yasin 13 Ekim 22:47: "iterasyonlarda yalnız mobil değil SaaS da düşün")
1. Satıcıya SaaS (önerilen): dijital fiş + garanti kartı gönderimi, talep ve yasal süre paneli; müşteri uygulamasına otomatik kayıt (kayıt zahmeti çözülür, iki taraflı büyüme).
2. Hak motoru API'si (çağrı başı ücret; e-ticaret, sigorta, hukuk teknolojisi).
3. Tüketici web paneli (toplu yükleme, sigorta envanteri; mobili tamamlar).
Uyarı: doğrudan SaaS geliri büyük olasılıkla 20/B dışında; mali müşavir teyidi gerekli.

## Satıcı paneli web ekranları (14 Ekim, yasin "olur")
Canvas'ta en altta, C2 diliyle 3 sayfa (masaüstü ve telefon genişliğinde çalışır):
- Genel görünüm: cevap bekleyen talepler en yakın yasal süreye göre sıralı, her satırda "senin durumun" (ispat yükü kimde); 3 işe yarar sayı (gönderilen dijital fiş, çözüm süresi, garantisi bu ay biten müşteri → uzatılmış garanti teklifi); son fişlerin müşteri tarafında kaydedilip kaydedilmediği.
- Talep detayı: müşteri bildirimi + video, dijital fişle otomatik eşleşen satış kaydı, satıcının yasal durumu (kaynaklı), karar seçenekleri (tamir önerilen; reddetmenin şartı yazılı).
- Dijital fiş gönder: "her satışta otomatik" entegrasyon bandı en üstte, kısa form, müşterinin göreceği kartın canlı önizlemesi ("Eşyalarıma ekle").
