import 'filing_status.dart';

/// One rung of a progressive rate schedule.
class Bracket {
  const Bracket(this.rate, this.upTo);

  /// Marginal rate, e.g. 0.10 for 10%.
  final double rate;

  /// Upper bound of taxable income for this rung (inclusive).
  /// The final rung uses [double.infinity].
  final double upTo;
}

/// All federal parameters the demo engine needs for one tax year.
///
/// TY2025 values were cross-checked in November 2026 against:
///  * IRS VITA "Standard Deduction" page (basic and 65+/blind amounts, OBBBA):
///    https://apps.irs.gov/app/vita/content/00/00_13_005.jsp
///  * Tax Foundation 2025 brackets (rates, SALT phase-down, senior deduction):
///    https://taxfoundation.org/data/all/federal/2025-tax-brackets/
///  * IRS newsroom, enhanced senior deduction (P.L. 119-21 / OBBBA):
///    https://www.irs.gov/newsroom/check-your-eligibility-for-the-new-enhanced-deduction-for-seniors
///  * IRS Form 1040 instructions, Qualified Dividends worksheet breakpoints:
///    https://www.irs.gov/instructions/i1040gi
///  * H&R Block & Jackson Hewitt TY2025 pages (student loan interest phaseouts).
///
/// DEMO SOFTWARE: verify every number against official IRS tables before
/// relying on any calculation produced with this class.
class TaxYearParameters {
  const TaxYearParameters({
    required this.year,
    required this.standardDeduction,
    required this.additionalPerAgedOrBlindPerson,
    required this.seniorDeductionPerPerson,
    required this.seniorPhaseoutStart,
    this.seniorPhaseoutRate = 0.06,
    required this.ordinaryBrackets,
    required this.qdiZeroCap,
    required this.qdiFifteenCap,
    required this.saltBaseCap,
    required this.saltPhaseoutStart,
    this.saltPhaseoutRate = 0.30,
    required this.saltFloor,
    this.niitRate = 0.038,
    required this.niitThreshold,
    required this.ctcPerChild,
    required this.actcPerChild,
    this.actcRate = 0.15,
    this.actcEarnedIncomeFloor = 2500,
    required this.ctcPhaseoutStart,
    this.ctcPhaseoutRate = 0.05,
    required this.odcPerDependent,
    required this.studentLoanMax,
    required this.studentLoanPhaseoutStart,
    required this.studentLoanPhaseoutEnd,
    this.charitableCashAgiLimit = 0.60,
    this.charitableNonCashAgiLimit = 0.30,
  });

  final int year;

  /// Basic standard deduction by filing status (OBBBA amounts for 2025).
  final Map<FilingStatus, double> standardDeduction;

  /// Additional standard deduction per person who is 65+ or blind
  /// (standard-deduction route only). IRS VITA: $2,000 single/HoH,
  /// $1,600 married per person for 2025.
  final Map<FilingStatus, double> additionalPerAgedOrBlindPerson;

  /// OBBBA "senior deduction": $6,000 per person 65+ for 2025-2028, usable
  /// with the standard deduction OR itemizing, phased out at 6% of MAGI over
  /// the phaseout start.
  final double seniorDeductionPerPerson;
  final Map<FilingStatus, double> seniorPhaseoutStart;
  final double seniorPhaseoutRate;

  /// Ordinary income rate schedules.
  final Map<FilingStatus, List<Bracket>> ordinaryBrackets;

  /// Qualified dividends / net long-term capital gains: top of the 0% band
  /// and top of the 15% band, by filing status (stacked on ordinary income).
  final Map<FilingStatus, double> qdiZeroCap;
  final Map<FilingStatus, double> qdiFifteenCap;

  /// SALT cap (OBBBA): $40,000 for 2025 ($20,000 MFS), reduced by 30% of
  /// MAGI over the phaseout start, never below the floor.
  final Map<FilingStatus, double> saltBaseCap;
  final Map<FilingStatus, double> saltPhaseoutStart;
  final double saltPhaseoutRate;
  final Map<FilingStatus, double> saltFloor;

