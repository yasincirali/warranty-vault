// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Eşyalarım';

  @override
  String get searchItems => 'Eşya ara';

  @override
  String attentionHeader(int count) {
    return 'İlgilen · $count';
  }

  @override
  String allHeader(int count) {
    return 'Tümü · $count';
  }

  @override
  String get addReceipt => 'Fiş ya da fatura ekle';

  @override
  String get emptyTitle => 'İlk faturanı ekle, haklarını biz takip edelim.';

  @override
  String get emptyBody =>
      'Bir süre bitmeden haber veririz. Bir şey bozulduğunda ne yapacağını tek ekranda söyleriz.';

  @override
  String endsIn(String kind, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün sonra bitiyor',
      zero: 'bugün bitiyor',
    );
    return '$kind $_temp0';
  }

  @override
  String get kindReturn => 'İade süresi';

  @override
  String get kindReject => '30 günlük iade hakkı';

  @override
  String get kindManufacturer => 'Üretici garantisi';

  @override
  String get kindExtended => 'Uzatılmış garanti';

  @override
  String get kindLegal => 'Yasal hak';

  @override
  String statusLine(String kind, String remaining) {
    return '$kind · $remaining';
  }

  @override
  String get protectionEnded => 'Koruma bitti';

  @override
  String get noFixedEnd => 'Sabit süre yok';

  @override
  String durYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yıl',
    );
    return '$_temp0';
  }

  @override
  String durMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ay',
    );
    return '$_temp0';
  }

  @override
  String durDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün',
      zero: 'bugün',
    );
    return '$_temp0';
  }

  @override
  String get todayStatus => 'Bugünkü durumun';

  @override
  String get answerReturn => 'Gerekçe göstermeden iade edebilirsin.';

  @override
  String get answerReject => 'Arızalıysa reddedip paranı geri isteyebilirsin.';

  @override
  String get answerManufacturer =>
      'Arıza olursa üreticinin servisi ücretsiz tamir eder.';

  @override
  String get answerExtended =>
      'Arıza olursa uzatılmış garantin tamiri karşılar.';

  @override
  String get answerLegal =>
      'Satıcıya karşı yasal hakkın sürüyor. Arıza olursa ücretsiz tamir ya da değişim isteyebilirsin.';

  @override
  String get answerNone => 'Bu eşyanın koruması bitti.';

  @override
  String get answerUnverified =>
      'Bu ülkenin yasal kurallarını henüz doğrulamadık; yalnız üretici garantisini gösteriyoruz.';

  @override
  String endsOn(String date) {
    return 'Bitiş: $date';
  }

  @override
  String endedOn(String date) {
    return 'Bitti · $date';
  }

  @override
  String get notVerified => 'Henüz doğrulanmadı';

  @override
  String get whereFrom => 'Bu süre nereden geliyor?';

  @override
  String get invoice => 'Fatura';

  @override
  String get serial => 'Seri no';

  @override
  String get problemButton => 'Bir sorun var';

  @override
  String get whatHappened => 'Ne oldu?';

  @override
  String get issueDefect => 'Çalışmıyor ya da arıza var';

  @override
  String get issueDamaged => 'Hasarlı geldi';

  @override
  String get issueNotAsDescribed => 'Anlatıldığı gibi değil';

  @override
  String get issueLost => 'Kayboldu ya da çalındı';

  @override
  String get recommended => 'Önerilen yol';

  @override
  String adviceReturn(String store) {
    return 'Satıcıya ($store) iade et. Süre içindesin, gerekçe göstermen gerekmez.';
  }

  @override
  String adviceReject(String store) {
    return 'Satıcıya ($store) reddettiğini bildir, paranın tamamını geri iste. İlk 30 gün içindesin.';
  }

  @override
  String adviceSellerRepair(String store) {
    return 'Satıcıdan ($store) tamir ya da değişim iste. Yasal hakkın sürdüğü için ücret ödememen gerekir.';
  }

  @override
  String get proofSeller => 'Arızanın baştan olmadığını satıcı kanıtlamalı.';

  @override
  String get proofBuyer =>
      'Bu aşamada arızanın baştan var olduğunu göstermen gerekebilir; fotoğraf ve video önemli.';

  @override
  String get adviceManufacturer =>
      'Üreticinin servisine başvur. Garantin hâlâ geçerli.';

  @override
  String get adviceCheckLocal =>
      'Ülkendeki tüketici kurumu haklarını söyleyebilir. Bu kuralları henüz doğrulamadık.';

  @override
  String get adviceInsurance =>
      'Garanti kayıp ve hırsızlığı kapsamaz. Konut ya da cihaz sigortana bak.';

  @override
  String get adviceNotCovered =>
      'Bu eşyanın koruması bitti. Ücretli tamir ya da üreticinin iyi niyeti kalan yollar.';

  @override
  String get stepDocsReady => 'Fatura ve seri no hazır';

  @override
  String get stepAddEvidence => 'Sorunun fotoğrafını ya da videosunu ekle';

  @override
  String get stepWeDraft =>
      'Mesajı satıcının dilinde biz yazarız; Türkçesini görüp sen gönderirsin';

  @override
  String get continueButton => 'Devam et';

  @override
  String get isItRight => 'Doğru mu?';

  @override
  String get readFromInvoice => 'Faturadan okuduk. Yanlışsa dokunup düzelt.';

  @override
  String get fieldProduct => 'Ürün';

  @override
  String get fieldStore => 'Mağaza';

  @override
  String get fieldDate => 'Alış tarihi';

  @override
  String get fieldAmount => 'Tutar';

  @override
  String get fieldSerial => 'Seri no';

  @override
  String get checkThis => 'Emin değiliz, kontrol et';

  @override
  String countryNote(String country) {
    return 'Alındığı ülke: $country. Hakların o ülkenin kurallarına göre hesaplanır.';
  }

  @override
  String get save => 'Kaydet';

  @override
  String get retake => 'Yeniden çek';

  @override
  String get close => 'Kapat';

  @override
  String get back => 'Geri';

  @override
  String get edit => 'Düzenle';

  @override
  String get disclaimer => 'Bilgi amaçlıdır, hukuki tavsiye değildir.';

  @override
  String get left => 'kaldı';

  @override
  String ruleSemantics(int p) {
    return 'Sürenin yüzde $p kadarı geçti';
  }

  @override
  String ruleProofMonth(int n) {
    return '$n. ay · ispat sana geçer';
  }

  @override
  String rulesOf(String country) {
    return '$country kuralları';
  }

  @override
  String get regionDE => 'Almanya';

  @override
  String get regionEU => 'AB';

  @override
  String get regionGB => 'Birleşik Krallık';

  @override
  String get regionTR => 'Türkiye';

  @override
  String get regionUS => 'ABD';

  @override
  String get regionAU => 'Avustralya';

  @override
  String get showAtCounter => 'Kasada göster';

  @override
  String get counterTitle => 'Satın alma kanıtı';

  @override
  String counterRight(String kind, String date) {
    return '$kind: $date tarihine kadar.';
  }

  @override
  String get counterAsk => 'Ücretsiz tamir ya da değişim istiyorum.';

  @override
  String get counterNoInvoice => 'Henüz fatura fotoğrafı yok';

  @override
  String get adviceIfRefused =>
      'Satıcı reddederse başvuracağın resmi kurumu gösterir, şikâyet metnini biz hazırlarız.';

  @override
  String get notVerifiedWhy =>
      'Bu ülkenin kuralını henüz resmi kaynaktan doğrulamadık, bu yüzden süre göstermiyoruz.';

  @override
  String get wayPhoto => 'Fişin fotoğrafını çek';

  @override
  String get wayPhotoWhy => 'Kâğıt fiş birkaç ayda silinir; fotoğrafı kalır.';

  @override
  String get wayPdf => 'PDF fatura seç';

  @override
  String get wayPdfWhy => 'Online alışverişlerin faturaları.';

  @override
  String get wayEmail => 'E-postayla ilet';

  @override
  String get wayEmailWhy => 'İlettiğin her fatura kendiliğinden eklenir.';

  @override
  String get previewTitle => 'Ne göreceksin';

  @override
  String get previewBody =>
      'Her eşyanın süre çizgisi: ne kadar geçti, ne kadar kaldı, ispat yükü ne zaman sana geçiyor.';

  @override
  String daysLeft(int n) {
    return 'gün kaldı';
  }

  @override
  String cabinetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şey',
      one: '1 şey',
    );
    return 'Raflarında $_temp0 var';
  }

  @override
  String get cabinetHint =>
      'Başka rafa sürükle. Yana fırlatırsan kasadan çıkar.';

  @override
  String get addItem => 'Ürün ekle';

  @override
  String get shelfLabelHint => '+ Etiket';

  @override
  String shelfName(int n) {
    return '$n. raf';
  }

  @override
  String shelfLabelA11y(int n, String label) {
    return '$n. raf etiketi: $label. Düzenlemek için iki kez dokun.';
  }

  @override
  String shelfNoLabelA11y(int n) {
    return '$n. rafın etiketi yok. Eklemek için iki kez dokun.';
  }

  @override
  String itemA11y(String name, String status, String shelf) {
    return '$name. $status. $shelf.';
  }

  @override
  String get moveUp => 'Üst rafa taşı';

  @override
  String get moveDown => 'Alt rafa taşı';

  @override
  String get throwOut => 'Kasadan çıkar';

  @override
  String thrownOut(String name) {
    return '$name kasadan çıktı';
  }

  @override
  String get undo => 'Geri al';

  @override
  String disposedHeader(int count) {
    return 'Çıkardıkların · $count';
  }

  @override
  String get putBack => 'Rafa geri koy';

  @override
  String get wayCamera => 'Ürünün fotoğrafını çek';

  @override
  String get wayCameraWhy => 'Arka planından ayırıp rafa koyarız.';

  @override
  String get wayGallery => 'Fotoğraflarından seç';

  @override
  String get wayGalleryWhy => 'Elindeki bir ürün fotoğrafı da olur.';

  @override
  String get waySample => 'Örnek kasayı yükle';

  @override
  String get waySampleWhy => 'Rafları önce altı örnek ürünle dene.';

  @override
  String get emptyCabinetTitle => 'Aldığın şeyleri raflarına diz.';

  @override
  String get emptyCabinetBody =>
      'Her biri fişini ve haklarını yanında taşır. Bir süre bitmeden haber veririz.';

  @override
  String get sampleDesk => 'Çalışma masası';

  @override
  String get sampleLiving => 'Salon';

  @override
  String get sampleKitchen => 'Mutfak';

  @override
  String get addTitle => 'Yeni ürün';

  @override
  String get photoCamera => 'Kamera';

  @override
  String get photoGallery => 'Fotoğraflar';

  @override
  String get photoOptional =>
      'Fotoğraf şart değil ama rafta onu fotoğrafından tanırsın.';

  @override
  String get loading => 'Yükleniyor';

  @override
  String get lifting => 'Arka plandan ayırıyorum…';

  @override
  String get photoCutout => 'Dekupe';

  @override
  String get photoOriginal => 'Orijinal';

  @override
  String get photoChange => 'Fotoğrafı değiştir';

  @override
  String get photoFailed => 'Bu fotoğraf okunamadı. Başka birini dene.';

  @override
  String get photoNoCutout =>
      'Arka plan ayırmaya yetecek kadar düz değil; fotoğraf olduğu gibi kalıyor.';

  @override
  String get fieldChannel => 'Nereden aldın?';

  @override
  String get channelStore => 'Mağazadan';

  @override
  String get channelOnline => 'İnternetten';

  @override
  String get fieldRegion => 'Alındığı ülke';

  @override
  String get warrantyNone => 'Yok';

  @override
  String get fieldShelf => 'Raf';

  @override
  String get shelfAuto => 'Boş yeri olan ilk raf';

  @override
  String get putOnShelf => 'Rafa koy';

  @override
  String get nameHint => 'ör. Kahve makinesi';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get langTr => 'Türkçe';

  @override
  String get langEn => 'English';

  @override
  String get settingsRegion => 'Ülke';

  @override
  String get regionSystem => 'Telefonun ülkesi';

  @override
  String get settingsRegionHint =>
      'Yeni eklediğin ürünlerin hakları bu ülkenin kurallarıyla hesaplanır. Her üründe ayrıca değiştirebilirsin.';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get aboutLocal =>
      'Dolabın ve fotoğrafların bu telefonda saklanır. Hesap açman gerekmez.';

  @override
  String amountPreview(String amount) {
    return 'Kaydedilecek: $amount';
  }

  @override
  String get amountUnreadable => 'Tutar okunamadı; rakamla yaz.';

  @override
  String get settingsExport => 'Dışa aktar';

  @override
  String get exportPdf => 'PDF raporu';

  @override
  String get exportPdfWhy =>
      'Yazdırmak ya da saklamak için: her ürün, korumaları ve tarihleriyle.';

  @override
  String get exportExcel => 'Excel tablosu';

  @override
  String get exportExcelWhy =>
      'Sıralamak ve süzmek için: her ürün bir satır, tarihler gerçek tarih.';

  @override
  String exportPreparing(String format) {
    return '$format hazırlanıyor';
  }

  @override
  String get exportFailed => 'Dosya oluşturulamadı. Tekrar dene.';

  @override
  String get exportEmpty => 'Dışa aktarılacak bir şey yok. Önce bir ürün ekle.';

  @override
  String get exportHint =>
      'Dosya bu telefonda oluşur; nereye gideceğini sen seçersin.';

  @override
  String get exportTitle => 'Envanter';

  @override
  String get exportFileName => 'envanter';

  @override
  String exportAsOf(String date) {
    return '$date itibarıyla';
  }

  @override
  String get exportItems => 'Ürün';

  @override
  String get exportTotal => 'Toplam ödenen';

  @override
  String get exportSoon => '30 gün içinde biten';

  @override
  String get exportNone => 'Yok';

  @override
  String get exportAttention => 'İlgilen';

  @override
  String get exportAttentionWhy =>
      'Bu korumalar 30 gün içinde bitiyor. Bir sorun varsa tarihten önce harekete geç.';

  @override
  String get exportUnlabelled => 'Etiketsiz raf';

  @override
  String exportPage(int page, int pages) {
    return 'Sayfa $page / $pages';
  }

  @override
  String get exportStatusActive => 'Sürüyor';

  @override
  String get exportStatusEnded => 'Bitti';

  @override
  String exportDaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n gün kaldı',
      zero: 'bugün bitiyor',
    );
    return '$_temp0';
  }

  @override
  String exportProofUntil(String date) {
    return '$date tarihine kadar ispat satıcıda';
  }

  @override
  String get exportNoProtection => 'Kayıtlı koruma yok';

  @override
  String get exportLegend =>
      'Çubuk: alıştan bu yana geçen süre. Halka: bugün. Dik çizgi: ispat yükünün sana geçtiği gün. Turuncu: 30 gün içinde bitiyor.';

  @override
  String get colShelf => 'Raf';

  @override
  String get colProduct => 'Ürün';

  @override
  String get colCategory => 'Kategori';

  @override
  String get colStore => 'Mağaza';

  @override
  String get colChannel => 'Alış yeri';

  @override
  String get colCountry => 'Ülke';

  @override
  String get colPurchased => 'Alış tarihi';

  @override
  String get colPrice => 'Tutar';

  @override
  String get colCurrency => 'Para birimi';

  @override
  String get colSerial => 'Seri no';

  @override
  String get colNext => 'Sıradaki biten';

  @override
  String get colNextEnd => 'Bitiş tarihi';

  @override
  String get colDaysLeft => 'Kalan gün';

  @override
  String get colProofEnd => 'İspat satıcıda (son gün)';

  @override
  String colEnds(String kind) {
    return '$kind bitişi';
  }

  @override
  String get colProtection => 'Koruma';

  @override
  String get colStart => 'Başlangıç';

  @override
  String get colEnd => 'Bitiş';

  @override
  String get colStatus => 'Durum';

  @override
  String get colSources => 'Kaynak';

  @override
  String get colDisposed => 'Çıkarıldığı tarih';

  @override
  String get sheetDisposed => 'Çıkardıkların';

  @override
  String get sheetProtections => 'Korumalar';

  @override
  String get catLaptop => 'Dizüstü bilgisayar';

  @override
  String get catPhone => 'Telefon';

  @override
  String get catHeadphones => 'Kulaklık';

  @override
  String get catTv => 'Televizyon';

  @override
  String get catAppliance => 'Beyaz eşya';

  @override
  String get catVacuum => 'Süpürge';

  @override
  String get catOther => 'Diğer';

  @override
  String get lifetime => 'Ömür boyu';

  @override
  String get fieldKind => 'Ne tür bir ürün?';

  @override
  String get kindHint => 'Fotoğraf yoksa rafta bu çizimle durur.';

  @override
  String kindA11y(String kind) {
    return '$kind, tür';
  }
}
