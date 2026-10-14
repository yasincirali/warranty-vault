import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My things'**
  String get appTitle;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get searchItems;

  /// No description provided for @attentionHeader.
  ///
  /// In en, this message translates to:
  /// **'Needs attention · {count}'**
  String attentionHeader(int count);

  /// No description provided for @allHeader.
  ///
  /// In en, this message translates to:
  /// **'All · {count}'**
  String allHeader(int count);

  /// No description provided for @addReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add receipt or invoice'**
  String get addReceipt;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first invoice and we\'ll track your rights.'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'We warn you before a period ends, and when something breaks we tell you what to do on one screen.'**
  String get emptyBody;

  /// No description provided for @endsIn.
  ///
  /// In en, this message translates to:
  /// **'{kind} ends in {days, plural, =0{today} =1{1 day} other{{days} days}}'**
  String endsIn(String kind, int days);

  /// No description provided for @kindReturn.
  ///
  /// In en, this message translates to:
  /// **'Return window'**
  String get kindReturn;

  /// No description provided for @kindReject.
  ///
  /// In en, this message translates to:
  /// **'30-day right to reject'**
  String get kindReject;

  /// No description provided for @kindManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer warranty'**
  String get kindManufacturer;

  /// No description provided for @kindExtended.
  ///
  /// In en, this message translates to:
  /// **'Extended warranty'**
  String get kindExtended;

  /// No description provided for @kindLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal right'**
  String get kindLegal;

  /// No description provided for @statusLine.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {remaining}'**
  String statusLine(String kind, String remaining);

  /// No description provided for @protectionEnded.
  ///
  /// In en, this message translates to:
  /// **'Protection ended'**
  String get protectionEnded;

  /// No description provided for @noFixedEnd.
  ///
  /// In en, this message translates to:
  /// **'No fixed end'**
  String get noFixedEnd;

  /// No description provided for @durYears.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 yr} other{{n} yrs}}'**
  String durYears(int n);

  /// No description provided for @durMonths.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 mo} other{{n} mo}}'**
  String durMonths(int n);

  /// No description provided for @durDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{today} =1{1 day} other{{n} days}}'**
  String durDays(int n);

  /// No description provided for @todayStatus.
  ///
  /// In en, this message translates to:
  /// **'Where you stand today'**
  String get todayStatus;

  /// No description provided for @answerReturn.
  ///
  /// In en, this message translates to:
  /// **'You can return it without giving a reason.'**
  String get answerReturn;

  /// No description provided for @answerReject.
  ///
  /// In en, this message translates to:
  /// **'If it\'s faulty you can reject it and get your money back.'**
  String get answerReject;

  /// No description provided for @answerManufacturer.
  ///
  /// In en, this message translates to:
  /// **'If it breaks, the manufacturer\'s service repairs it free of charge.'**
  String get answerManufacturer;

  /// No description provided for @answerExtended.
  ///
  /// In en, this message translates to:
  /// **'If it breaks, your extended warranty covers the repair.'**
  String get answerExtended;

  /// No description provided for @answerLegal.
  ///
  /// In en, this message translates to:
  /// **'Your legal right against the seller is still running. If it breaks, you can ask for a free repair or replacement.'**
  String get answerLegal;

  /// No description provided for @answerNone.
  ///
  /// In en, this message translates to:
  /// **'This item\'s protection has ended.'**
  String get answerNone;

  /// No description provided for @answerUnverified.
  ///
  /// In en, this message translates to:
  /// **'We haven\'t verified the legal rules for this country yet, so we only show the manufacturer warranty.'**
  String get answerUnverified;

  /// No description provided for @endsOn.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String endsOn(String date);

  /// No description provided for @endedOn.
  ///
  /// In en, this message translates to:
  /// **'Ended · {date}'**
  String endedOn(String date);

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get notVerified;

  /// No description provided for @whereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where does this period come from?'**
  String get whereFrom;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @serial.
  ///
  /// In en, this message translates to:
  /// **'Serial no.'**
  String get serial;

  /// No description provided for @problemButton.
  ///
  /// In en, this message translates to:
  /// **'Something\'s wrong'**
  String get problemButton;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

  /// No description provided for @issueDefect.
  ///
  /// In en, this message translates to:
  /// **'It doesn\'t work or is faulty'**
  String get issueDefect;

  /// No description provided for @issueDamaged.
  ///
  /// In en, this message translates to:
  /// **'It arrived damaged'**
  String get issueDamaged;

  /// No description provided for @issueNotAsDescribed.
  ///
  /// In en, this message translates to:
  /// **'It\'s not as described'**
  String get issueNotAsDescribed;

  /// No description provided for @issueLost.
  ///
  /// In en, this message translates to:
  /// **'Lost or stolen'**
  String get issueLost;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended next step'**
  String get recommended;

  /// No description provided for @adviceReturn.
  ///
  /// In en, this message translates to:
  /// **'Return it to {store}. You\'re within the return window, no reason needed.'**
  String adviceReturn(String store);

  /// No description provided for @adviceReject.
  ///
  /// In en, this message translates to:
  /// **'Reject it at {store} for a full refund. You\'re within the first 30 days.'**
  String adviceReject(String store);

  /// No description provided for @adviceSellerRepair.
  ///
  /// In en, this message translates to:
  /// **'Ask the seller ({store}) for a repair or replacement. Your legal right is running, so it should be free.'**
  String adviceSellerRepair(String store);

  /// No description provided for @proofSeller.
  ///
  /// In en, this message translates to:
  /// **'The seller has to prove the fault wasn\'t there from the start.'**
  String get proofSeller;

  /// No description provided for @proofBuyer.
  ///
  /// In en, this message translates to:
  /// **'At this stage you may need to show the fault was there from the start, so photos and video matter.'**
  String get proofBuyer;

  /// No description provided for @adviceManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Contact the manufacturer\'s service. Your warranty is still valid.'**
  String get adviceManufacturer;

  /// No description provided for @adviceCheckLocal.
  ///
  /// In en, this message translates to:
  /// **'Your country\'s consumer body can tell you what you\'re entitled to. We haven\'t verified these rules yet.'**
  String get adviceCheckLocal;

  /// No description provided for @adviceInsurance.
  ///
  /// In en, this message translates to:
  /// **'Guarantees don\'t cover loss or theft. Check your home or device insurance.'**
  String get adviceInsurance;

  /// No description provided for @adviceNotCovered.
  ///
  /// In en, this message translates to:
  /// **'This item isn\'t covered anymore. A paid repair or the manufacturer\'s goodwill are the remaining options.'**
  String get adviceNotCovered;

  /// No description provided for @stepDocsReady.
  ///
  /// In en, this message translates to:
  /// **'Invoice and serial number are ready'**
  String get stepDocsReady;

  /// No description provided for @stepAddEvidence.
  ///
  /// In en, this message translates to:
  /// **'Add a photo or video of the problem'**
  String get stepAddEvidence;

  /// No description provided for @stepWeDraft.
  ///
  /// In en, this message translates to:
  /// **'We write it in the seller\'s language; you read it in yours and send it'**
  String get stepWeDraft;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @isItRight.
  ///
  /// In en, this message translates to:
  /// **'Is this right?'**
  String get isItRight;

  /// No description provided for @readFromInvoice.
  ///
  /// In en, this message translates to:
  /// **'We read this from your invoice. Tap anything that\'s wrong.'**
  String get readFromInvoice;

  /// No description provided for @fieldProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get fieldProduct;

  /// No description provided for @fieldStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get fieldStore;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get fieldDate;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial no.'**
  String get fieldSerial;

  /// No description provided for @checkThis.
  ///
  /// In en, this message translates to:
  /// **'We\'re not sure, please check'**
  String get checkThis;

  /// No description provided for @countryNote.
  ///
  /// In en, this message translates to:
  /// **'Bought in {country}: your rights follow that country\'s rules.'**
  String countryNote(String country);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'For information only, not legal advice.'**
  String get disclaimer;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @ruleSemantics.
  ///
  /// In en, this message translates to:
  /// **'{p}% of the period has passed'**
  String ruleSemantics(int p);

  /// No description provided for @ruleProofMonth.
  ///
  /// In en, this message translates to:
  /// **'Month {n} · proof moves to you'**
  String ruleProofMonth(int n);

  /// No description provided for @rulesOf.
  ///
  /// In en, this message translates to:
  /// **'Rules: {country}'**
  String rulesOf(String country);

  /// No description provided for @regionDE.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get regionDE;

  /// No description provided for @regionEU.
  ///
  /// In en, this message translates to:
  /// **'EU'**
  String get regionEU;

  /// No description provided for @regionGB.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get regionGB;

  /// No description provided for @regionTR.
  ///
  /// In en, this message translates to:
  /// **'Türkiye'**
  String get regionTR;

  /// No description provided for @regionUS.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get regionUS;

  /// No description provided for @regionAU.
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get regionAU;

  /// No description provided for @showAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Show at the counter'**
  String get showAtCounter;

  /// No description provided for @counterTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of purchase'**
  String get counterTitle;

  /// No description provided for @counterRight.
  ///
  /// In en, this message translates to:
  /// **'{kind} until {date}.'**
  String counterRight(String kind, String date);

  /// No description provided for @counterAsk.
  ///
  /// In en, this message translates to:
  /// **'I\'m asking for a free repair or replacement.'**
  String get counterAsk;

  /// No description provided for @counterNoInvoice.
  ///
  /// In en, this message translates to:
  /// **'No invoice photo yet'**
  String get counterNoInvoice;

  /// No description provided for @adviceIfRefused.
  ///
  /// In en, this message translates to:
  /// **'If the seller refuses, we point you to the official consumer body and draft the complaint.'**
  String get adviceIfRefused;

  /// No description provided for @notVerifiedWhy.
  ///
  /// In en, this message translates to:
  /// **'We haven\'t checked this country\'s rule against an official source yet, so we don\'t show a period.'**
  String get notVerifiedWhy;

  /// No description provided for @wayPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photograph a receipt'**
  String get wayPhoto;

  /// No description provided for @wayPhotoWhy.
  ///
  /// In en, this message translates to:
  /// **'Paper receipts fade within months; the photo stays.'**
  String get wayPhotoWhy;

  /// No description provided for @wayPdf.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF invoice'**
  String get wayPdf;

  /// No description provided for @wayPdfWhy.
  ///
  /// In en, this message translates to:
  /// **'Invoices from online shops.'**
  String get wayPdfWhy;

  /// No description provided for @wayEmail.
  ///
  /// In en, this message translates to:
  /// **'Forward by email'**
  String get wayEmail;

  /// No description provided for @wayEmailWhy.
  ///
  /// In en, this message translates to:
  /// **'Every invoice you forward is added for you.'**
  String get wayEmailWhy;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll see'**
  String get previewTitle;

  /// No description provided for @previewBody.
  ///
  /// In en, this message translates to:
  /// **'A time rule for every item: how much has passed, how much is left, and when the burden of proof moves to you.'**
  String get previewBody;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{day left} other{days left}}'**
  String daysLeft(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