  /// Net investment income tax (simplified: applied to interest, dividends
  /// and capital gains).
  final double niitRate;
  final Map<FilingStatus, double> niitThreshold;

  /// Child Tax Credit / Additional Child Tax Credit (OBBBA: $2,200 per child
  /// for 2025, up to $1,700 per child refundable).
  final double ctcPerChild;
  final double actcPerChild;
  final double actcRate;
  final double actcEarnedIncomeFloor;
  final Map<FilingStatus, double> ctcPhaseoutStart;
  final double ctcPhaseoutRate;

  /// Credit for other dependents.
  final double odcPerDependent;

  /// Student loan interest deduction.
  final double studentLoanMax;
  final Map<FilingStatus, double> studentLoanPhaseoutStart;
  final Map<FilingStatus, double> studentLoanPhaseoutEnd;

  /// Charitable deduction AGI ceilings (simplified).
  final double charitableCashAgiLimit;
  final double charitableNonCashAgiLimit;

  /// Sources shown in the app's About screen.
  static const List<String> parameterSources = [
    'https://apps.irs.gov/app/vita/content/00/00_13_005.jsp',
    'https://taxfoundation.org/data/all/federal/2025-tax-brackets/',
    'https://www.irs.gov/newsroom/check-your-eligibility-for-the-new-enhanced-deduction-for-seniors',
    'https://www.irs.gov/instructions/i1040gi',
    'https://www.irs.gov/taxtopics/tc456',
    'https://www.congress.gov/bill/119th-congress/house-bill/1',
  ];

  double saltCapFor(FilingStatus status, double magi) {
    final base = saltBaseCap[status]!;
    final start = saltPhaseoutStart[status]!;
    final floor = saltFloor[status]!;
    if (magi <= start) return base;
    final reduced = base - saltPhaseoutRate * (magi - start);
    return reduced < floor ? floor : reduced;
  }

  /// Width of the student loan interest phase-out band (0 means ineligible).
  double studentLoanPhaseoutWidth(FilingStatus status) =>
      (studentLoanPhaseoutEnd[status] ?? 0) -
      (studentLoanPhaseoutStart[status] ?? 0);

