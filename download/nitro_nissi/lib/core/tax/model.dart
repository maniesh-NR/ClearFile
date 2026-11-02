/// Nitro Nissi — US federal tax return data model (TY2024 & TY2025).
///
/// Pure Dart. Amounts are stored as doubles in whole US dollars; the engine
/// performs integer-safe rounding per IRS rules (whole-dollar returns).
library;

import 'dart:convert';

/// US federal filing statuses (Form 1040, lines 1-5).
enum FilingStatus {
  single,
  marriedJointly,
  marriedSeparately,
  headOfHousehold,
  qualifyingSurvivingSpouse;

  String toJson() => name;

  static FilingStatus fromJson(String v) => FilingStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => FilingStatus.single,
      );
}

class Person {
  String firstName;
  String lastName;
  String ssn; // masked in UI; stored as entered
  bool isBlind;
  DateTime? dateOfBirth;

  Person({
    this.firstName = '',
    this.lastName = '',
    this.ssn = '',
    this.isBlind = false,
    this.dateOfBirth,
  });

  bool get is65OrOlder {
    final d = dateOfBirth;
    if (d == null) return false;
    // IRS: considered 65 on the day BEFORE the 65th birthday.
    final cutoff = DateTime(d.year + 65, d.month, d.day - 1);
    return DateTime.now().isAfter(cutoff) || d.year <= DateTime.now().year - 65;
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'ssn': ssn,
        'isBlind': isBlind,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
      };

  static Person fromJson(Map<String, dynamic> j) => Person(
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        ssn: j['ssn'] as String? ?? '',
        isBlind: j['isBlind'] as bool? ?? false,
        dateOfBirth: j['dateOfBirth'] == null
            ? null
            : DateTime.tryParse(j['dateOfBirth'] as String),
      );
}

class Dependent {
  String firstName;
  String lastName;
  String ssn;
  String relationship;
  DateTime? dateOfBirth;
  bool isFullTimeStudent;
  bool permanentlyDisabled;
  int monthsLivedWithYou;
  /// Dates from birth only; used for the CTC qualifying-child test (<17 at EOY).
  bool isUsCitizen;

  Dependent({
    this.firstName = '',
    this.lastName = '',
    this.ssn = '',
    this.relationship = '',
    this.dateOfBirth,
    this.isFullTimeStudent = false,
    this.permanentlyDisabled = false,
    this.monthsLivedWithYou = 12,
    this.isUsCitizen = true,
  });

  /// Under 17 at end of the given tax year → Child Tax Credit eligible.
  bool isCtcEligible(int taxYear) {
    final d = dateOfBirth;
    if (d == null) return false;
    return taxYear - d.year < 17;
  }

  /// EITC qualifying child: under 19, or under 24 if a full-time student,
  /// or any age if permanently disabled.
  bool isEitcQualifyingChild(int taxYear) {
    if (permanentlyDisabled) return true;
    final d = dateOfBirth;
    if (d == null) return false;
    final age = taxYear - d.year;
    if (isFullTimeStudent) return age < 24;
    return age < 19;
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'ssn': ssn,
        'relationship': relationship,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'isFullTimeStudent': isFullTimeStudent,
        'permanentlyDisabled': permanentlyDisabled,
        'monthsLivedWithYou': monthsLivedWithYou,
        'isUsCitizen': isUsCitizen,
      };

  static Dependent fromJson(Map<String, dynamic> j) => Dependent(
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        ssn: j['ssn'] as String? ?? '',
        relationship: j['relationship'] as String? ?? '',
        dateOfBirth: j['dateOfBirth'] == null
            ? null
            : DateTime.tryParse(j['dateOfBirth'] as String),
        isFullTimeStudent: j['isFullTimeStudent'] as bool? ?? false,
        permanentlyDisabled: j['permanentlyDisabled'] as bool? ?? false,
        monthsLivedWithYou: j['monthsLivedWithYou'] as int? ?? 12,
        isUsCitizen: j['isUsCitizen'] as bool? ?? true,
      );
}

