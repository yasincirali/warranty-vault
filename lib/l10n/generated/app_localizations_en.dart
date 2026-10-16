// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My things';

  @override
  String get searchItems => 'Search items';

  @override
  String attentionHeader(int count) {
    return 'Needs attention · $count';
  }

  @override
  String allHeader(int count) {
    return 'All · $count';
  }

  @override
  String get addReceipt => 'Add receipt or invoice';

  @override
  String get emptyTitle =>
      'Add your first invoice and we\'ll track your rights.';

  @override
  String get emptyBody =>
      'We warn you before a period ends, and when something breaks we tell you what to do on one screen.';

  @override
  String endsIn(String kind, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'today',
    );
    return '$kind ends in $_temp0';
  }

  @override
  String get kindReturn => 'Return window';

  @override
  String get kindReject => '30-day right to reject';

  @override
  String get kindManufacturer => 'Manufacturer warranty';

  @override
  String get kindExtended => 'Extended warranty';

  @override
  String get kindLegal => 'Legal right';

  @override
  String statusLine(String kind, String remaining) {
    return '$kind · $remaining';
  }

  @override
  String get protectionEnded => 'Protection ended';

  @override
  String get noFixedEnd => 'No fixed end';

  @override
  String durYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n yrs',
      one: '1 yr',
    );
    return '$_temp0';
  }

  @override
  String durMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mo',
      one: '1 mo',
    );
    return '$_temp0';
  }

  @override
  String durDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get todayStatus => 'Where you stand today';

  @override
  String get answerReturn => 'You can return it without giving a reason.';

  @override
  String get answerReject =>
      'If it\'s faulty you can reject it and get your money back.';

  @override
  String get answerManufacturer =>
      'If it breaks, the manufacturer\'s service repairs it free of charge.';

  @override
  String get answerExtended =>
      'If it breaks, your extended warranty covers the repair.';

  @override
  String get answerLegal =>
      'Your legal right against the seller is still running. If it breaks, you can ask for a free repair or replacement.';

  @override
  String get answerNone => 'This item\'s protection has ended.';

  @override
  String get answerUnverified =>
      'We haven\'t verified the legal rules for this country yet, so we only show the manufacturer warranty.';

  @override
  String endsOn(String date) {
    return 'Until $date';
  }

  @override
  String endedOn(String date) {
    return 'Ended · $date';
  }

  @override
  String get notVerified => 'Not verified yet';

  @override
  String get whereFrom => 'Where does this period come from?';

  @override
  String get invoice => 'Invoice';

  @override
  String get serial => 'Serial no.';

  @override
  String get problemButton => 'Something\'s wrong';

  @override
  String get whatHappened => 'What happened?';

  @override
  String get issueDefect => 'It doesn\'t work or is faulty';

  @override
  String get issueDamaged => 'It arrived damaged';

  @override
  String get issueNotAsDescribed => 'It\'s not as described';

  @override
  String get issueLost => 'Lost or stolen';

  @override
  String get recommended => 'Recommended next step';

  @override
  String adviceReturn(String store) {
    return 'Return it to $store. You\'re within the return window, no reason needed.';
  }

  @override
  String adviceReject(String store) {
    return 'Reject it at $store for a full refund. You\'re within the first 30 days.';
  }

  @override
  String adviceSellerRepair(String store) {
    return 'Ask the seller ($store) for a repair or replacement. Your legal right is running, so it should be free.';
  }

  @override
  String get proofSeller =>
      'The seller has to prove the fault wasn\'t there from the start.';

  @override
  String get proofBuyer =>
      'At this stage you may need to show the fault was there from the start, so photos and video matter.';

  @override
  String get adviceManufacturer =>
      'Contact the manufacturer\'s service. Your warranty is still valid.';

  @override
  String get adviceCheckLocal =>
      'Your country\'s consumer body can tell you what you\'re entitled to. We haven\'t verified these rules yet.';

  @override
  String get adviceInsurance =>
      'Guarantees don\'t cover loss or theft. Check your home or device insurance.';

  @override
  String get adviceNotCovered =>
      'This item isn\'t covered anymore. A paid repair or the manufacturer\'s goodwill are the remaining options.';

  @override
  String get stepDocsReady => 'Invoice and serial number are ready';

  @override
  String get stepAddEvidence => 'Add a photo or video of the problem';

  @override
  String get stepWeDraft =>
      'We write it in the seller\'s language; you read it in yours and send it';

  @override
  String get continueButton => 'Continue';

  @override
  String get isItRight => 'Is this right?';

  @override
  String get readFromInvoice =>
      'We read this from your invoice. Tap anything that\'s wrong.';

  @override
  String get fieldProduct => 'Product';

  @override
  String get fieldStore => 'Store';

  @override
  String get fieldDate => 'Purchase date';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldSerial => 'Serial no.';

  @override
  String get checkThis => 'We\'re not sure, please check';

  @override
  String countryNote(String country) {
    return 'Bought in $country: your rights follow that country\'s rules.';
  }

  @override
  String get save => 'Save';

  @override
  String get retake => 'Retake';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get edit => 'Edit';

  @override
  String get disclaimer => 'For information only, not legal advice.';

  @override
  String get left => 'left';

  @override
  String ruleSemantics(int p) {
    return '$p% of the period has passed';
  }

  @override
  String ruleProofMonth(int n) {
    return 'Month $n · proof moves to you';
  }

  @override
  String rulesOf(String country) {
    return 'Rules: $country';
  }

  @override
  String get regionDE => 'Germany';

  @override
  String get regionEU => 'EU';

  @override
  String get regionGB => 'United Kingdom';

  @override
  String get regionTR => 'Türkiye';

  @override
  String get regionUS => 'United States';

  @override
  String get regionAU => 'Australia';

  @override
  String get showAtCounter => 'Show at the counter';

  @override
  String get counterTitle => 'Proof of purchase';

  @override
  String counterRight(String kind, String date) {
    return '$kind until $date.';
  }

  @override
  String get counterAsk => 'I\'m asking for a free repair or replacement.';

  @override
  String get counterNoInvoice => 'No invoice photo yet';

  @override
  String get adviceIfRefused =>
      'If the seller refuses, we point you to the official consumer body and draft the complaint.';

  @override
  String get notVerifiedWhy =>
      'We haven\'t checked this country\'s rule against an official source yet, so we don\'t show a period.';

  @override
  String get wayPhoto => 'Photograph a receipt';

  @override
  String get wayPhotoWhy =>
      'Paper receipts fade within months; the photo stays.';

  @override
  String get wayPdf => 'Choose a PDF invoice';

  @override
  String get wayPdfWhy => 'Invoices from online shops.';

  @override
  String get wayEmail => 'Forward by email';

  @override
  String get wayEmailWhy => 'Every invoice you forward is added for you.';

  @override
  String get previewTitle => 'What you\'ll see';

  @override
  String get previewBody =>
      'A time rule for every item: how much has passed, how much is left, and when the burden of proof moves to you.';

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'days left',
      one: 'day left',
    );
    return '$_temp0';
  }

  @override
  String cabinetCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things on your shelves',
      one: '1 thing on your shelves',
    );
    return '$_temp0';
  }

  @override
  String get cabinetHint =>
      'Drag to another shelf. Flick sideways to throw out.';

  @override
  String get addItem => 'Add a product';

  @override
  String get shelfLabelHint => '+ Label';

  @override
  String shelfName(int n) {
    return 'Shelf $n';
  }

  @override
  String shelfLabelA11y(int n, String label) {
    return 'Shelf $n label: $label. Double tap to edit.';
  }

  @override
  String shelfNoLabelA11y(int n) {
    return 'Shelf $n has no label. Double tap to add one.';
  }

  @override
  String itemA11y(String name, String status, String shelf) {
    return '$name. $status. $shelf.';
  }

  @override
  String get moveUp => 'Move to the shelf above';

  @override
  String get moveDown => 'Move to the shelf below';

  @override
  String get throwOut => 'Throw out';

  @override
  String thrownOut(String name) {
    return '$name is out of the cabinet';
  }

  @override
  String get undo => 'Undo';

  @override
  String disposedHeader(int count) {
    return 'Thrown out · $count';
  }

  @override
  String get putBack => 'Put back';

  @override
  String get wayCamera => 'Photograph the product';

  @override
  String get wayCameraWhy =>
      'We lift it off the background and stand it on a shelf.';

  @override
  String get wayGallery => 'Choose from your photos';

  @override
  String get wayGalleryWhy => 'A product photo you already have works too.';

  @override
  String get waySample => 'Load a sample cabinet';

  @override
  String get waySampleWhy => 'Try the shelves with six sample products first.';

  @override
  String get emptyCabinetTitle => 'Put the things you bought on your shelves.';

  @override
  String get emptyCabinetBody =>
      'Each one keeps its receipt and its rights. We warn you before a period ends.';

  @override
  String get sampleDesk => 'Desk';

  @override
  String get sampleLiving => 'Living room';

  @override
  String get sampleKitchen => 'Kitchen';

  @override
  String get addTitle => 'New product';

  @override
  String get photoCamera => 'Camera';

  @override
  String get photoGallery => 'Photos';

  @override
  String get photoOptional =>
      'A photo is optional, but it is how you will spot it on the shelf.';

  @override
  String get loading => 'Loading';

  @override
  String get lifting => 'Lifting it off the background…';

  @override
  String get photoCutout => 'Cut out';

  @override
  String get photoOriginal => 'Original';

  @override
  String get photoChange => 'Change photo';

  @override
  String get photoFailed => 'That photo couldn\'t be read. Try another one.';

  @override
  String get photoNoCutout =>
      'The background wasn\'t clear enough to lift, so the photo stays as it is.';

  @override
  String get fieldChannel => 'Where did you buy it?';

  @override
  String get channelStore => 'In a store';

  @override
  String get channelOnline => 'Online';

  @override
  String get fieldRegion => 'Country of purchase';

  @override
  String get warrantyNone => 'None';

  @override
  String get fieldShelf => 'Shelf';

  @override
  String get shelfAuto => 'First shelf with room';

  @override
  String get putOnShelf => 'Put it on the shelf';

  @override
  String get nameHint => 'e.g. Coffee machine';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get langTr => 'Türkçe';

  @override
  String get langEn => 'English';

  @override
  String get settingsRegion => 'Country';

  @override
  String get regionSystem => 'Phone\'s country';

  @override
  String get settingsRegionHint =>
      'New products are judged by this country\'s rules. You can still change it for each product.';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutLocal =>
      'Your cabinet and photos are stored on this phone. No account needed.';

  @override
  String amountPreview(String amount) {
    return 'Will be saved as $amount';
  }

  @override
  String get amountUnreadable => 'Couldn\'t read the amount; use digits.';

  @override
  String get settingsExport => 'Export';

  @override
  String get exportPdf => 'PDF report';

  @override
  String get exportPdfWhy =>
      'To print or keep: every product with its protections and dates.';

  @override
  String get exportExcel => 'Excel spreadsheet';

  @override
  String get exportExcelWhy =>
      'To sort and filter: one row per product, dates as real dates.';

  @override
  String exportPreparing(String format) {
    return 'Preparing $format';
  }

  @override
  String get exportFailed => 'Couldn\'t create the file. Try again.';

  @override
  String get exportEmpty => 'Nothing to export yet. Add a product first.';

  @override
  String get exportHint =>
      'The file is created on this phone; you choose where it goes.';

  @override
  String get exportTitle => 'Inventory';

  @override
  String get exportFileName => 'inventory';

  @override
  String exportAsOf(String date) {
    return 'As of $date';
  }

  @override
  String get exportItems => 'Products';

  @override
  String get exportTotal => 'Total paid';

  @override
  String get exportSoon => 'Ending within 30 days';

  @override
  String get exportNone => 'None';

  @override
  String get exportAttention => 'Needs attention';

  @override
  String get exportAttentionWhy =>
      'These protections end within 30 days. Act before the date if something is wrong.';

  @override
  String get exportUnlabelled => 'Unlabelled shelf';

  @override
  String exportPage(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get exportStatusActive => 'Active';

  @override
  String get exportStatusEnded => 'Ended';

  @override
  String exportDaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days left',
      one: '1 day left',
      zero: 'ends today',
    );
    return '$_temp0';
  }

  @override
  String exportProofUntil(String date) {
    return 'Seller must prove until $date';
  }

  @override
  String get exportNoProtection => 'No protection on record';

  @override
  String get exportLegend =>
      'Bar: time since purchase. Ring: today. Tick: the day the burden of proof moves to you. Amber: ends within 30 days.';

  @override
  String get colShelf => 'Shelf';

  @override
  String get colProduct => 'Product';

  @override
  String get colCategory => 'Category';

  @override
  String get colStore => 'Store';

  @override
  String get colChannel => 'Bought';

  @override
  String get colCountry => 'Country';

  @override
  String get colPurchased => 'Purchase date';

  @override
  String get colPrice => 'Amount';

  @override
  String get colCurrency => 'Currency';

  @override
  String get colSerial => 'Serial number';

  @override
  String get colNext => 'Ends next';

  @override
  String get colNextEnd => 'Ends on';

  @override
  String get colDaysLeft => 'Days left';

  @override
  String get colProofEnd => 'Seller proves until';

  @override
  String colEnds(String kind) {
    return '$kind ends';
  }

  @override
  String get colProtection => 'Protection';

  @override
  String get colStart => 'Starts';

  @override
  String get colEnd => 'Ends';

  @override
  String get colStatus => 'Status';

  @override
  String get colSources => 'Source';

  @override
  String get colDisposed => 'Thrown out on';

  @override
  String get sheetDisposed => 'Thrown out';

  @override
  String get sheetProtections => 'Protections';

  @override
  String get catLaptop => 'Laptop';

  @override
  String get catPhone => 'Phone';

  @override
  String get catHeadphones => 'Headphones';

  @override
  String get catTv => 'TV';

  @override
  String get catAppliance => 'Appliance';

  @override
  String get catVacuum => 'Vacuum';

  @override
  String get catOther => 'Other';

  @override
  String get lifetime => 'Lifetime';

  @override
  String get fieldKind => 'What kind of product?';

  @override
  String get kindHint =>
      'Without a photo, it stands on the shelf as this drawing.';

  @override
  String kindA11y(String kind) {
    return '$kind, kind';
  }

  @override
  String get hideKeyboard => 'Hide keyboard';

  @override
  String reminderEndsBody(String what) {
    return '$what. If something is wrong, report it before the last day.';
  }

  @override
  String reminderProofBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'In $_temp0 the burden of proving a fault moves to you. Report any problem now.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Product, store, serial or shelf';

  @override
  String get searchClear => 'Clear search';

  @override
  String searchNone(String query) {
    return 'Nothing in the cabinet matches “$query”.';
  }

  @override
  String get docsHeader => 'Receipts and papers';

  @override
  String get docReceipt => 'Receipt or invoice';

  @override
  String get docWarrantyCard => 'Warranty card';

  @override
  String get docManual => 'Manual';

  @override
  String get docOther => 'Other paper';

  @override
  String get docPdf => 'PDF';

  @override
  String get docPhoto => 'Photo';

  @override
  String get docAdd => 'Add a receipt or paper';

  @override
  String get docAddWhy =>
      'The seller asks for proof of purchase. Keep it here and it never fades.';

  @override
  String get docWhat => 'What is it?';

  @override
  String get docFromCamera => 'Take a photo';

  @override
  String get docFromGallery => 'Choose from photos';

  @override
  String get docFromFile => 'PDF file (e-invoice)';

  @override
  String docAdded(String kind) {
    return '$kind saved';
  }

  @override
  String get docTooLarge => 'That file is over 20 MB. Try a smaller copy.';

  @override
  String get docFailed => 'Couldn\'t save it. Try again.';

  @override
  String get docDelete => 'Delete';

  @override
  String docDeleteTitle(String kind) {
    return 'Delete $kind?';
  }

  @override
  String get docDeleteBody =>
      'It is removed from this phone. The product stays in the cabinet.';

  @override
  String get counterOpenPdf => 'Open the invoice (PDF)';

  @override
  String get counterReceiptA11y => 'Receipt, opens full screen';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get remindersSwitch => 'Remind me before rights end';

  @override
  String get remindersWhy =>
      'A few days before a return window closes, a month before a warranty ends, and before the burden of proof moves to you. Sent from this phone only.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get backupMake => 'Back up the cabinet';

  @override
  String get backupMakeWhy => 'Every product, photo and receipt in one file';

  @override
  String get backupRestore => 'Restore from a backup';

  @override
  String get backupRestoreWhy => 'Replaces the cabinet on this phone';

  @override
  String get backupHint =>
      'Save the file to iCloud Drive or Files. It is a plain zip you can open on a computer, so keep it somewhere private.';

  @override
  String get backupFilePrefix => 'cabinet-backup';

  @override
  String get backupInvalid => 'That file is not a cabinet backup.';

  @override
  String get backupFailed => 'The backup couldn\'t be completed. Try again.';

  @override
  String backupConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restore $count products?',
      one: 'Restore 1 product?',
    );
    return '$_temp0';
  }

  @override
  String backupFrom(String date) {
    return 'Backup from $date.';
  }

  @override
  String backupConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count products on this phone will be replaced.',
      one: 'The 1 product on this phone will be replaced.',
      zero: 'The cabinet on this phone is empty.',
    );
    return '$_temp0';
  }

  @override
  String get backupReplace => 'Restore';

  @override
  String backupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products restored',
      one: '1 product restored',
    );
    return '$_temp0';
  }
}
