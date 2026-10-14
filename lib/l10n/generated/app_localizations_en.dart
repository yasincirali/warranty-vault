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
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptyBody =>
      'Photograph a receipt or forward an invoice email. We read it and tell you what you\'re covered for.';

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
  String get stepWeDraft => 'We draft the message, you send it';

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
}
