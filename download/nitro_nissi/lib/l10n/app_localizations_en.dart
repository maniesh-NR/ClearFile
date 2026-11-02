import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navMyReturn => 'My return';

  @override
  String get navAssistant => 'AI assistant';

  @override
  String get navSettings => 'Settings';

  @override
  String get refundEstimate => 'Refund';

  @override
  String get oweEstimate => 'Owe';

  @override
  String get topicsHeader => 'Let\'s finish your return';

  @override
  String get topicsSubheader => 'Work through each topic. You can jump around anytime — your answers save automatically.';

  @override
  String issuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need attention before filing',
      one: '1 item needs attention before filing',
    );
    return '$_temp0';
  }

  @override
  String issuesFoundInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions for your review',
      one: '1 suggestion for your review',
    );
    return '$_temp0';
  }

  @override
  String get continueToReview => 'Continue to review';

  @override
  String get jumpToResults => 'Jump to my estimate';

  @override
  String autosaveNote(String name) {
    return 'Autosaved to $name';
  }

  @override
  String get whyWeAsk => 'Why do we ask?';

  @override
  String topicStep(int a, int b) {
    return 'Step $a of $b';
  }

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get seeResults => 'See my results';

  @override
  String get topicPersonal => 'Personal info';

  @override
  String get topicIncome => 'Income';

  @override
  String get topicDeductions => 'Deductions & adjustments';

  @override
  String get topicCredits => 'Credits & payments';

  @override
  String get pagePersonalInfo => 'Tell us about you';

  @override
  String get pageSpouse => 'Your spouse';

  @override
  String get pageDependents => 'Dependents';

  @override
  String get pageW2 => 'W-2 wages';

  @override
  String get pageInterest => 'Interest income';

  @override
  String get pageDividends => 'Dividends';

  @override
  String get pageCapGains => 'Investment sales';

  @override
  String get pageSelfEmployment => 'Self-employment';

  @override
  String get pageRetirement => 'Retirement distributions';

  @override
  String get pageOtherIncome => 'Other income';

  @override
  String get pageDeductions => 'Deductions';

  @override
  String get pageCredits => 'Credits';

  @override
  String get secYourInfo => 'Your information';

  @override
  String get secFilingStatus => 'Filing status';

  @override
  String get secSpouseInfo => 'Spouse information';

  @override
  String get secSocialSecurity => 'Social Security benefits';

  @override
  String get secUnemployment => 'Unemployment compensation';

  @override
  String get secOtherIncome => 'Other income';

  @override
  String get secObbba => '2025 special deductions';

  @override
  String get secItemized => 'Itemized deductions (optional)';

  @override
  String get secAdjustments => 'Adjustments to income';

  @override
  String get secChildCare => 'Child & dependent care';

  @override
  String get secEducation => 'Education expenses';

  @override
  String get secSavers => 'Retirement savings contributions';

  @override
  String get secPayments => 'Payments you already made';

  @override
  String get fFirstName => 'First name';

  @override
  String get fLastName => 'Last name';

  @override
  String get fSsn => 'Social Security number';

  @override
  String get fDateOfBirth => 'Date of birth';

  @override
  String get fBlind => 'Legally blind';

  @override
  String get fFilingStatus => 'Filing status';

  @override
  String get fSsBenefits => 'Total Social Security benefits received';

  @override
  String get fUnemployment => 'Unemployment compensation received';

  @override
  String get fUnemploymentWithheld => 'Federal tax withheld from unemployment';

  @override
  String get fOtherIncomeDesc => 'Description (e.g., prize, jury pay)';

  @override
  String get hOtherIncome => 'Brief description of the income';

  @override
  String get fOtherIncomeAmount => 'Amount';

  @override
  String get fCarLoanInterest => 'Qualified car loan interest paid (2025–2028)';

  @override
  String get fMedical => 'Medical & dental expenses';

  @override
  String get fSalt => 'State & local taxes paid (income + property)';

  @override
  String get fMortgage => 'Home mortgage interest (Form 1098)';

  @override
  String get fCharityCash => 'Charitable donations (cash)';

  @override
  String get fCharityNonCash => 'Charitable donations (goods)';

  @override
  String get fIra => 'Traditional IRA contributions';

  @override
  String get fStudentLoanInterest => 'Student loan interest paid (Form 1098-E)';

  @override
  String get fHsa => 'HSA contributions';

  @override
  String get fEducator => 'Educator expenses';

  @override
  String get fChildCare => 'Child care expenses (so you could work or look for work)';

  @override
  String get fAotc => 'American opportunity credit qualified expenses (max 4,000)';

  @override
  String get fLlc => 'Lifetime learning qualified expenses (max 10,000)';

  @override
  String get fSavers => 'Retirement contributions for the Saver\'s Credit';

  @override
  String get fEstimatedPayments => 'Estimated tax payments made for this year';

  @override
  String get infoYourName => 'Enter your legal name exactly as it appears on your Social Security card.';

  @override
  String get infoSsn => 'We store your SSN only on this device. It never leaves your computer except if you export a file yourself.';

  @override
  String get infoDob => 'Your age affects extra deductions for people 65+, and the EITC age rules.';

  @override
  String get infoPersonal => 'These details appear on your return. You can edit them anytime.';

  @override
  String get infoSpouse => 'Needed for married filing jointly or separately. Qualifying surviving spouse uses your late spouse\'s details on paper forms.';

  @override
  String get infoDependents => 'A dependent is a child or relative you support. Each one can unlock the Child Tax Credit, EITC, or education benefits.';

  @override
  String get infoW2 => 'Copy the numbers straight from your W-2 boxes. Box 1 is your taxable wages.';

  @override
  String get infoInterest => 'From Form 1099-INT: box 1 is taxable interest, box 8 is tax-exempt (like municipal bonds).';

  @override
  String get infoDividends => 'From Form 1099-DIV: box 1a ordinary dividends, box 1b qualified dividends (taxed at lower rates).';

  @override
  String get infoCapGains => 'Each sale from your broker\'s 1099-B: sales price and cost basis. Held over one year = long-term (lower rates).';

  @override
  String get infoSe => 'Your net profit (income minus expenses) from freelancing or a small business. We compute self-employment tax for you.';

  @override
  String get infoRetirement => 'From Form 1099-R: the taxable amount is usually in box 2a.';

  @override
  String get infoSs => 'Find this in box 3 of your SSA-1099. Only part of it may be taxable — we figure that out.';

  @override
  String get infoCarLoan => 'New for 2025: interest on a car loan for a personal vehicle (from your lender). Phases out at higher incomes.';

  @override
  String get infoOtherIncome => 'One-time or unusual income. Gambling winnings need special handling — see a professional for those.';

  @override
  String get infoMedical => 'Only the part above 7.5% of your income counts. Include premiums you paid yourself.';

  @override
  String get infoSalt => 'State/local income + property taxes. The cap is \$10,000 (2024) or \$40,000 (2025, phasing down at high incomes).';

  @override
  String get infoIra => 'Traditional IRA contributions may be deductible depending on your income and workplace plan.';

  @override
  String get infoSli => 'Up to \$2,500 of student loan interest, phased out at higher incomes.';

  @override
  String get infoDeductions => 'We automatically compare itemized vs standard and use whichever helps you more.';

  @override
  String get infoChildCare => 'Payments so you could work or look for work. Max \$3,000 for one child, \$6,000 for two or more.';

  @override
  String get infoAotc => 'First four years of college. Qualified expenses like tuition and required books (max \$4,000).';

  @override
  String get infoLlc => 'Any level of study: tuition and fees (max \$10,000, credit is 20%).';

  @override
  String get infoSavers => 'Contributions to an IRA or workplace plan may earn up to 50% back as a credit if your income is low to moderate.';

  @override
  String get infoCredits => 'Payments and credits reduce what you owe. Some credits are refundable — they can increase your refund.';

  @override
  String get emptyW2 => 'No W-2s yet. Add one for each employer.';

  @override
  String get addW2 => 'Add a W-2';

  @override
  String w2N(int n) {
    return 'W-2 #$n';
  }

  @override
  String get fEmployer => 'Employer name';

  @override
  String get fEin => 'Employer ID number (EIN)';

  @override
  String get fWagesBox1 => 'Wages (Box 1)';

  @override
  String get fFedWithheldBox2 => 'Federal income tax withheld (Box 2)';

  @override
  String get fSsWagesBox3 => 'Social Security wages (Box 3)';

  @override
  String get fSsWithheldBox4 => 'Social Security tax withheld (Box 4)';

  @override
  String get fMedicareBox6 => 'Medicare tax withheld (Box 6)';

  @override
  String get fQualifiedTips => 'Qualified tips (2025)';

  @override
  String get fQualifiedOvertime => 'Qualified overtime pay (2025)';

  @override
  String get emptyDependents => 'No dependents added yet.';

  @override
  String get addDependent => 'Add a dependent';

  @override
  String dependentN(int n) {
    return 'Dependent #$n';
  }

  @override
  String get fRelationship => 'Relationship to you (son, daughter, mother…)';

  @override
  String get fFullTimeStudent => 'Full-time student';

  @override
  String get fPermanentlyDisabled => 'Permanently and totally disabled';

  @override
  String get emptyInterest => 'No interest income added yet.';

  @override
  String get addPayer => 'Add a payer';

  @override
  String payerN(int n) {
    return 'Payer #$n';
  }

  @override
  String get fPayer => 'Payer name';

  @override
  String get fTaxableInterest => 'Taxable interest (1099-INT box 1)';

  @override
  String get fTaxExemptInterest => 'Tax-exempt interest (box 8)';

  @override
  String get emptyDividends => 'No dividends added yet.';

  @override
  String get fOrdinaryDividends => 'Ordinary dividends (box 1a)';

  @override
  String get fQualifiedDividends => 'Qualified dividends (box 1b)';

  @override
  String get emptyCapGains => 'No sales added yet.';

  @override
  String get addSale => 'Add a sale';

  @override
  String saleN(int n) {
    return 'Sale #$n';
  }

  @override
  String get fDescription => 'Description (e.g., AAPL shares)';

  @override
  String get fProceeds => 'Sales price';

  @override
  String get fCostBasis => 'Cost basis (what you paid)';

  @override
  String get fLongTerm => 'Held more than one year (long-term)';

  @override
  String get emptySe => 'No businesses added yet.';

  @override
  String get addBusiness => 'Add a business';

  @override
  String businessN(int n) {
    return 'Business #$n';
  }

  @override
  String get fBusinessName => 'Business name';

  @override
  String get fNetProfit => 'Net profit (income minus expenses)';

  @override
  String get fSeTips => 'Qualified tips (2025)';

  @override
  String get fSeHealthPremiums => 'Self-employed health insurance premiums';

  @override
  String get fSepSimple => 'SEP/SIMPle plan contributions';

  @override
  String get emptyRetirement => 'No distributions added yet.';

  @override
  String get fGrossDistribution => 'Gross distribution (box 1)';

  @override
  String get fTaxableAmount => 'Taxable amount (box 2a)';

  @override
  String get fFedWithheld => 'Federal tax withheld (box 4)';

  @override
  String get reviewTitle => 'Check your answers';

  @override
  String get rowWages => 'Wages';

  @override
  String get rowSeIncome => 'Self-employment income';

  @override
  String get rowInterest => 'Interest';

  @override
  String get rowDividends => 'Dividends';

  @override
  String get rowCapGains => 'Net capital gain';

  @override
  String get rowRetirement => 'Retirement (taxable)';

  @override
  String get rowSs => 'Social Security (taxable)';

  @override
  String get rowUnemployment => 'Unemployment';

  @override
  String get rowOther => 'Other income';

  @override
  String get rowTotalIncome => 'Total income';

  @override
  String get rowAgi => 'Adjusted gross income (AGI)';

  @override
  String get rowItemized => 'Itemized deductions';

  @override
  String get rowStandard => 'Standard deduction';

  @override
  String get rowQbi => 'QBI deduction (§199A)';

  @override
  String get rowSenior => 'Senior deduction';

  @override
  String get rowTaxableIncome => 'Taxable income';

  @override
  String get rowTax => 'Tax';

  @override
  String get rowSeTax => 'Self-employment tax';

  @override
  String get rowCtc => 'Child Tax Credit';

  @override
  String get rowCare => 'Child & dependent care credit';

  @override
  String get rowAotc => 'American opportunity credit';

  @override
  String get rowLlc => 'Lifetime learning credit';

  @override
  String get rowSavers => 'Saver\'s Credit';

  @override
  String get rowEitc => 'Earned Income Tax Credit';

  @override
  String get rowPayments => 'Withholding & estimates';

  @override
  String get editAnswers => 'Edit my answers';

  @override
  String get issueMissingSpouse => 'This filing status needs a spouse — add one under Personal info.';

  @override
  String get issueMfsLimits => 'Married filing separately cannot claim the EITC, education credits, or the senior deduction.';

  @override
  String get issueMissingSsn => 'Your SSN is missing — add it under Personal info.';

  @override
  String get issueDependentSsn => 'A dependent is missing an SSN, which is required for most credits.';

  @override
  String get issueDependentDob => 'A dependent is missing a date of birth, so age-based rules can\'t be checked.';

  @override
  String get issueW2Employer => 'A W-2 has no employer name.';

  @override
  String get issueW2NoWithholding => 'A W-2 shows no federal withholding — double-check Box 2.';

  @override
  String get issueSeTax => 'Self-employment income over \$400 triggers SE tax — quarterly estimated payments may be needed next year.';

  @override
  String get issueObbbaOnly2025 => 'Tips and overtime deductions only apply to tax years 2025–2028.';

  @override
  String get resultsTitle => 'Your estimate';

  @override
  String get refundHeadline => 'Estimated refund';

  @override
  String get oweHeadline => 'Estimated balance due';

  @override
  String get estimateDisclaimer => 'This is a planning estimate produced by Nitro Nissi — not a filed return and not tax advice.';

  @override
  String get bracketBreakdown => 'How your tax adds up';

  @override
  String preferentialNote(String amount, String tax) {
    return 'Includes $amount taxed at lower 0/15/20% rates (saves $tax vs ordinary rates).';
  }

  @override
  String get factAgi => 'Adjusted gross income';

  @override
  String get factDeduction => 'Deduction used';

  @override
  String get factTaxable => 'Taxable income';

  @override
  String get factEffective => 'Effective rate';

  @override
  String get factMarginal => 'Top marginal rate';

  @override
  String get factCredits => 'Total credits';

  @override
  String get factOtherTaxes => 'Other taxes (SE/NIIT)';

  @override
  String get exportHeader => 'Export';

  @override
  String get exportPdf => 'Printable return package';

  @override
  String get exportMef => 'E-file-ready JSON';

  @override
  String get savedPackage => 'Return package saved.';

  @override
  String get savedMef => 'E-file-ready JSON saved.';

  @override
  String get mefDisclaimer => 'The JSON mirrors IRS MeF concepts for portability. It is not transmitted anywhere and is not accepted by the IRS directly.';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get startNewReturn => 'Start a new return';

  @override
  String get openReturnFile => 'Open a return file (.nnx)';

  @override
  String get importFromOther => 'Import from TurboTax / CSV / paste';

  @override
  String get continueLastReturn => 'Continue my last return';

  @override
  String get welcomeTagline => 'A clean-room, open-source guided tax return for US federal 2024 & 2025 — your data stays on your device.';

  @override
  String get welcomePrivacyNote => 'Nitro Nissi stores everything locally. AI features are optional and only use the free API keys you provide.';

  @override
  String openFailed(String error) {
    return 'Could not open that file: $error';
  }

  @override
  String get eligibilityTitle => 'Quick eligibility check';

  @override
  String get eligQ1 => 'Were you a US citizen or resident alien for the whole year?';

  @override
  String get eligQ2 => 'Do you (and your spouse, if filing jointly) have valid SSNs?';

  @override
  String get eligQ3 => 'Is your income only from paychecks, self-employment, interest, dividends, investments, retirement, Social Security, or unemployment?';

  @override
  String get eligQ4 => 'No rental properties, K-1s, farm income, foreign accounts, or a bankruptcy this year?';

  @override
  String get answerYes => 'Yes';

  @override
  String get answerNo => 'No';

  @override
  String get eligOkTitle => 'Great — Nitro Nissi fits your situation';

  @override
  String get eligOkBody => 'You can complete a federal return here with confidence. You\'ll still review everything before exporting.';

  @override
  String get eligPartialTitle => 'You can still continue — with care';

  @override
  String get eligPartialBody => 'Some answers suggest parts of your taxes may need a professional or more advanced software. Nitro Nissi will flag anything it can\'t fully handle.';

  @override
  String get eligContinue => 'Continue to my return';

  @override
  String get askPlaceholder => 'Ask anything about your return…';

  @override
  String get quickReviewReturn => 'Review my return';

  @override
  String get quickDeductions => 'What am I missing?';

  @override
  String get quickExplain => 'Explain AGI & deductions';

  @override
  String get settingsAiHeader => 'AI assistant';

  @override
  String get googleKeyTitle => 'Google AI Studio (Gemini) — free API key';

  @override
  String get googleKeySteps => '1. Open aistudio.google.com/apikey and sign in with a Google account.\n2. Click \"Create API key\" (choose or create a project).\n3. Copy the key (starts with AIza…) and paste it below. The free tier includes daily limits per model.';

  @override
  String get googleKeyLink => 'Get a free Google AI Studio key →';

  @override
  String get mistralKeyTitle => 'Mistral La Plateforme — free API key';

  @override
  String get mistralKeySteps => '1. Open console.mistral.ai/api-keys and create a free account (the \"Experiment\" plan needs no credit card).\n2. Click \"Create new key\", name it, and copy it.\n3. Paste it below. The free plan allows about 1 request/second and 500k tokens/minute.';

  @override
  String get mistralKeyLink => 'Get a free Mistral key →';

  @override
  String get chainHeader => 'Model fallback chain';

  @override
  String get testChain => 'Test';

  @override
  String get chainNote => 'Nitro Nissi tries the first model, then automatically falls to the next when a key is missing, the model is unavailable, or free-tier limits are hit. Reorder or disable freely.';

  @override
  String get automationHeader => 'Automation & privacy';

  @override
  String get toggleShareContext => 'Let the assistant see a summary of my return';

  @override
  String get toggleAnonymize => 'Anonymize personal data (names, SSNs) in AI requests';

  @override
  String get toggleAutoDeductions => 'Suggest commonly missed deductions';

  @override
  String get toggleAutoExtract => 'Extract numbers from pasted documents automatically';

  @override
  String get appearanceHeader => 'Appearance & language';

  @override
  String get themeLabel => 'Theme';

  @override
  String get languageLabel => 'Language';

  @override
  String couldNotOpen(String url) {
    return 'Could not open $url';
  }

  @override
  String get importTitle => 'Import';

  @override
  String get importIntro => 'Bring data in from a TurboTax return file (best-effort — their format is proprietary), a CSV, our own .nnx files, or paste W-2/1099 text and let AI extract the numbers. You always review before anything is applied.';

  @override
  String get chooseFile => 'Choose a file…';

  @override
  String get extractPasted => 'Extract from pasted text';

  @override
  String get pasteLabel => 'Paste document text here';

  @override
  String get pasteHint => 'e.g., copy the text of a W-2 or 1099…';

  @override
  String get detectedFormat => 'Detected';

  @override
  String get reviewImportNote => 'Keep only the fields you verified. Import never overwrites without your checkmarks.';

  @override
  String get nothingFound => 'No recognizable tax fields were found. Newer TurboTax files may be encrypted or use an undocumented format — see docs/FILE_FORMATS.md.';

  @override
  String applyFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields',
      one: '1 field',
    );
    return 'Apply $_temp0';
  }

  @override
  String get importFaq => 'Why best-effort? Intuit\'s formats are closed and undocumented; we parse container structures and label matches conservatively, and we never attempt to defeat encryption. Docs/REVERSE_ENGINEERING_PLAN.md describes our clean-room roadmap.';

  @override
  String get importNotePreview => 'Review each detected field, keep what you verified, then apply.';

  @override
  String get importNoteZipEncrypted => 'This is a ZIP container, but it appears encrypted or non-standard. Try exporting a CSV/PDF from the other app instead.';

  @override
  String get importNoteOle2NoFields => 'This is an OLE2 (Compound File) container. No recognizable tax fields were found in its streams.';

  @override
  String get importNoteOle2Unknown => 'This is an OLE2 (Compound File) container, but its contents could not be analyzed.';

  @override
  String get importNoteUnknown => 'The file type wasn\'t recognized. Supported: .nnx, JSON, CSV, plain text, and structural scans of proprietary files.';

  @override
  String get importErrorUnknown => 'Something went wrong while reading that file.';
}