  static const TaxYearParameters ty2025 = TaxYearParameters(
    year: 2025,
    standardDeduction: {
      FilingStatus.single: 15750,
      FilingStatus.marriedJoint: 31500,
      FilingStatus.marriedSeparate: 15750,
      FilingStatus.headOfHousehold: 23625,
      FilingStatus.survivingSpouse: 31500,
    },
    additionalPerAgedOrBlindPerson: {
      FilingStatus.single: 2000,
      FilingStatus.marriedJoint: 1600,
      FilingStatus.marriedSeparate: 1600,
      FilingStatus.headOfHousehold: 2000,
      FilingStatus.survivingSpouse: 1600,
    },
    seniorDeductionPerPerson: 6000,
    seniorPhaseoutStart: {
      FilingStatus.single: 75000,
      FilingStatus.marriedSeparate: 75000,
      FilingStatus.headOfHousehold: 75000,
      FilingStatus.marriedJoint: 150000,
      FilingStatus.survivingSpouse: 150000,
    },
    ordinaryBrackets: {
      FilingStatus.single: [
        Bracket(0.10, 11925),
        Bracket(0.12, 48475),
        Bracket(0.22, 103350),
        Bracket(0.24, 197300),
        Bracket(0.32, 250525),
        Bracket(0.35, 626350),
        Bracket(0.37, double.infinity),
      ],
      FilingStatus.marriedJoint: [
        Bracket(0.10, 23850),
        Bracket(0.12, 96950),
        Bracket(0.22, 206700),
        Bracket(0.24, 394600),
        Bracket(0.32, 501050),
        Bracket(0.35, 751600),
        Bracket(0.37, double.infinity),
      ],
      FilingStatus.marriedSeparate: [
        Bracket(0.10, 11925),
        Bracket(0.12, 48475),
        Bracket(0.22, 103350),
        Bracket(0.24, 197300),
        Bracket(0.32, 250525),
        Bracket(0.35, 375800),
        Bracket(0.37, double.infinity),
      ],
      FilingStatus.headOfHousehold: [
        Bracket(0.10, 17000),
        Bracket(0.12, 64850),
        Bracket(0.22, 103350),
        Bracket(0.24, 197300),
        Bracket(0.32, 250500),
        Bracket(0.35, 626350),
        Bracket(0.37, double.infinity),
      ],
      FilingStatus.survivingSpouse: [
        Bracket(0.10, 23850),
        Bracket(0.12, 96950),
        Bracket(0.22, 206700),
        Bracket(0.24, 394600),
        Bracket(0.32, 501050),
        Bracket(0.35, 751600),
        Bracket(0.37, double.infinity),
      ],
    },
    qdiZeroCap: {
      FilingStatus.single: 48350,
      FilingStatus.marriedJoint: 96700,
      FilingStatus.marriedSeparate: 48350,
      FilingStatus.headOfHousehold: 64750,
      FilingStatus.survivingSpouse: 96700,
    },
    qdiFifteenCap: {
      FilingStatus.single: 533400,
      FilingStatus.marriedJoint: 600050,
      FilingStatus.marriedSeparate: 300025,
      FilingStatus.headOfHousehold: 566700,
      FilingStatus.survivingSpouse: 600050,
    },
    saltBaseCap: {
      FilingStatus.single: 40000,
      FilingStatus.marriedJoint: 40000,
      FilingStatus.marriedSeparate: 20000,
      FilingStatus.headOfHousehold: 40000,
      FilingStatus.survivingSpouse: 40000,
    },
    saltPhaseoutStart: {
      FilingStatus.single: 500000,
      FilingStatus.marriedJoint: 500000,
      FilingStatus.marriedSeparate: 250000,
      FilingStatus.headOfHousehold: 500000,
      FilingStatus.survivingSpouse: 500000,
    },
    saltFloor: {
      FilingStatus.single: 10000,
      FilingStatus.marriedJoint: 10000,
      FilingStatus.marriedSeparate: 5000,
      FilingStatus.headOfHousehold: 10000,
      FilingStatus.survivingSpouse: 10000,
    },
    niitThreshold: {
      FilingStatus.single: 200000,
      FilingStatus.marriedSeparate: 200000,
      FilingStatus.headOfHousehold: 200000,
      FilingStatus.marriedJoint: 250000,
      FilingStatus.survivingSpouse: 250000,
    },
    ctcPerChild: 2200,
    actcPerChild: 1700,
    ctcPhaseoutStart: {
      FilingStatus.single: 200000,
      FilingStatus.marriedSeparate: 200000,
      FilingStatus.headOfHousehold: 200000,
      FilingStatus.marriedJoint: 400000,
      FilingStatus.survivingSpouse: 400000,
    },
    odcPerDependent: 500,
    studentLoanMax: 2500,
    studentLoanPhaseoutStart: {
      FilingStatus.single: 85000,
      FilingStatus.headOfHousehold: 85000,
      FilingStatus.survivingSpouse: 85000,
      FilingStatus.marriedJoint: 170000,
      // Married filing separately is not eligible; start > end encodes that.
      FilingStatus.marriedSeparate: 1,
    },
    studentLoanPhaseoutEnd: {
      FilingStatus.single: 100000,
      FilingStatus.headOfHousehold: 100000,
      FilingStatus.survivingSpouse: 100000,
      FilingStatus.marriedJoint: 200000,
      FilingStatus.marriedSeparate: 0,
    },
  );
}