/// Form W-2 wage entry.
class W2Entry {
  String employerName;
  String employerEin;
  double wages; // Box 1
  double federalWithholding; // Box 2
  double ssWages; // Box 3 (needed for SE tax wage-base offset)
  double ssWithholding; // Box 4
  double medicareWithholding; // Box 6
  /// OBBBA qualified tips as reported by the employer (2025-2028).
  double qualifiedTips;
  /// OBBBA qualified FLSA overtime premium pay (2025-2028).
  double qualifiedOvertime;

  W2Entry({
    this.employerName = '',
    this.employerEin = '',
    this.wages = 0,
    this.federalWithholding = 0,
    this.ssWages = 0,
    this.ssWithholding = 0,
    this.medicareWithholding = 0,
    this.qualifiedTips = 0,
    this.qualifiedOvertime = 0,
  });

  Map<String, dynamic> toJson() => {
        'employerName': employerName,
        'employerEin': employerEin,
        'wages': wages,
        'federalWithholding': federalWithholding,
        'ssWages': ssWages,
        'ssWithholding': ssWithholding,
        'medicareWithholding': medicareWithholding,
        'qualifiedTips': qualifiedTips,
        'qualifiedOvertime': qualifiedOvertime,
      };

  static W2Entry fromJson(Map<String, dynamic> j) => W2Entry(
        employerName: j['employerName'] as String? ?? '',
        employerEin: j['employerEin'] as String? ?? '',
        wages: (j['wages'] as num?)?.toDouble() ?? 0,
        federalWithholding: (j['federalWithholding'] as num?)?.toDouble() ?? 0,
        ssWages: (j['ssWages'] as num?)?.toDouble() ?? 0,
        ssWithholding: (j['ssWithholding'] as num?)?.toDouble() ?? 0,
        medicareWithholding: (j['medicareWithholding'] as num?)?.toDouble() ?? 0,
        qualifiedTips: (j['qualifiedTips'] as num?)?.toDouble() ?? 0,
        qualifiedOvertime: (j['qualifiedOvertime'] as num?)?.toDouble() ?? 0,
      );
}

class InterestIncome {
  String payer;
  double taxableInterest; // 1099-INT box 1
  double taxExemptInterest; // box 8

  InterestIncome({this.payer = '', this.taxableInterest = 0, this.taxExemptInterest = 0});

  Map<String, dynamic> toJson() =>
      {'payer': payer, 'taxableInterest': taxableInterest, 'taxExemptInterest': taxExemptInterest};

  static InterestIncome fromJson(Map<String, dynamic> j) => InterestIncome(
        payer: j['payer'] as String? ?? '',
        taxableInterest: (j['taxableInterest'] as num?)?.toDouble() ?? 0,
        taxExemptInterest: (j['taxExemptInterest'] as num?)?.toDouble() ?? 0,
      );
}

class DividendIncome {
  String payer;
  double ordinaryDividends; // 1099-DIV box 1a
  double qualifiedDividends; // box 1b

  DividendIncome({this.payer = '', this.ordinaryDividends = 0, this.qualifiedDividends = 0});

  Map<String, dynamic> toJson() => {
        'payer': payer,
        'ordinaryDividends': ordinaryDividends,
        'qualifiedDividends': qualifiedDividends,
      };

  static DividendIncome fromJson(Map<String, dynamic> j) => DividendIncome(
        payer: j['payer'] as String? ?? '',
        ordinaryDividends: (j['ordinaryDividends'] as num?)?.toDouble() ?? 0,
        qualifiedDividends: (j['qualifiedDividends'] as num?)?.toDouble() ?? 0,
      );
}

/// A sale from 1099-B / Schedule D.
class CapitalGainEntry {
  String description;
  double proceeds;
  double costBasis;
  bool isLongTerm;

