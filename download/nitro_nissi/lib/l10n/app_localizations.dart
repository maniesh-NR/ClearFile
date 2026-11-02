import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @navMyReturn.
  ///
  /// In en, this message translates to:
  /// **'My return'**
  String get navMyReturn;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get navAssistant;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @refundEstimate.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundEstimate;

  /// No description provided for @oweEstimate.
  ///
  /// In en, this message translates to:
  /// **'Owe'**
  String get oweEstimate;

  /// No description provided for @topicsHeader.
  ///
  /// In en, this message translates to:
  /// **'Let\'s finish your return'**
  String get topicsHeader;

  /// No description provided for @topicsSubheader.
  ///
  /// In en, this message translates to:
  /// **'Work through each topic. You can jump around anytime — your answers save automatically.'**
  String get topicsSubheader;

  /// No description provided for @issuesFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item needs attention before filing} other{{count} items need attention before filing}}'**
  String issuesFound(int count);

  /// No description provided for @issuesFoundInfo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 suggestion for your review} other{{count} suggestions for your review}}'**
  String issuesFoundInfo(int count);

  /// No description provided for @continueToReview.
  ///
  /// In en, this message translates to:
  /// **'Continue to review'**
  String get continueToReview;

  /// No description provided for @jumpToResults.
  ///
  /// In en, this message translates to:
  /// **'Jump to my estimate'**
  String get jumpToResults;

  /// No description provided for @autosaveNote.
  ///
  /// In en, this message translates to:
  /// **'Autosaved to {name}'**
  String autosaveNote(String name);

  /// No description provided for @whyWeAsk.
  ///
  /// In en, this message translates to:
  /// **'Why do we ask?'**
  String get whyWeAsk;

  /// No description provided for @topicStep.
  ///
  /// In en, this message translates to:
  /// **'Step {a} of {b}'**
  String topicStep(int a, int b);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @seeResults.
  ///
  /// In en, this message translates to:
  /// **'See my results'**
  String get seeResults;

  /// No description provided for @topicPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get topicPersonal;

  /// No description provided for @topicIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get topicIncome;

  /// No description provided for @topicDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions & adjustments'**
  String get topicDeductions;

  /// No description provided for @topicCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits & payments'**
  String get topicCredits;

  /// No description provided for @pagePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get pagePersonalInfo;

  /// No description provided for @pageSpouse.
  ///
  /// In en, this message translates to:
  /// **'Your spouse'**
  String get pageSpouse;

  /// No description provided for @pageDependents.
  ///
  /// In en, this message translates to:
  /// **'Dependents'**
  String get pageDependents;

  /// No description provided for @pageW2.
  ///
  /// In en, this message translates to:
  /// **'W-2 wages'**
  String get pageW2;

  /// No description provided for @pageInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest income'**
  String get pageInterest;

  /// No description provided for @pageDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends'**
  String get pageDividends;

  /// No description provided for @pageCapGains.
  ///
  /// In en, this message translates to:
  /// **'Investment sales'**
  String get pageCapGains;

  /// No description provided for @pageSelfEmployment.
  ///
  /// In en, this message translates to:
  /// **'Self-employment'**
  String get pageSelfEmployment;

  /// No description provided for @pageRetirement.
  ///
  /// In en, this message translates to:
  /// **'Retirement distributions'**
  String get pageRetirement;

  /// No description provided for @pageOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get pageOtherIncome;

  /// No description provided for @pageDeductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get pageDeductions;

  /// No description provided for @pageCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get pageCredits;

  /// No description provided for @secYourInfo.
  ///
  /// In en, this message translates to:
  /// **'Your information'**
  String get secYourInfo;

  /// No description provided for @secFilingStatus.
  ///
  /// In en, this message translates to:
  /// **'Filing status'**
  String get secFilingStatus;

  /// No description provided for @secSpouseInfo.
  ///
  /// In en, this message translates to:
  /// **'Spouse information'**
  String get secSpouseInfo;

  /// No description provided for @secSocialSecurity.
  ///
  /// In en, this message translates to:
  /// **'Social Security benefits'**
  String get secSocialSecurity;

  /// No description provided for @secUnemployment.
  ///
  /// In en, this message translates to:
  /// **'Unemployment compensation'**
  String get secUnemployment;

  /// No description provided for @secOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get secOtherIncome;

  /// No description provided for @secObbba.
  ///
  /// In en, this message translates to:
  /// **'2025 special deductions'**
  String get secObbba;

  /// No description provided for @secItemized.
  ///
  /// In en, this message translates to:
  /// **'Itemized deductions (optional)'**
  String get secItemized;

  /// No description provided for @secAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjustments to income'**
  String get secAdjustments;

  /// No description provided for @secChildCare.
  ///
  /// In en, this message translates to:
  /// **'Child & dependent care'**
  String get secChildCare;

  /// No description provided for @secEducation.
  ///
  /// In en, this message translates to:
  /// **'Education expenses'**
  String get secEducation;

  /// No description provided for @secSavers.
  ///
  /// In en, this message translates to:
  /// **'Retirement savings contributions'**
  String get secSavers;

  /// No description provided for @secPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments you already made'**
  String get secPayments;

  /// No description provided for @fFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fFirstName;

  /// No description provided for @fLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fLastName;

  /// No description provided for @fSsn.
  ///
  /// In en, this message translates to:
  /// **'Social Security number'**
  String get fSsn;

  /// No description provided for @fDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get fDateOfBirth;

  /// No description provided for @fBlind.
  ///
  /// In en, this message translates to:
  /// **'Legally blind'**
  String get fBlind;

  /// No description provided for @fFilingStatus.
  ///
  /// In en, this message translates to:
  /// **'Filing status'**
  String get fFilingStatus;

  /// No description provided for @fSsBenefits.
  ///
  /// In en, this message translates to:
  /// **'Total Social Security benefits received'**
  String get fSsBenefits;

  /// No description provided for @fUnemployment.
  ///
  /// In en, this message translates to:
  /// **'Unemployment compensation received'**
  String get fUnemployment;

  /// No description provided for @fUnemploymentWithheld.
  ///
  /// In en, this message translates to:
  /// **'Federal tax withheld from unemployment'**
  String get fUnemploymentWithheld;

  /// No description provided for @fOtherIncomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Description (e.g., prize, jury pay)'**
  String get fOtherIncomeDesc;

  /// No description provided for @hOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the income'**
  String get hOtherIncome;

  /// No description provided for @fOtherIncomeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fOtherIncomeAmount;

  /// No description provided for @fCarLoanInterest.
  ///
  /// In en, this message translates to:
  /// **'Qualified car loan interest paid (2025–2028)'**
  String get fCarLoanInterest;

  /// No description provided for @fMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical & dental expenses'**
  String get fMedical;

  /// No description provided for @fSalt.
  ///
  /// In en, this message translates to:
  /// **'State & local taxes paid (income + property)'**
  String get fSalt;

  /// No description provided for @fMortgage.
  ///
  /// In en, this message translates to:
  /// **'Home mortgage interest (Form 1098)'**
  String get fMortgage;

  /// No description provided for @fCharityCash.
  ///
  /// In en, this message translates to:
  /// **'Charitable donations (cash)'**
  String get fCharityCash;

  /// No description provided for @fCharityNonCash.
  ///
  /// In en, this message translates to:
  /// **'Charitable donations (goods)'**
  String get fCharityNonCash;

  /// No description provided for @fIra.
  ///
  /// In en, this message translates to:
  /// **'Traditional IRA contributions'**
  String get fIra;

  /// No description provided for @fStudentLoanInterest.
  ///
  /// In en, this message translates to:
  /// **'Student loan interest paid (Form 1098-E)'**
  String get fStudentLoanInterest;

  /// No description provided for @fHsa.
  ///
  /// In en, this message translates to:
  /// **'HSA contributions'**
  String get fHsa;

  /// No description provided for @fEducator.
  ///
  /// In en, this message translates to:
  /// **'Educator expenses'**
  String get fEducator;

  /// No description provided for @fChildCare.
  ///
  /// In en, this message translates to:
  /// **'Child care expenses (so you could work or look for work)'**
  String get fChildCare;

  /// No description provided for @fAotc.
  ///
  /// In en, this message translates to:
  /// **'American opportunity credit qualified expenses (max 4,000)'**
  String get fAotc;

  /// No description provided for @fLlc.
  ///
  /// In en, this message translates to:
  /// **'Lifetime learning qualified expenses (max 10,000)'**
  String get fLlc;

  /// No description provided for @fSavers.
  ///
  /// In en, this message translates to:
  /// **'Retirement contributions for the Saver\'s Credit'**
  String get fSavers;

  /// No description provided for @fEstimatedPayments.
  ///
  /// In en, this message translates to:
  /// **'Estimated tax payments made for this year'**
  String get fEstimatedPayments;

  /// No description provided for @infoYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your legal name exactly as it appears on your Social Security card.'**
  String get infoYourName;

  /// No description provided for @infoSsn.
  ///
  /// In en, this message translates to:
  /// **'We store your SSN only on this device. It never leaves your computer except if you export a file yourself.'**
  String get infoSsn;

  /// No description provided for @infoDob.
  ///
  /// In en, this message translates to:
  /// **'Your age affects extra deductions for people 65+, and the EITC age rules.'**
  String get infoDob;

  /// No description provided for @infoPersonal.
  ///
  /// In en, this message translates to:
  /// **'These details appear on your return. You can edit them anytime.'**
  String get infoPersonal;

  /// No description provided for @infoSpouse.
  ///
  /// In en, this message translates to:
  /// **'Needed for married filing jointly or separately. Qualifying surviving spouse uses your late spouse\'s details on paper forms.'**
  String get infoSpouse;

  /// No description provided for @infoDependents.
  ///
  /// In en, this message translates to:
  /// **'A dependent is a child or relative you support. Each one can unlock the Child Tax Credit, EITC, or education benefits.'**
  String get infoDependents;

  /// No description provided for @infoW2.
  ///
  /// In en, this message translates to:
  /// **'Copy the numbers straight from your W-2 boxes. Box 1 is your taxable wages.'**
  String get infoW2;

  /// No description provided for @infoInterest.
  ///
  /// In en, this message translates to:
  /// **'From Form 1099-INT: box 1 is taxable interest, box 8 is tax-exempt (like municipal bonds).'**
  String get infoInterest;

  /// No description provided for @infoDividends.
  ///
  /// In en, this message translates to:
  /// **'From Form 1099-DIV: box 1a ordinary dividends, box 1b qualified dividends (taxed at lower rates).'**
  String get infoDividends;

  /// No description provided for @infoCapGains.
  ///
  /// In en, this message translates to:
  /// **'Each sale from your broker\'s 1099-B: sales price and cost basis. Held over one year = long-term (lower rates).'**
  String get infoCapGains;

  /// No description provided for @infoSe.
  ///
  /// In en, this message translates to:
  /// **'Your net profit (income minus expenses) from freelancing or a small business. We compute self-employment tax for you.'**
  String get infoSe;

  /// No description provided for @infoRetirement.
  ///
  /// In en, this message translates to:
  /// **'From Form 1099-R: the taxable amount is usually in box 2a.'**
  String get infoRetirement;

  /// No description provided for @infoSs.
  ///
  /// In en, this message translates to:
  /// **'Find this in box 3 of your SSA-1099. Only part of it may be taxable — we figure that out.'**
  String get infoSs;

  /// No description provided for @infoCarLoan.
  ///
  /// In en, this message translates to:
  /// **'New for 2025: interest on a car loan for a personal vehicle (from your lender). Phases out at higher incomes.'**
  String get infoCarLoan;

  /// No description provided for @infoOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'One-time or unusual income. Gambling winnings need special handling — see a professional for those.'**
  String get infoOtherIncome;

  /// No description provided for @infoMedical.
  ///
  /// In en, this message translates to:
  /// **'Only the part above 7.5% of your income counts. Include premiums you paid yourself.'**
  String get infoMedical;

  /// No description provided for @infoSalt.
  ///
  /// In en, this message translates to:
  /// **'State/local income + property taxes. The cap is \$10,000 (2024) or \$40,000 (2025, phasing down at high incomes).'**
  String get infoSalt;

  /// No description provided for @infoIra.
  ///
  /// In en, this message translates to:
  /// **'Traditional IRA contributions may be deductible depending on your income and workplace plan.'**
  String get infoIra;

  /// No description provided for @infoSli.
  ///
  /// In en, this message translates to:
  /// **'Up to \$2,500 of student loan interest, phased out at higher incomes.'**
  String get infoSli;

  /// No description provided for @infoDeductions.
  ///
  /// In en, this message translates to:
  /// **'We automatically compare itemized vs standard and use whichever helps you more.'**
  String get infoDeductions;

  /// No description provided for @infoChildCare.
  ///
  /// In en, this message translates to:
  /// **'Payments so you could work or look for work. Max \$3,000 for one child, \$6,000 for two or more.'**
  String get infoChildCare;

  /// No description provided for @infoAotc.
  ///
  /// In en, this message translates to:
  /// **'First four years of college. Qualified expenses like tuition and required books (max \$4,000).'**
  String get infoAotc;

  /// No description provided for @infoLlc.
  ///
  /// In en, this message translates to:
  /// **'Any level of study: tuition and fees (max \$10,000, credit is 20%).'**
  String get infoLlc;

  /// No description provided for @infoSavers.
  ///
  /// In en, this message translates to:
  /// **'Contributions to an IRA or workplace plan may earn up to 50% back as a credit if your income is low to moderate.'**
  String get infoSavers;

  /// No description provided for @infoCredits.
  ///
  /// In en, this message translates to:
  /// **'Payments and credits reduce what you owe. Some credits are refundable — they can increase your refund.'**
  String get infoCredits;

  /// No description provided for @emptyW2.
  ///
  /// In en, this message translates to:
  /// **'No W-2s yet. Add one for each employer.'**
  String get emptyW2;

  /// No description provided for @addW2.
  ///
  /// In en, this message translates to:
  /// **'Add a W-2'**
  String get addW2;

  /// No description provided for @w2N.
  ///
  /// In en, this message translates to:
  /// **'W-2 #{n}'**
  String w2N(int n);

  /// No description provided for @fEmployer.
  ///
  /// In en, this message translates to:
  /// **'Employer name'**
  String get fEmployer;

  /// No description provided for @fEin.
  ///
  /// In en, this message translates to:
  /// **'Employer ID number (EIN)'**
  String get fEin;

  /// No description provided for @fWagesBox1.
  ///
  /// In en, this message translates to:
  /// **'Wages (Box 1)'**
  String get fWagesBox1;

  /// No description provided for @fFedWithheldBox2.
  ///
  /// In en, this message translates to:
  /// **'Federal income tax withheld (Box 2)'**
  String get fFedWithheldBox2;

  /// No description provided for @fSsWagesBox3.
  ///
  /// In en, this message translates to:
  /// **'Social Security wages (Box 3)'**
  String get fSsWagesBox3;

  /// No description provided for @fSsWithheldBox4.
  ///
  /// In en, this message translates to:
  /// **'Social Security tax withheld (Box 4)'**
  String get fSsWithheldBox4;

  /// No description provided for @fMedicareBox6.
  ///
  /// In en, this message translates to:
  /// **'Medicare tax withheld (Box 6)'**
  String get fMedicareBox6;

  /// No description provided for @fQualifiedTips.
  ///
  /// In en, this message translates to:
  /// **'Qualified tips (2025)'**
  String get fQualifiedTips;

  /// No description provided for @fQualifiedOvertime.
  ///
  /// In en, this message translates to:
  /// **'Qualified overtime pay (2025)'**
  String get fQualifiedOvertime;

  /// No description provided for @emptyDependents.
  ///
  /// In en, this message translates to:
  /// **'No dependents added yet.'**
  String get emptyDependents;

  /// No description provided for @addDependent.
  ///
  /// In en, this message translates to:
  /// **'Add a dependent'**
  String get addDependent;

  /// No description provided for @dependentN.
  ///
  /// In en, this message translates to:
  /// **'Dependent #{n}'**
  String dependentN(int n);

  /// No description provided for @fRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship to you (son, daughter, mother…)'**
  String get fRelationship;

  /// No description provided for @fFullTimeStudent.
  ///
  /// In en, this message translates to:
  /// **'Full-time student'**
  String get fFullTimeStudent;

  /// No description provided for @fPermanentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Permanently and totally disabled'**
  String get fPermanentlyDisabled;

  /// No description provided for @emptyInterest.
  ///
  /// In en, this message translates to:
  /// **'No interest income added yet.'**
  String get emptyInterest;

  /// No description provided for @addPayer.
  ///
  /// In en, this message translates to:
  /// **'Add a payer'**
  String get addPayer;

  /// No description provided for @payerN.
  ///
  /// In en, this message translates to:
  /// **'Payer #{n}'**
  String payerN(int n);

  /// No description provided for @fPayer.
  ///
  /// In en, this message translates to:
  /// **'Payer name'**
  String get fPayer;

  /// No description provided for @fTaxableInterest.
  ///
  /// In en, this message translates to:
  /// **'Taxable interest (1099-INT box 1)'**
  String get fTaxableInterest;

  /// No description provided for @fTaxExemptInterest.
  ///
  /// In en, this message translates to:
  /// **'Tax-exempt interest (box 8)'**
  String get fTaxExemptInterest;

  /// No description provided for @emptyDividends.
  ///
  /// In en, this message translates to:
  /// **'No dividends added yet.'**
  String get emptyDividends;

  /// No description provided for @fOrdinaryDividends.
  ///
  /// In en, this message translates to:
  /// **'Ordinary dividends (box 1a)'**
  String get fOrdinaryDividends;

  /// No description provided for @fQualifiedDividends.
  ///
  /// In en, this message translates to:
  /// **'Qualified dividends (box 1b)'**
  String get fQualifiedDividends;

  /// No description provided for @emptyCapGains.
  ///
  /// In en, this message translates to:
  /// **'No sales added yet.'**
  String get emptyCapGains;

  /// No description provided for @addSale.
  ///
  /// In en, this message translates to:
  /// **'Add a sale'**
  String get addSale;

  /// No description provided for @saleN.
  ///
  /// In en, this message translates to:
  /// **'Sale #{n}'**
  String saleN(int n);

  /// No description provided for @fDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (e.g., AAPL shares)'**
  String get fDescription;

  /// No description provided for @fProceeds.
  ///
  /// In en, this message translates to:
  /// **'Sales price'**
  String get fProceeds;

  /// No description provided for @fCostBasis.
  ///
  /// In en, this message translates to:
  /// **'Cost basis (what you paid)'**
  String get fCostBasis;

  /// No description provided for @fLongTerm.
  ///
  /// In en, this message translates to:
  /// **'Held more than one year (long-term)'**
  String get fLongTerm;

  /// No description provided for @emptySe.
  ///
  /// In en, this message translates to:
  /// **'No businesses added yet.'**
  String get emptySe;

  /// No description provided for @addBusiness.
  ///
  /// In en, this message translates to:
  /// **'Add a business'**
  String get addBusiness;

  /// No description provided for @businessN.
  ///
  /// In en, this message translates to:
  /// **'Business #{n}'**
  String businessN(int n);

  /// No description provided for @fBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get fBusinessName;

  /// No description provided for @fNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit (income minus expenses)'**
  String get fNetProfit;

  /// No description provided for @fSeTips.
  ///
  /// In en, this message translates to:
  /// **'Qualified tips (2025)'**
  String get fSeTips;

  /// No description provided for @fSeHealthPremiums.
  ///
  /// In en, this message translates to:
  /// **'Self-employed health insurance premiums'**
  String get fSeHealthPremiums;

  /// No description provided for @fSepSimple.
  ///
  /// In en, this message translates to:
  /// **'SEP/SIMPle plan contributions'**
  String get fSepSimple;

  /// No description provided for @emptyRetirement.
  ///
  /// In en, this message translates to:
  /// **'No distributions added yet.'**
  String get emptyRetirement;

  /// No description provided for @fGrossDistribution.
  ///
  /// In en, this message translates to:
  /// **'Gross distribution (box 1)'**
  String get fGrossDistribution;

  /// No description provided for @fTaxableAmount.
  ///
  /// In en, this message translates to:
  /// **'Taxable amount (box 2a)'**
  String get fTaxableAmount;

  /// No description provided for @fFedWithheld.
  ///
  /// In en, this message translates to:
  /// **'Federal tax withheld (box 4)'**
  String get fFedWithheld;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your answers'**
  String get reviewTitle;

  /// No description provided for @rowWages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get rowWages;

  /// No description provided for @rowSeIncome.
  ///
  /// In en, this message translates to:
  /// **'Self-employment income'**
  String get rowSeIncome;

  /// No description provided for @rowInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get rowInterest;

  /// No description provided for @rowDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends'**
  String get rowDividends;

  /// No description provided for @rowCapGains.
  ///
  /// In en, this message translates to:
  /// **'Net capital gain'**
  String get rowCapGains;

  /// No description provided for @rowRetirement.
  ///
  /// In en, this message translates to:
  /// **'Retirement (taxable)'**
  String get rowRetirement;

  /// No description provided for @rowSs.
  ///
  /// In en, this message translates to:
  /// **'Social Security (taxable)'**
  String get rowSs;

  /// No description provided for @rowUnemployment.
  ///
  /// In en, this message translates to:
  /// **'Unemployment'**
  String get rowUnemployment;

  /// No description provided for @rowOther.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get rowOther;

  /// No description provided for @rowTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get rowTotalIncome;

  /// No description provided for @rowAgi.
  ///
  /// In en, this message translates to:
  /// **'Adjusted gross income (AGI)'**
  String get rowAgi;

  /// No description provided for @rowItemized.
  ///
  /// In en, this message translates to:
  /// **'Itemized deductions'**
  String get rowItemized;

  /// No description provided for @rowStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard deduction'**
  String get rowStandard;

  /// No description provided for @rowQbi.
  ///
  /// In en, this message translates to:
  /// **'QBI deduction (§199A)'**
  String get rowQbi;

  /// No description provided for @rowSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior deduction'**
  String get rowSenior;

  /// No description provided for @rowTaxableIncome.
  ///
  /// In en, this message translates to:
  /// **'Taxable income'**
  String get rowTaxableIncome;

  /// No description provided for @rowTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get rowTax;

  /// No description provided for @rowSeTax.
  ///
  /// In en, this message translates to:
  /// **'Self-employment tax'**
  String get rowSeTax;

  /// No description provided for @rowCtc.
  ///
  /// In en, this message translates to:
  /// **'Child Tax Credit'**
  String get rowCtc;

  /// No description provided for @rowCare.
  ///
  /// In en, this message translates to:
  /// **'Child & dependent care credit'**
  String get rowCare;

  /// No description provided for @rowAotc.
  ///
  /// In en, this message translates to:
  /// **'American opportunity credit'**
  String get rowAotc;

  /// No description provided for @rowLlc.
  ///
  /// In en, this message translates to:
  /// **'Lifetime learning credit'**
  String get rowLlc;

  /// No description provided for @rowSavers.
  ///
  /// In en, this message translates to:
  /// **'Saver\'s Credit'**
  String get rowSavers;

  /// No description provided for @rowEitc.
  ///
  /// In en, this message translates to:
  /// **'Earned Income Tax Credit'**
  String get rowEitc;

  /// No description provided for @rowPayments.
  ///
  /// In en, this message translates to:
  /// **'Withholding & estimates'**
  String get rowPayments;

  /// No description provided for @editAnswers.
  ///
  /// In en, this message translates to:
  /// **'Edit my answers'**
  String get editAnswers;

  /// No description provided for @issueMissingSpouse.
  ///
  /// In en, this message translates to:
  /// **'This filing status needs a spouse — add one under Personal info.'**
  String get issueMissingSpouse;

  /// No description provided for @issueMfsLimits.
  ///
  /// In en, this message translates to:
  /// **'Married filing separately cannot claim the EITC, education credits, or the senior deduction.'**
  String get issueMfsLimits;

  /// No description provided for @issueMissingSsn.
  ///
  /// In en, this message translates to:
  /// **'Your SSN is missing — add it under Personal info.'**
  String get issueMissingSsn;

  /// No description provided for @issueDependentSsn.
  ///
  /// In en, this message translates to:
  /// **'A dependent is missing an SSN, which is required for most credits.'**
  String get issueDependentSsn;

  /// No description provided for @issueDependentDob.
  ///
  /// In en, this message translates to:
  /// **'A dependent is missing a date of birth, so age-based rules can\'t be checked.'**
  String get issueDependentDob;

  /// No description provided for @issueW2Employer.
  ///
  /// In en, this message translates to:
  /// **'A W-2 has no employer name.'**
  String get issueW2Employer;

  /// No description provided for @issueW2NoWithholding.
  ///
  /// In en, this message translates to:
  /// **'A W-2 shows no federal withholding — double-check Box 2.'**
  String get issueW2NoWithholding;

  /// No description provided for @issueSeTax.
  ///
  /// In en, this message translates to:
  /// **'Self-employment income over \$400 triggers SE tax — quarterly estimated payments may be needed next year.'**
  String get issueSeTax;

  /// No description provided for @issueObbbaOnly2025.
  ///
  /// In en, this message translates to:
  /// **'Tips and overtime deductions only apply to tax years 2025–2028.'**
  String get issueObbbaOnly2025;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your estimate'**
  String get resultsTitle;

  /// No description provided for @refundHeadline.
  ///
  /// In en, this message translates to:
  /// **'Estimated refund'**
  String get refundHeadline;

  /// No description provided for @oweHeadline.
  ///
  /// In en, this message translates to:
  /// **'Estimated balance due'**
  String get oweHeadline;

  /// No description provided for @estimateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a planning estimate produced by Nitro Nissi — not a filed return and not tax advice.'**
  String get estimateDisclaimer;

  /// No description provided for @bracketBreakdown.
  ///
  /// In en, this message translates to:
  /// **'How your tax adds up'**
  String get bracketBreakdown;

  /// No description provided for @preferentialNote.
  ///
  /// In en, this message translates to:
  /// **'Includes {amount} taxed at lower 0/15/20% rates (saves {tax} vs ordinary rates).'**
  String preferentialNote(String amount, String tax);

  /// No description provided for @factAgi.
  ///
  /// In en, this message translates to:
  /// **'Adjusted gross income'**
  String get factAgi;

  /// No description provided for @factDeduction.
  ///
  /// In en, this message translates to:
  /// **'Deduction used'**
  String get factDeduction;

  /// No description provided for @factTaxable.
  ///
  /// In en, this message translates to:
  /// **'Taxable income'**
  String get factTaxable;

  /// No description provided for @factEffective.
  ///
  /// In en, this message translates to:
  /// **'Effective rate'**
  String get factEffective;

  /// No description provided for @factMarginal.
  ///
  /// In en, this message translates to:
  /// **'Top marginal rate'**
  String get factMarginal;

  /// No description provided for @factCredits.
  ///
  /// In en, this message translates to:
  /// **'Total credits'**
  String get factCredits;

  /// No description provided for @factOtherTaxes.
  ///
  /// In en, this message translates to:
  /// **'Other taxes (SE/NIIT)'**
  String get factOtherTaxes;

  /// No description provided for @exportHeader.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportHeader;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Printable return package'**
  String get exportPdf;

  /// No description provided for @exportMef.
  ///
  /// In en, this message translates to:
  /// **'E-file-ready JSON'**
  String get exportMef;

  /// No description provided for @savedPackage.
  ///
  /// In en, this message translates to:
  /// **'Return package saved.'**
  String get savedPackage;

  /// No description provided for @savedMef.
  ///
  /// In en, this message translates to:
  /// **'E-file-ready JSON saved.'**
  String get savedMef;

  /// No description provided for @mefDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The JSON mirrors IRS MeF concepts for portability. It is not transmitted anywhere and is not accepted by the IRS directly.'**
  String get mefDisclaimer;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @startNewReturn.
  ///
  /// In en, this message translates to:
  /// **'Start a new return'**
  String get startNewReturn;

  /// No description provided for @openReturnFile.
  ///
  /// In en, this message translates to:
  /// **'Open a return file (.nnx)'**
  String get openReturnFile;

  /// No description provided for @importFromOther.
  ///
  /// In en, this message translates to:
  /// **'Import from TurboTax / CSV / paste'**
  String get importFromOther;

  /// No description provided for @continueLastReturn.
  ///
  /// In en, this message translates to:
  /// **'Continue my last return'**
  String get continueLastReturn;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'A clean-room, open-source guided tax return for US federal 2024 & 2025 — your data stays on your device.'**
  String get welcomeTagline;

  /// No description provided for @welcomePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Nitro Nissi stores everything locally. AI features are optional and only use the free API keys you provide.'**
  String get welcomePrivacyNote;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that file: {error}'**
  String openFailed(String error);

  /// No description provided for @eligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick eligibility check'**
  String get eligibilityTitle;

  /// No description provided for @eligQ1.
  ///
  /// In en, this message translates to:
  /// **'Were you a US citizen or resident alien for the whole year?'**
  String get eligQ1;

  /// No description provided for @eligQ2.
  ///
  /// In en, this message translates to:
  /// **'Do you (and your spouse, if filing jointly) have valid SSNs?'**
  String get eligQ2;

  /// No description provided for @eligQ3.
  ///
  /// In en, this message translates to:
  /// **'Is your income only from paychecks, self-employment, interest, dividends, investments, retirement, Social Security, or unemployment?'**
  String get eligQ3;

  /// No description provided for @eligQ4.
  ///
  /// In en, this message translates to:
  /// **'No rental properties, K-1s, farm income, foreign accounts, or a bankruptcy this year?'**
  String get eligQ4;

  /// No description provided for @answerYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get answerYes;

  /// No description provided for @answerNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get answerNo;

  /// No description provided for @eligOkTitle.
  ///
  /// In en, this message translates to:
  /// **'Great — Nitro Nissi fits your situation'**
  String get eligOkTitle;

  /// No description provided for @eligOkBody.
  ///
  /// In en, this message translates to:
  /// **'You can complete a federal return here with confidence. You\'ll still review everything before exporting.'**
  String get eligOkBody;

  /// No description provided for @eligPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'You can still continue — with care'**
  String get eligPartialTitle;

  /// No description provided for @eligPartialBody.
  ///
  /// In en, this message translates to:
  /// **'Some answers suggest parts of your taxes may need a professional or more advanced software. Nitro Nissi will flag anything it can\'t fully handle.'**
  String get eligPartialBody;

  /// No description provided for @eligContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to my return'**
  String get eligContinue;

  /// No description provided for @askPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your return…'**
  String get askPlaceholder;

  /// No description provided for @quickReviewReturn.
  ///
  /// In en, this message translates to:
  /// **'Review my return'**
  String get quickReviewReturn;

  /// No description provided for @quickDeductions.
  ///
  /// In en, this message translates to:
  /// **'What am I missing?'**
  String get quickDeductions;

  /// No description provided for @quickExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain AGI & deductions'**
  String get quickExplain;

  /// No description provided for @settingsAiHeader.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get settingsAiHeader;

  /// No description provided for @googleKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Google AI Studio (Gemini) — free API key'**
  String get googleKeyTitle;

  /// No description provided for @googleKeySteps.
  ///
  /// In en, this message translates to:
  /// **'1. Open aistudio.google.com/apikey and sign in with a Google account.\n2. Click \"Create API key\" (choose or create a project).\n3. Copy the key (starts with AIza…) and paste it below. The free tier includes daily limits per model.'**
  String get googleKeySteps;

  /// No description provided for @googleKeyLink.
  ///
  /// In en, this message translates to:
  /// **'Get a free Google AI Studio key →'**
  String get googleKeyLink;

  /// No description provided for @mistralKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Mistral La Plateforme — free API key'**
  String get mistralKeyTitle;

  /// No description provided for @mistralKeySteps.
  ///
  /// In en, this message translates to:
  /// **'1. Open console.mistral.ai/api-keys and create a free account (the \"Experiment\" plan needs no credit card).\n2. Click \"Create new key\", name it, and copy it.\n3. Paste it below. The free plan allows about 1 request/second and 500k tokens/minute.'**
  String get mistralKeySteps;

  /// No description provided for @mistralKeyLink.
  ///
  /// In en, this message translates to:
  /// **'Get a free Mistral key →'**
  String get mistralKeyLink;

  /// No description provided for @chainHeader.
  ///
  /// In en, this message translates to:
  /// **'Model fallback chain'**
  String get chainHeader;

  /// No description provided for @testChain.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get testChain;

  /// No description provided for @chainNote.
  ///
  /// In en, this message translates to:
  /// **'Nitro Nissi tries the first model, then automatically falls to the next when a key is missing, the model is unavailable, or free-tier limits are hit. Reorder or disable freely.'**
  String get chainNote;

  /// No description provided for @automationHeader.
  ///
  /// In en, this message translates to:
  /// **'Automation & privacy'**
  String get automationHeader;

  /// No description provided for @toggleShareContext.
  ///
  /// In en, this message translates to:
  /// **'Let the assistant see a summary of my return'**
  String get toggleShareContext;

  /// No description provided for @toggleAnonymize.
  ///
  /// In en, this message translates to:
  /// **'Anonymize personal data (names, SSNs) in AI requests'**
  String get toggleAnonymize;

  /// No description provided for @toggleAutoDeductions.
  ///
  /// In en, this message translates to:
  /// **'Suggest commonly missed deductions'**
  String get toggleAutoDeductions;

  /// No description provided for @toggleAutoExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract numbers from pasted documents automatically'**
  String get toggleAutoExtract;

  /// No description provided for @appearanceHeader.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get appearanceHeader;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpen(String url);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importTitle;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Bring data in from a TurboTax return file (best-effort — their format is proprietary), a CSV, our own .nnx files, or paste W-2/1099 text and let AI extract the numbers. You always review before anything is applied.'**
  String get importIntro;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file…'**
  String get chooseFile;

  /// No description provided for @extractPasted.
  ///
  /// In en, this message translates to:
  /// **'Extract from pasted text'**
  String get extractPasted;

  /// No description provided for @pasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste document text here'**
  String get pasteLabel;

  /// No description provided for @pasteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., copy the text of a W-2 or 1099…'**
  String get pasteHint;

  /// No description provided for @detectedFormat.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detectedFormat;

  /// No description provided for @reviewImportNote.
  ///
  /// In en, this message translates to:
  /// **'Keep only the fields you verified. Import never overwrites without your checkmarks.'**
  String get reviewImportNote;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'No recognizable tax fields were found. Newer TurboTax files may be encrypted or use an undocumented format — see docs/FILE_FORMATS.md.'**
  String get nothingFound;

  /// No description provided for @applyFields.
  ///
  /// In en, this message translates to:
  /// **'Apply {count, plural, =1{1 field} other{{count} fields}}'**
  String applyFields(int count);

  /// No description provided for @importFaq.
  ///
  /// In en, this message translates to:
  /// **'Why best-effort? Intuit\'s formats are closed and undocumented; we parse container structures and label matches conservatively, and we never attempt to defeat encryption. Docs/REVERSE_ENGINEERING_PLAN.md describes our clean-room roadmap.'**
  String get importFaq;

  /// No description provided for @importNotePreview.
  ///
  /// In en, this message translates to:
  /// **'Review each detected field, keep what you verified, then apply.'**
  String get importNotePreview;

  /// No description provided for @importNoteZipEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This is a ZIP container, but it appears encrypted or non-standard. Try exporting a CSV/PDF from the other app instead.'**
  String get importNoteZipEncrypted;

  /// No description provided for @importNoteOle2NoFields.
  ///
  /// In en, this message translates to:
  /// **'This is an OLE2 (Compound File) container. No recognizable tax fields were found in its streams.'**
  String get importNoteOle2NoFields;

  /// No description provided for @importNoteOle2Unknown.
  ///
  /// In en, this message translates to:
  /// **'This is an OLE2 (Compound File) container, but its contents could not be analyzed.'**
  String get importNoteOle2Unknown;

  /// No description provided for @importNoteUnknown.
  ///
  /// In en, this message translates to:
  /// **'The file type wasn\'t recognized. Supported: .nnx, JSON, CSV, plain text, and structural scans of proprietary files.'**
  String get importNoteUnknown;

  /// No description provided for @importErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading that file.'**
  String get importErrorUnknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
