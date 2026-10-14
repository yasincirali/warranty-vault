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
  String get emptyTitle => 'Henüz bir şey yok';

  @override
  String get emptyBody =>
      'Fişin fotoğrafını çek ya da fatura e-postasını ilet. Okuyup neyle korunduğunu söyleriz.';

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
  String get stepWeDraft => 'Mesajı biz hazırlarız, sen gönderirsin';

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
}