  CapitalGainEntry({
    this.description = '',
    this.proceeds = 0,
    this.costBasis = 0,
    this.isLongTerm = false,
  });

  double get gain => proceeds - costBasis;

  Map<String, dynamic> toJson() => {
        'description': description,
        'proceeds': proceeds,
        'costBasis': costBasis,
        'isLongTerm': isLongTerm,
      };

  static CapitalGainEntry fromJson(Map<String, dynamic> j) => CapitalGainEntry(
        description: j['description'] as String? ?? '',
        proceeds: (j['proceeds'] as num?)?.toDouble() ?? 0,
        costBasis: (j['costBasis'] as num?)?.toDouble() ?? 0,
        isLongTerm: j['isLongTerm'] as bool? ?? false,
      );
}

/// Schedule C net profit (1099-NEC/K income).
class SelfEmploymentIncome {
  String businessName;
  double netProfit;
  /// Qualified tips earned as an independent contractor (OBBBA, 2025-2028).
  double qualifiedTips;
  double seHealthInsurancePremiums;
  double sepSimpleContributions;

  SelfEmploymentIncome({
    this.businessName = '',
    this.netProfit = 0,
    this.qualifiedTips = 0,
    this.seHealthInsurancePremiums = 0,
    this.sepSimpleContributions = 0,
  });

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'netProfit': netProfit,
        'qualifiedTips': qualifiedTips,
        'seHealthInsurancePremiums': seHealthInsurancePremiums,
        'sepSimpleContributions': sepSimpleContributions,
      };

  static SelfEmploymentIncome fromJson(Map<String, dynamic> j) => SelfEmploymentIncome(
        businessName: j['businessName'] as String? ?? '',
        netProfit: (j['netProfit'] as num?)?.toDouble() ?? 0,
        qualifiedTips: (j['qualifiedTips'] as num?)?.toDouble() ?? 0,
        seHealthInsurancePremiums:
            (j['seHealthInsurancePremiums'] as num?)?.toDouble() ?? 0,
        sepSimpleContributions: (j['sepSimpleContributions'] as num?)?.toDouble() ?? 0,
      );
}

/// Form 1099-R distribution (IRA/pension).
class RetirementIncome {
  String payer;
  double grossDistribution;
  double taxableAmount;
  double federalWithholding;

  RetirementIncome({
    this.payer = '',
    this.grossDistribution = 0,
    this.taxableAmount = 0,
    this.federalWithholding = 0,
  });

  Map<String, dynamic> toJson() => {
        'payer': payer,
        'grossDistribution': grossDistribution,
        'taxableAmount': taxableAmount,
        'federalWithholding': federalWithholding,
      };

  static RetirementIncome fromJson(Map<String, dynamic> j) => RetirementIncome(
        payer: j['payer'] as String? ?? '',
        grossDistribution: (j['grossDistribution'] as num?)?.toDouble() ?? 0,
        taxableAmount: (j['taxableAmount'] as num?)?.toDouble() ?? 0,
        federalWithholding: (j['federalWithholding'] as num?)?.toDouble() ?? 0,
      );
}

/// Other income items (prizes, jury duty, gambling note, etc.).
class OtherIncomeItem {
  String description;
  double amount;

  OtherIncomeItem({this.description = '', this.amount = 0});

  Map<String, dynamic> toJson() => {'description': description, 'amount': amount};

  static OtherIncomeItem fromJson(Map<String, dynamic> j) => OtherIncomeItem(
        description: j['description'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
      );
}

class ItemizedDeductions {
  double medicalExpenses;
  /// State and local income + property taxes (SALT cap applies in engine).
  double saltTaxes;
  double mortgageInterest;
  double charitableCash;
  double charitableNonCash;

  ItemizedDeductions({
    this.medicalExpenses = 0,
    this.saltTaxes = 0,
    this.mortgageInterest = 0,
    this.charitableCash = 0,
    this.charitableNonCash = 0,
  });

