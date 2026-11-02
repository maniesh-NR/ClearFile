/// TY2025 federal parameters.
///
/// Sources (verified):
///  - Rev. Proc. 2024-40 (2025 inflation adjustments) and the Tax Foundation
///    2025 bracket tables: brackets; standard deduction later increased by
///    OBBBA (below); LTCG breakpoints; SE wage base ($176,100);
///    student-loan-interest phaseout (85k-100k S / 175k-200k MFJ);
///    saver's credit bands; EITC ends/investment-income limit.
///  - IRS "EITC Tables" page (irs.gov), fetched for TY2025: max credits
///    649/4,328/7,152/8,046; max AGI ends; investment income limit $11,950.
///  - One Big Beautiful Bill Act (P.L. 119-21, July 2025), per IRS newsroom /
///    H&R Block / Tax Policy Center / IRS VITA materials:
///    * Standard deduction raised to $15,750 / $31,500 / $23,625.
///    * Additional 65+/blind: $2,000 (S/HOH) / $1,600 (MFJ/QSS).
///    * Senior deduction $6,000 (2025-2028), phases out 6% over $75k (S) /
///      $150k (MFJ) MAGI; MFS ineligible.
///    * Qualified tips deduction up to $25,000; overtime up to $12,500
///      ($25,000 MFJ); both phase out $100 per $1,000 MAGI over
///      $150,000 S / $300,000 MFJ.
///    * Qualified car-loan-interest deduction up to $10,000, phased out
///      $200 per $1,000 MAGI over $100,000 S / $200,000 MFJ (OBBBA §70208).
///    * SALT cap temporarily raised $10,000 → $40,000 (2025-2029), reduced
///      30% of MAGI over $500,000, floor $10,000 (MFS: half amounts).
///    * CTC $2,200 per child; refundable ACTC max $1,700 (2025).
///  - Form 8995-A 2025 instructions: QBI thresholds $197,300 other /
///    $394,600 MFJ.
library;

import 'engine.dart';

const YearParams params2025 = YearParams(
  year: 2025,
  brackets: [
    [0.10, 11925, 23850, 17000, 11925],
    [0.12, 48475, 96950, 64850, 48475],
    [0.22, 103350, 206700, 103350, 103350],
    [0.24, 197300, 394600, 197300, 197300],
    [0.32, 250500, 501050, 250500, 250500],
    [0.35, 626350, 751600, 626350, 375800],
    [0.37, double.infinity, double.infinity, double.infinity, double.infinity],
  ],
  // OBBBA-raised amounts (base standard deduction).
  standardDeduction: [15750, 31500, 23625, 15750],
  additionalStdDeductionSingle: 2000,
  additionalStdDeductionMarried: 1600,
  dependentStdFloor: 1350,
  dependentStdEarnedAdd: 450,
  ltcgZeroUpTo: [48350, 96700, 64750, 48350],
  ltcgFifteenUpTo: [533400, 600050, 566700, 291850],
  niitThresholds: [200000, 250000, 125000],
  addlMedicareThresholds: [200000, 250000, 125000],
  // EITC (IRS 2025 tables). Phaseout starts derived from the IRS published
  // end points and statutory rates (see TAX_ENGINE.md); they match the
  // published starts within the IRS table rounding (±$50).
  eitcMaxCredits: [649, 4328, 7152, 8046],
  eitcPhaseoutStartSingle: [10620, 23350, 23350, 23350],
  eitcPhaseoutStartMfjBonus: [7110, 7120, 7120, 7120],
  eitcPhaseoutEndSingle: [19104, 50434, 57310, 61555],
  eitcPhaseoutRates: [0.0765, 0.1598, 0.2106, 0.2106],
  eitcPhaseInRates: [0.0765, 0.34, 0.40, 0.45],
  eitcInvestmentIncomeLimit: 11950,
  // CTC / ACTC (OBBBA).
  ctcPerChild: 2200,
  ctcRefundableMaxPerChild: 1700,
  ctcPhaseoutStartSingle: 200000,
  ctcPhaseoutStartMfj: 400000,
  ctcRefundableEarnedFloor: 2500,
  ctcRefundableRate: 0.15,
  // QBI (Form 8995-A 2025 instructions).
  qbiThresholdOther: 197300,
  qbiThresholdMfj: 394600,
  qbiPhaseInOther: 50000,
  qbiPhaseInMfj: 100000,
  edCreditPhaseoutStartSingle: 80000,
  edCreditPhaseoutStartMfj: 160000,
  // Student loan interest (Rev. Proc. 2024-40).
  slInterestPhaseoutStartSingle: 85000,
  slInterestPhaseoutEndSingle: 100000,
  slInterestPhaseoutStartMfj: 175000,
  slInterestPhaseoutEndMfj: 200000,
  // Saver's credit bands 2025 (Rev. Proc. 2024-40): [S/HOH, MFJ].
  saversCreditBands: [
    [23750, 47500],
    [25750, 51500],
    [39500, 79000],
  ],
  seWageBase: 176100,
  // SALT cap: OBBBA temporarily raises to $40,000 for 2025, reduced 30% of
  // MAGI over $500,000, floor $10,000. MFS uses half amounts.
  saltCap: 40000,
  saltCapPhaseDownStart: 500000,
  saltCapFloor: 10000,
  // OBBBA individual deductions (2025-2028).
  obbbaDeductionsActive: true,
  obbbaTipsCap: 25000,
  obbbaOvertimeCapSingle: 12500,
  obbbaOvertimeCapMfj: 25000,
  obbbaSeniorDeduction: 6000,
  obbbaHighIncomePhaseoutStart: 150000, // S; MFJ = 2x (tips/overtime)
  obbbaCarLoanCap: 10000,
);
