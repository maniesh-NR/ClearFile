/// TY2024 federal parameters.
///
/// Sources (verified):
///  - Rev. Proc. 2023-34 (2024 inflation adjustments): brackets, standard
///    deduction, LTCG breakpoints, saver's credit bands, student-loan-interest
///    phaseout, SE wage base ($168,600), EITC parameters.
///  - IRS "EITC Tables" page (irs.gov): EITC max credits / max-AGI / investment
///    income limit for 2024.
///  - Form 8995-A instructions / Rev. Proc.: QBI thresholds 2024
///    ($191,950 other / $383,900 MFJ).
///  - IRC §24 / Form 8812: CTC $2,000, refundable ACTC max $1,700 (2024).
library;

import 'engine.dart';

const YearParams params2024 = YearParams(
  year: 2024,
  // Ordinary brackets: [rate, upper bound of bracket for single,
  //  MFJ, HOH, MFS] — upper bound is INCLUSIVE top of the bracket.
  brackets: [
    [0.10, 11600, 23200, 16550, 11600],
    [0.12, 47150, 94300, 63100, 47150],
    [0.22, 100525, 201050, 100500, 100525],
    [0.24, 191950, 383900, 191950, 191950],
    [0.32, 243725, 487450, 243700, 243725],
    [0.35, 609350, 731200, 609350, 365600],
    [0.37, double.infinity, double.infinity, double.infinity, double.infinity],
  ],
  standardDeduction: [14600, 29200, 21900, 14600],
  // Additional standard deduction per 65+/blind box:
  // single/HOH $1,950; MFJ/MFS/QSS $1,550 per person (Rev. Proc. 2023-34).
  additionalStdDeductionSingle: 1950,
  additionalStdDeductionMarried: 1550,
  // Dependent standard deduction floor: greater of $1,300 or earned + $450.
  dependentStdFloor: 1300,
  dependentStdEarnedAdd: 450,
  // LTCG / qualified dividends breakpoints (single, MFJ, HOH, MFS).
  ltcgZeroUpTo: [47025, 94050, 63000, 47025],
  ltcgFifteenUpTo: [518900, 583750, 551350, 291850],
  // NIIT thresholds (single/HOH, MFJ/QSS, MFS).
  niitThresholds: [200000, 250000, 125000],
  // Additional Medicare tax 0.9% thresholds.
  addlMedicareThresholds: [200000, 250000, 125000],
  // EITC (IRS 2024 tables).
  eitcMaxCredits: [632, 4213, 6960, 7830],
  eitcPhaseoutStartSingle: [10330, 22720, 22720, 22720],
  eitcPhaseoutStartMfjBonus: [6920, 6920, 6920, 6920],
  eitcPhaseoutEndSingle: [18591, 49084, 55768, 59899],
  eitcPhaseoutRates: [0.0765, 0.1598, 0.2106, 0.2106],
  eitcPhaseInRates: [0.0765, 0.34, 0.40, 0.45],
  eitcInvestmentIncomeLimit: 11600,
  // CTC / ACTC (Form 8812).
  ctcPerChild: 2000,
  ctcRefundableMaxPerChild: 1700,
  ctcPhaseoutStartSingle: 200000,
  ctcPhaseoutStartMfj: 400000,
  ctcRefundableEarnedFloor: 2500,
  ctcRefundableRate: 0.15,
  // QBI (§199A / Form 8995).
  qbiThresholdOther: 191950,
  qbiThresholdMfj: 383900,
  qbiPhaseInOther: 50000,
  qbiPhaseInMfj: 100000,
  // Education credits (AOTC/LLC) phaseout ranges.
  edCreditPhaseoutStartSingle: 80000,
  edCreditPhaseoutStartMfj: 160000,
  // Student loan interest deduction phaseout (Rev. Proc. 2023-34).
  slInterestPhaseoutStartSingle: 80000,
  slInterestPhaseoutEndSingle: 95000,
  slInterestPhaseoutStartMfj: 165000,
  slInterestPhaseoutEndMfj: 195000,
  // Saver's credit AGI bands: 50% / 20% / 10% cutoffs
  // [single/HOH, MFJ] for each band boundary (Rev. Proc. 2023-34).
  saversCreditBands: [
    [23000, 46000], // 50% up to
    [25000, 50000], // 20% up to
    [38500, 77000], // 10% up to
  ],
  // SE tax.
  seWageBase: 168600,
  // SALT cap (TCJA baseline for 2024).
  saltCap: 10000,
  saltCapPhaseDownStart: null, // OBBBA phase-down begins 2025
  saltCapFloor: 10000,
  // OBBBA provisions (tips/overtime/senior/car-loan) begin in 2025.
  obbbaDeductionsActive: false,
  obbbaTipsCap: 0,
  obbbaOvertimeCapSingle: 0,
  obbbaOvertimeCapMfj: 0,
  obbbaSeniorDeduction: 0,
  obbbaHighIncomePhaseoutStart: null,
  obbbaCarLoanCap: 0,
);