  Map<String, dynamic> toJson() => {
        'medicalExpenses': medicalExpenses,
        'saltTaxes': saltTaxes,
        'mortgageInterest': mortgageInterest,
        'charitableCash': charitableCash,
        'charitableNonCash': charitableNonCash,
      };

  static ItemizedDeductions fromJson(Map<String, dynamic> j) => ItemizedDeductions(
        medicalExpenses: (j['medicalExpenses'] as num?)?.toDouble() ?? 0,
        saltTaxes: (j['saltTaxes'] as num?)?.toDouble() ?? 0,
        mortgageInterest: (j['mortgageInterest'] as num?)?.toDouble() ?? 0,
        charitableCash: (j['charitableCash'] as num?)?.toDouble() ?? 0,
        charitableNonCash: (j['charitableNonCash'] as num?)?.toDouble() ?? 0,
      );
}

/// Above-the-line adjustments (Schedule 1, Part II).
class Adjustments {
  double iraContributions;
  double studentLoanInterest;
  double hsaContributions;
  double educatorExpenses;
  double estimatedPayments;
  double unemploymentAmount;
  double unemploymentWithholding;

  Adjustments({
    this.iraContributions = 0,
    this.studentLoanInterest = 0,
    this.hsaContributions = 0,
    this.educatorExpenses = 0,
    this.estimatedPayments = 0,
    this.unemploymentAmount = 0,
    this.unemploymentWithholding = 0,
  });

  Map<String, dynamic> toJson() => {
        'iraContributions': iraContributions,
        'studentLoanInterest': studentLoanInterest,
        'hsaContributions': hsaContributions,
        'educatorExpenses': educatorExpenses,
        'estimatedPayments': estimatedPayments,
        'unemploymentAmount': unemploymentAmount,
        'unemploymentWithholding': unemploymentWithholding,
      };

  static Adjustments fromJson(Map<String, dynamic> j) => Adjustments(
        iraContributions: (j['iraContributions'] as num?)?.toDouble() ?? 0,
        studentLoanInterest: (j['studentLoanInterest'] as num?)?.toDouble() ?? 0,
        hsaContributions: (j['hsaContributions'] as num?)?.toDouble() ?? 0,
        educatorExpenses: (j['educatorExpenses'] as num?)?.toDouble() ?? 0,
        estimatedPayments: (j['estimatedPayments'] as num?)?.toDouble() ?? 0,
        unemploymentAmount: (j['unemploymentAmount'] as num?)?.toDouble() ?? 0,
        unemploymentWithholding: (j['unemploymentWithholding'] as num?)?.toDouble() ?? 0,
      );
}

class CreditsInputs {
  double childCareExpenses;
  double aotcQualifiedExpenses; // Form 1098-T qualified amounts (max 4,000)
  double llcQualifiedExpenses; // Lifetime learning (max 10,000)
  /// Retirement contributions counted for the Saver's Credit
  /// (IRA + workplace plan amounts not already excluded from wages).
  double saversCreditContributions;

  CreditsInputs({
    this.childCareExpenses = 0,
    this.aotcQualifiedExpenses = 0,
    this.llcQualifiedExpenses = 0,
    this.saversCreditContributions = 0,
  });

  Map<String, dynamic> toJson() => {
        'childCareExpenses': childCareExpenses,
        'aotcQualifiedExpenses': aotcQualifiedExpenses,
        'llcQualifiedExpenses': llcQualifiedExpenses,
        'saversCreditContributions': saversCreditContributions,
      };

