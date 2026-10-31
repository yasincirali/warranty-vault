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

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first invoice and we\'ll track your rights.'**
  String get emptyTitle;

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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

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
  /// **'Worked out with {country} rules'**
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

  /// No description provided for @adviceIfRefused.
  ///
  /// In en, this message translates to:
  /// **'If the seller refuses, you can turn to your country\'s official consumer body; your receipt and photos are ready here.'**
  String get adviceIfRefused;

  /// No description provided for @notVerifiedWhy.
  ///
  /// In en, this message translates to:
  /// **'We haven\'t checked this country\'s rule against an official source yet, so we don\'t show a period.'**
  String get notVerifiedWhy;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{day left} other{days left}}'**
  String daysLeft(int n);

  /// No description provided for @cabinetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing on your shelves} other{{count} things on your shelves}}'**
  String cabinetCount(int count);

  /// No description provided for @cabinetHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to another shelf. Flick sideways to throw out.'**
  String get cabinetHint;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add a product'**
  String get addItem;

  /// No description provided for @shelfLabelHint.
  ///
  /// In en, this message translates to:
  /// **'+ Label'**
  String get shelfLabelHint;

  /// No description provided for @shelfName.
  ///
  /// In en, this message translates to:
  /// **'Shelf {n}'**
  String shelfName(int n);

  /// No description provided for @shelfLabelA11y.
  ///
  /// In en, this message translates to:
  /// **'Shelf {n} label: {label}. Double tap to edit.'**
  String shelfLabelA11y(int n, String label);

  /// No description provided for @shelfNoLabelA11y.
  ///
  /// In en, this message translates to:
  /// **'Shelf {n} has no label. Double tap to add one.'**
  String shelfNoLabelA11y(int n);

  /// No description provided for @itemA11y.
  ///
  /// In en, this message translates to:
  /// **'{name}. {status}. {shelf}.'**
  String itemA11y(String name, String status, String shelf);

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move to the shelf above'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move to the shelf below'**
  String get moveDown;

  /// No description provided for @throwOut.
  ///
  /// In en, this message translates to:
  /// **'Throw out'**
  String get throwOut;

  /// No description provided for @thrownOut.
  ///
  /// In en, this message translates to:
  /// **'{name} is out of the cabinet'**
  String thrownOut(String name);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @disposedHeader.
  ///
  /// In en, this message translates to:
  /// **'Thrown out · {count}'**
  String disposedHeader(int count);

  /// No description provided for @putBack.
  ///
  /// In en, this message translates to:
  /// **'Put back'**
  String get putBack;

  /// No description provided for @samplesNote.
  ///
  /// In en, this message translates to:
  /// **'These are sample products. They send no reminders.'**
  String get samplesNote;

  /// No description provided for @samplesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove samples'**
  String get samplesRemove;

  /// No description provided for @sampleTag.
  ///
  /// In en, this message translates to:
  /// **'Sample product · no reminders'**
  String get sampleTag;

  /// No description provided for @sampleTry.
  ///
  /// In en, this message translates to:
  /// **'Try the sample shelves'**
  String get sampleTry;

  /// No description provided for @emptyCabinetTitle.
  ///
  /// In en, this message translates to:
  /// **'Put the things you bought on your shelves.'**
  String get emptyCabinetTitle;

  /// No description provided for @emptyCabinetBody.
  ///
  /// In en, this message translates to:
  /// **'Each one keeps its receipt and its rights. We warn you before a period ends.'**
  String get emptyCabinetBody;

  /// No description provided for @sampleDesk.
  ///
  /// In en, this message translates to:
  /// **'Desk'**
  String get sampleDesk;

  /// No description provided for @sampleLiving.
  ///
  /// In en, this message translates to:
  /// **'Living room'**
  String get sampleLiving;

  /// No description provided for @sampleKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get sampleKitchen;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get addTitle;

  /// No description provided for @photoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get photoCamera;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photoGallery;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @lifting.
  ///
  /// In en, this message translates to:
  /// **'Lifting it off the background…'**
  String get lifting;

  /// No description provided for @photoCutout.
  ///
  /// In en, this message translates to:
  /// **'Cut out'**
  String get photoCutout;

  /// No description provided for @photoOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get photoOriginal;

  /// No description provided for @photoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get photoChange;

  /// No description provided for @photoFailed.
  ///
  /// In en, this message translates to:
  /// **'That photo couldn\'t be read. Try another one.'**
  String get photoFailed;

  /// No description provided for @photoNoCutout.
  ///
  /// In en, this message translates to:
  /// **'The background wasn\'t clear enough to lift, so the photo stays as it is.'**
  String get photoNoCutout;

  /// No description provided for @fieldChannel.
  ///
  /// In en, this message translates to:
  /// **'Where did you buy it?'**
  String get fieldChannel;

  /// No description provided for @channelStore.
  ///
  /// In en, this message translates to:
  /// **'In a store'**
  String get channelStore;

  /// No description provided for @channelOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get channelOnline;

  /// No description provided for @fieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Country of purchase'**
  String get fieldRegion;

  /// No description provided for @warrantyNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get warrantyNone;

  /// No description provided for @fieldShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get fieldShelf;

  /// No description provided for @shelfAuto.
  ///
  /// In en, this message translates to:
  /// **'First shelf with room'**
  String get shelfAuto;

  /// No description provided for @putOnShelf.
  ///
  /// In en, this message translates to:
  /// **'Put it on the shelf'**
  String get putOnShelf;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee machine'**
  String get nameHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @langTr.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get langTr;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @settingsRegion.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get settingsRegion;

  /// No description provided for @regionSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s country'**
  String get regionSystem;

  /// No description provided for @settingsRegionHint.
  ///
  /// In en, this message translates to:
  /// **'New products are judged by this country\'s rules. You can still change it for each product.'**
  String get settingsRegionHint;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutLocalIos.
  ///
  /// In en, this message translates to:
  /// **'Your cabinet and photos are stored on this phone. No account needed. If your iPhone\'s iCloud Backup is on, your cabinet is backed up with it.'**
  String get aboutLocalIos;

  /// No description provided for @backupLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup file: {date}'**
  String backupLast(String date);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'You have {count} products and no backup yet. If you change phones, this file is what brings them back.'**
  String backupNever(int count);

  /// No description provided for @nameMissing.
  ///
  /// In en, this message translates to:
  /// **'Write the product\'s name.'**
  String get nameMissing;

  /// No description provided for @aboutLocal.
  ///
  /// In en, this message translates to:
  /// **'Your cabinet and photos are stored on this phone. No account needed.'**
  String get aboutLocal;

  /// No description provided for @amountPreview.
  ///
  /// In en, this message translates to:
  /// **'Will be saved as {amount}'**
  String amountPreview(String amount);

  /// No description provided for @amountUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the amount; use digits.'**
  String get amountUnreadable;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExport;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get exportPdf;

  /// No description provided for @exportPdfWhy.
  ///
  /// In en, this message translates to:
  /// **'To print or keep: every product with its protections and dates.'**
  String get exportPdfWhy;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel spreadsheet'**
  String get exportExcel;

  /// No description provided for @exportExcelWhy.
  ///
  /// In en, this message translates to:
  /// **'To sort and filter: one row per product, dates as real dates.'**
  String get exportExcelWhy;

  /// No description provided for @exportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing {format}'**
  String exportPreparing(String format);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the file. Try again.'**
  String get exportFailed;

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet. Add a product first.'**
  String get exportEmpty;

  /// No description provided for @exportHint.
  ///
  /// In en, this message translates to:
  /// **'The file is created on this phone; you choose where it goes.'**
  String get exportHint;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get exportTitle;

  /// No description provided for @exportFileName.
  ///
  /// In en, this message translates to:
  /// **'inventory'**
  String get exportFileName;

  /// No description provided for @exportAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of {date}'**
  String exportAsOf(String date);

  /// No description provided for @exportItems.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get exportItems;

  /// No description provided for @exportTotal.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get exportTotal;

  /// No description provided for @exportAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get exportAttention;

  /// No description provided for @exportAttentionWhy.
  ///
  /// In en, this message translates to:
  /// **'These protections end within 30 days. Act before the date if something is wrong.'**
  String get exportAttentionWhy;

  /// No description provided for @exportUnlabelled.
  ///
  /// In en, this message translates to:
  /// **'Unlabelled shelf'**
  String get exportUnlabelled;

  /// No description provided for @exportPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String exportPage(int page, int pages);

  /// No description provided for @exportStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get exportStatusActive;

  /// No description provided for @exportStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get exportStatusEnded;

  /// No description provided for @exportDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{ends today} =1{1 day left} other{{n} days left}}'**
  String exportDaysLeft(int n);

  /// No description provided for @exportProofUntil.
  ///
  /// In en, this message translates to:
  /// **'Seller must prove until {date}'**
  String exportProofUntil(String date);

  /// No description provided for @exportNoProtection.
  ///
  /// In en, this message translates to:
  /// **'No protection on record'**
  String get exportNoProtection;

  /// No description provided for @exportLegend.
  ///
  /// In en, this message translates to:
  /// **'Bars: all of a product\'s protections on one timeline, from purchase to the latest end. Dark part: time passed. Ring: today. Tick: the day the burden of proof moves to you. Amber: ends within 30 days.'**
  String get exportLegend;

  /// No description provided for @colShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get colShelf;

  /// No description provided for @colProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get colProduct;

  /// No description provided for @colCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get colCategory;

  /// No description provided for @colStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get colStore;

  /// No description provided for @colChannel.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get colChannel;

  /// No description provided for @colCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get colCountry;

  /// No description provided for @colPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get colPurchased;

  /// No description provided for @colPrice.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get colPrice;

  /// No description provided for @colCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get colCurrency;

  /// No description provided for @colSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get colSerial;

  /// No description provided for @colNext.
  ///
  /// In en, this message translates to:
  /// **'Ends next'**
  String get colNext;

  /// No description provided for @colNextEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get colNextEnd;

  /// No description provided for @colDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get colDaysLeft;

  /// No description provided for @colProofEnd.
  ///
  /// In en, this message translates to:
  /// **'Seller proves until'**
  String get colProofEnd;

  /// No description provided for @colEnds.
  ///
  /// In en, this message translates to:
  /// **'{kind} ends'**
  String colEnds(String kind);

  /// No description provided for @colProtection.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get colProtection;

  /// No description provided for @colStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get colStart;

  /// No description provided for @colEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get colEnd;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @colSources.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get colSources;

  /// No description provided for @colDisposed.
  ///
  /// In en, this message translates to:
  /// **'Thrown out on'**
  String get colDisposed;

  /// No description provided for @sheetDisposed.
  ///
  /// In en, this message translates to:
  /// **'Thrown out'**
  String get sheetDisposed;

  /// No description provided for @sheetProtections.
  ///
  /// In en, this message translates to:
  /// **'Protections'**
  String get sheetProtections;

  /// No description provided for @catLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get catLaptop;

  /// No description provided for @catPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get catPhone;

  /// No description provided for @catHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get catHeadphones;

  /// No description provided for @catTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get catTv;

  /// No description provided for @catAppliance.
  ///
  /// In en, this message translates to:
  /// **'Appliance'**
  String get catAppliance;

  /// No description provided for @catVacuum.
  ///
  /// In en, this message translates to:
  /// **'Vacuum'**
  String get catVacuum;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @fieldKind.
  ///
  /// In en, this message translates to:
  /// **'What kind of product?'**
  String get fieldKind;

  /// No description provided for @kindHint.
  ///
  /// In en, this message translates to:
  /// **'Without a photo, it stands on the shelf as this drawing.'**
  String get kindHint;

  /// No description provided for @kindFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'We guessed the kind from the photo; tap the right one if it\'s wrong.'**
  String get kindFromPhoto;

  /// No description provided for @kindA11y.
  ///
  /// In en, this message translates to:
  /// **'{kind}, kind'**
  String kindA11y(String kind);

  /// No description provided for @hideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get hideKeyboard;

  /// No description provided for @reminderEndsBody.
  ///
  /// In en, this message translates to:
  /// **'{what}. If something is wrong, report it before the last day.'**
  String reminderEndsBody(String what);

  /// No description provided for @reminderProofBody.
  ///
  /// In en, this message translates to:
  /// **'In {days, plural, =1{1 day} other{{days} days}} the burden of proving a fault moves to you. Report any problem now.'**
  String reminderProofBody(int days);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Product, store, serial or shelf'**
  String get searchHint;

  /// No description provided for @searchSoonest.
  ///
  /// In en, this message translates to:
  /// **'Ending soonest first'**
  String get searchSoonest;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @searchNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the cabinet matches “{query}”.'**
  String searchNone(String query);

  /// No description provided for @docsHeader.
  ///
  /// In en, this message translates to:
  /// **'Receipts and papers'**
  String get docsHeader;

  /// No description provided for @docReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt or invoice'**
  String get docReceipt;

  /// No description provided for @docWarrantyCard.
  ///
  /// In en, this message translates to:
  /// **'Warranty card'**
  String get docWarrantyCard;

  /// No description provided for @docManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get docManual;

  /// No description provided for @docOther.
  ///
  /// In en, this message translates to:
  /// **'Other paper'**
  String get docOther;

  /// No description provided for @docPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get docPdf;

  /// No description provided for @docPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get docPhoto;

  /// No description provided for @docAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a receipt or paper'**
  String get docAdd;

  /// No description provided for @docAddWhy.
  ///
  /// In en, this message translates to:
  /// **'The seller asks for proof of purchase. Keep it here and it never fades.'**
  String get docAddWhy;

  /// No description provided for @docWhat.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get docWhat;

  /// No description provided for @docFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get docFromCamera;

  /// No description provided for @docFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get docFromGallery;

  /// No description provided for @docFromFile.
  ///
  /// In en, this message translates to:
  /// **'PDF file (e-invoice)'**
  String get docFromFile;

  /// No description provided for @docAdded.
  ///
  /// In en, this message translates to:
  /// **'{kind} saved'**
  String docAdded(String kind);

  /// No description provided for @docTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is over 20 MB. Try a smaller copy.'**
  String get docTooLarge;

  /// No description provided for @docFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save it. Try again.'**
  String get docFailed;

  /// No description provided for @docDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get docDelete;

  /// No description provided for @docDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {kind}?'**
  String docDeleteTitle(String kind);

  /// No description provided for @docDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It is removed from this phone. The product stays in the cabinet.'**
  String get docDeleteBody;

  /// No description provided for @counterOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Open the invoice (PDF)'**
  String get counterOpenPdf;

  /// No description provided for @counterReceiptA11y.
  ///
  /// In en, this message translates to:
  /// **'Receipt, opens full screen'**
  String get counterReceiptA11y;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// No description provided for @remindersSwitch.
  ///
  /// In en, this message translates to:
  /// **'Remind me before rights end'**
  String get remindersSwitch;

  /// No description provided for @remindersWhy.
  ///
  /// In en, this message translates to:
  /// **'A few days before a return window closes, a month before a warranty ends, and before the burden of proof moves to you. Sent from this phone only.'**
  String get remindersWhy;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @backupMake.
  ///
  /// In en, this message translates to:
  /// **'Back up the cabinet'**
  String get backupMake;

  /// No description provided for @backupMakeWhy.
  ///
  /// In en, this message translates to:
  /// **'Every product, photo and receipt in one file'**
  String get backupMakeWhy;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get backupRestore;

  /// No description provided for @backupRestoreWhy.
  ///
  /// In en, this message translates to:
  /// **'Replaces the cabinet on this phone'**
  String get backupRestoreWhy;

  /// No description provided for @backupHint.
  ///
  /// In en, this message translates to:
  /// **'Save the file to iCloud Drive or Files. It is a plain zip you can open on a computer, so keep it somewhere private.'**
  String get backupHint;

  /// No description provided for @backupFilePrefix.
  ///
  /// In en, this message translates to:
  /// **'cabinet-backup'**
  String get backupFilePrefix;

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'That file is not a cabinet backup.'**
  String get backupInvalid;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup couldn\'t be completed. Try again.'**
  String get backupFailed;

  /// No description provided for @backupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Restore 1 product?} other{Restore {count} products?}}'**
  String backupConfirmTitle(int count);

  /// No description provided for @backupFrom.
  ///
  /// In en, this message translates to:
  /// **'Backup from {date}.'**
  String backupFrom(String date);

  /// No description provided for @backupConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{The cabinet on this phone is empty.} =1{The 1 product on this phone will be replaced.} other{The {count} products on this phone will be replaced.}}'**
  String backupConfirmBody(int count);

  /// No description provided for @backupReplace.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupReplace;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product restored} other{{count} products restored}}'**
  String backupRestored(int count);

  /// No description provided for @receiptAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Add its receipt too?'**
  String get receiptAskTitle;

  /// No description provided for @receiptAskBody.
  ///
  /// In en, this message translates to:
  /// **'The seller asks for proof of purchase. Paper receipts fade within months; a photo here doesn\'t.'**
  String get receiptAskBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @notifyAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind you before it ends?'**
  String get notifyAskTitle;

  /// No description provided for @notifyAskBody.
  ///
  /// In en, this message translates to:
  /// **'A notification before a return window or warranty ends, and when it is time to report a fault. Nothing else.'**
  String get notifyAskBody;

  /// No description provided for @notifyAskFirst.
  ///
  /// In en, this message translates to:
  /// **'First one for this product: {date}'**
  String notifyAskFirst(String date);

  /// No description provided for @notifyAskYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, remind me'**
  String get notifyAskYes;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @notifyOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in the phone\'s settings. Reminders won\'t arrive.'**
  String get notifyOff;

  /// No description provided for @notifyNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t allowed yet. Reminders won\'t arrive.'**
  String get notifyNotAsked;

  /// No description provided for @notifyOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notifyOpenSettings;

  /// No description provided for @notifyAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notifyAllow;

  /// No description provided for @notifyOffItem.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so this product\'s reminders won\'t arrive.'**
  String get notifyOffItem;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editTitle;

  /// No description provided for @sourcesBody.
  ///
  /// In en, this message translates to:
  /// **'This period comes from the consumer rules of {region}. Source:'**
  String sourcesBody(String region);

  /// No description provided for @stepEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photograph the problem and keep it with the product\'s papers'**
  String get stepEvidence;

  /// No description provided for @stepEvidenceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the problem'**
  String get stepEvidenceAdd;

  /// No description provided for @stepEvidenceButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get stepEvidenceButton;

  /// No description provided for @stepEvidenceDone.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 photo added} other{{n} photos added}}'**
  String stepEvidenceDone(int n);

  /// No description provided for @stepShowProof.
  ///
  /// In en, this message translates to:
  /// **'Open your receipt with \"Show at the counter\" and show it to the seller'**
  String get stepShowProof;

  /// No description provided for @sourceOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get sourceOpenFailed;

  /// No description provided for @counterTitleNoProof.
  ///
  /// In en, this message translates to:
  /// **'Purchase details'**
  String get counterTitleNoProof;

  /// No description provided for @counterAddProof.
  ///
  /// In en, this message translates to:
  /// **'Add the receipt or invoice'**
  String get counterAddProof;

  /// No description provided for @counterProofHint.
  ///
  /// In en, this message translates to:
  /// **'No receipt? A bank statement or an order email also shows the purchase.'**
  String get counterProofHint;

  /// No description provided for @storeSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Store suggestion: {store}'**
  String storeSuggestion(String store);
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