  static CreditsInputs fromJson(Map<String, dynamic> j) => CreditsInputs(
        childCareExpenses: (j['childCareExpenses'] as num?)?.toDouble() ?? 0,
        aotcQualifiedExpenses: (j['aotcQualifiedExpenses'] as num?)?.toDouble() ?? 0,
        llcQualifiedExpenses: (j['llcQualifiedExpenses'] as num?)?.toDouble() ?? 0,
        saversCreditContributions: (j['saversCreditContributions'] as num?)?.toDouble() ?? 0,
      );
}

/// The complete return as entered by the user.
class TaxReturnData {
  int taxYear;
  FilingStatus filingStatus;
  Person taxpayer;
  Person? spouse; // required for MFJ / MFS / QSS
  List<Dependent> dependents;
  List<W2Entry> w2s;
  List<InterestIncome> interest;
  List<DividendIncome> dividends;
  List<CapitalGainEntry> capitalGains;
  List<SelfEmploymentIncome> selfEmployment;
  List<RetirementIncome> retirement;
  double socialSecurityBenefits; // household total (SSA-1099)
  List<OtherIncomeItem> otherIncome;
  ItemizedDeductions itemized;
  Adjustments adjustments;
  CreditsInputs credits;
  bool canBeClaimedByAnother;
  /// OBBBA qualified car-loan interest (2025-2028, Form 1098 or lender statement).
  double qualifiedCarLoanInterest;

  TaxReturnData({
    this.taxYear = 2025,
    this.filingStatus = FilingStatus.single,
    Person? taxpayer,
    this.spouse,
    List<Dependent>? dependents,
    List<W2Entry>? w2s,
    List<InterestIncome>? interest,
    List<DividendIncome>? dividends,
    List<CapitalGainEntry>? capitalGains,
    List<SelfEmploymentIncome>? selfEmployment,
    List<RetirementIncome>? retirement,
    this.socialSecurityBenefits = 0,
    List<OtherIncomeItem>? otherIncome,
    ItemizedDeductions? itemized,
    Adjustments? adjustments,
    CreditsInputs? credits,
    this.canBeClaimedByAnother = false,
    this.qualifiedCarLoanInterest = 0,
  })  : taxpayer = taxpayer ?? Person(),
        dependents = dependents ?? [],
        w2s = w2s ?? [],
        interest = interest ?? [],
        dividends = dividends ?? [],
        capitalGains = capitalGains ?? [],
        selfEmployment = selfEmployment ?? [],
        retirement = retirement ?? [],
        otherIncome = otherIncome ?? [],
        itemized = itemized ?? ItemizedDeductions(),
        adjustments = adjustments ?? Adjustments(),
        credits = credits ?? CreditsInputs();

  TaxReturnData copyWith({
    int? taxYear,
    FilingStatus? filingStatus,
    Person? taxpayer,
    Person? spouse,
    bool clearSpouse = false,
    List<Dependent>? dependents,
    List<W2Entry>? w2s,
    List<InterestIncome>? interest,
    List<DividendIncome>? dividends,
    List<CapitalGainEntry>? capitalGains,
    List<SelfEmploymentIncome>? selfEmployment,
    List<RetirementIncome>? retirement,
    double? socialSecurityBenefits,
    List<OtherIncomeItem>? otherIncome,
    ItemizedDeductions? itemized,
    Adjustments? adjustments,
    CreditsInputs? credits,
    bool? canBeClaimedByAnother,
    double? qualifiedCarLoanInterest,
  }) {
    return TaxReturnData(
      taxYear: taxYear ?? this.taxYear,
      filingStatus: filingStatus ?? this.filingStatus,
      taxpayer: taxpayer ?? this.taxpayer,
      spouse: clearSpouse ? null : (spouse ?? this.spouse),
      dependents: dependents ?? this.dependents,
      w2s: w2s ?? this.w2s,
      interest: interest ?? this.interest,
      dividends: dividends ?? this.dividends,
      capitalGains: capitalGains ?? this.capitalGains,
      selfEmployment: selfEmployment ?? this.selfEmployment,
      retirement: retirement ?? this.retirement,
      socialSecurityBenefits: socialSecurityBenefits ?? this.socialSecurityBenefits,
      otherIncome: otherIncome ?? this.otherIncome,
      itemized: itemized ?? this.itemized,
      adjustments: adjustments ?? this.adjustments,
      credits: credits ?? this.credits,
      canBeClaimedByAnother: canBeClaimedByAnother ?? this.canBeClaimedByAnother,
      qualifiedCarLoanInterest: qualifiedCarLoanInterest ?? this.qualifiedCarLoanInterest,
    );
  }

  Map<String, dynamic> toJson() => {
        'schema': 'nitro-nissi/nnx',
        'schemaVersion': 1,
        'taxYear': taxYear,
        'filingStatus': filingStatus.toJson(),
        'taxpayer': taxpayer.toJson(),
        'spouse': spouse?.toJson(),
        'dependents': dependents.map((d) => d.toJson()).toList(),
        'w2s': w2s.map((w) => w.toJson()).toList(),
        'interest': interest.map((i) => i.toJson()).toList(),
        'dividends': dividends.map((d) => d.toJson()).toList(),
        'capitalGains': capitalGains.map((c) => c.toJson()).toList(),
        'selfEmployment': selfEmployment.map((s) => s.toJson()).toList(),
        'retirement': retirement.map((r) => r.toJson()).toList(),
        'socialSecurityBenefits': socialSecurityBenefits,
        'otherIncome': otherIncome.map((o) => o.toJson()).toList(),
        'itemized': itemized.toJson(),
        'adjustments': adjustments.toJson(),
        'credits': credits.toJson(),
        'canBeClaimedByAnother': canBeClaimedByAnother,
        'qualifiedCarLoanInterest': qualifiedCarLoanInterest,
      };

  static TaxReturnData fromJson(Map<String, dynamic> j) => TaxReturnData(
        taxYear: j['taxYear'] as int? ?? 2025,
        filingStatus: FilingStatus.fromJson(j['filingStatus'] as String? ?? 'single'),
        taxpayer: Person.fromJson((j['taxpayer'] as Map?)?.cast<String, dynamic>() ?? {}),
        spouse: j['spouse'] == null
            ? null
            : Person.fromJson((j['spouse'] as Map).cast<String, dynamic>()),
        dependents: (j['dependents'] as List?)
                ?.map((d) => Dependent.fromJson((d as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        w2s: (j['w2s'] as List?)
                ?.map((w) => W2Entry.fromJson((w as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        interest: (j['interest'] as List?)
                ?.map((i) => InterestIncome.fromJson((i as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        dividends: (j['dividends'] as List?)
                ?.map((d) => DividendIncome.fromJson((d as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        capitalGains: (j['capitalGains'] as List?)
                ?.map((c) => CapitalGainEntry.fromJson((c as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        selfEmployment: (j['selfEmployment'] as List?)
                ?.map((s) => SelfEmploymentIncome.fromJson((s as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        retirement: (j['retirement'] as List?)
                ?.map((r) => RetirementIncome.fromJson((r as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        socialSecurityBenefits: (j['socialSecurityBenefits'] as num?)?.toDouble() ?? 0,
        otherIncome: (j['otherIncome'] as List?)
                ?.map((o) => OtherIncomeItem.fromJson((o as Map).cast<String, dynamic>()))
                .toList() ??
            [],
        itemized: ItemizedDeductions.fromJson(
            (j['itemized'] as Map?)?.cast<String, dynamic>() ?? {}),
        adjustments:
            Adjustments.fromJson((j['adjustments'] as Map?)?.cast<String, dynamic>() ?? {}),
        credits: CreditsInputs.fromJson((j['credits'] as Map?)?.cast<String, dynamic>() ?? {}),
        canBeClaimedByAnother: j['canBeClaimedByAnother'] as bool? ?? false,
        qualifiedCarLoanInterest: (j['qualifiedCarLoanInterest'] as num?)?.toDouble() ?? 0,
      );

  String serialize() => const JsonEncoder.withIndent('  ').convert(toJson());

  static TaxReturnData deserialize(String text) =>
      TaxReturnData.fromJson((jsonDecode(text) as Map).cast<String, dynamic>());
}
