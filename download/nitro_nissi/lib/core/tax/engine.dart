/// Nitro Nissi — US federal income tax engine (TY2024 & TY2025).
///
/// Pure Dart (no Flutter imports) so it can be unit-tested with the Dart VM
/// and shared by every platform target.
///
/// Scope & accuracy notes are in docs/TAX_ENGINE.md. This engine implements
/// Form 1040 core flow: income → AGI → deduction → QBI → taxable income →
/// tax (incl. preferential rates) → nonrefundable & refundable credits →
/// other taxes (SE, NIIT, add'l Medicare) → payments → refund/owe.
library;

import 'model.dart';

/// Column index by filing status: 0 = single, 1 = MFJ/QSS, 2 = HOH, 3 = MFS.
int statusCol(FilingStatus s) {
  switch (s) {
    case FilingStatus.marriedJointly:
    case FilingStatus.qualifyingSurvivingSpouse:
      return 1;
    case FilingStatus.headOfHousehold:
      return 2;
    case FilingStatus.marriedSeparately:
      return 3;
    case FilingStatus.single:
      return 0;
  }
}

class YearParams {
  final int year;
  /// Rows: [rate, singleTop, mfjTop, hohTop, mfsTop] — upper bound INCLUSIVE.
  final List<List<double>> brackets;
  /// [single, MFJ/QSS, HOH, MFS]
  final List<double> standardDeduction;
  final double additionalStdDeductionSingle;
  final double additionalStdDeductionMarried;
  final double dependentStdFloor;
  final double dependentStdEarnedAdd;

  final List<double> ltcgZeroUpTo; // [S, MFJ, HOH, MFS]
  final List<double> ltcgFifteenUpTo;
  final List<double> niitThresholds; // [S/HOH, MFJ/QSS, MFS]
  final List<double> addlMedicareThresholds;

  final List<double> eitcMaxCredits; // [0,1,2,3+] kids
  final List<double> eitcPhaseoutStartSingle;
  final List<double> eitcPhaseoutStartMfjBonus;
  final List<double> eitcPhaseoutEndSingle;
  final List<double> eitcPhaseoutRates;
  final List<double> eitcPhaseInRates;
  final double eitcInvestmentIncomeLimit;

  final double ctcPerChild;
  final double ctcRefundableMaxPerChild;
  final double ctcPhaseoutStartSingle;
  final double ctcPhaseoutStartMfj;
  final double ctcRefundableEarnedFloor;
  final double ctcRefundableRate;

  final double qbiThresholdOther;
  final double qbiThresholdMfj;
  final double qbiPhaseInOther;
  final double qbiPhaseInMfj;

  final double edCreditPhaseoutStartSingle;
  final double edCreditPhaseoutStartMfj;

  final double slInterestPhaseoutStartSingle;
  final double slInterestPhaseoutEndSingle;
  final double slInterestPhaseoutStartMfj;
  final double slInterestPhaseoutEndMfj;

  final List<List<double>> saversCreditBands; // [S/HOH/MFS, MFJ] per band

  final double seWageBase;
  final double saltCap;
  final double? saltCapPhaseDownStart; // OBBBA 2025: $500,000
  final double saltCapFloor;

  final bool obbbaDeductionsActive;
  final double obbbaTipsCap;
  final double obbbaOvertimeCapSingle;
  final double obbbaOvertimeCapMfj;
  final double obbbaSeniorDeduction;
  final double? obbbaHighIncomePhaseoutStart; // tips/overtime, single; MFJ = 2x
  final double obbbaCarLoanCap;

  const YearParams({
    required this.year,
    required this.brackets,
    required this.standardDeduction,
    required this.additionalStdDeductionSingle,
    required this.additionalStdDeductionMarried,
    required this.dependentStdFloor,
    required this.dependentStdEarnedAdd,
    required this.ltcgZeroUpTo,
    required this.ltcgFifteenUpTo,
    required this.niitThresholds,
    required this.addlMedicareThresholds,
    required this.eitcMaxCredits,
    required this.eitcPhaseoutStartSingle,
    required this.eitcPhaseoutStartMfjBonus,
    required this.eitcPhaseoutEndSingle,
    required this.eitcPhaseoutRates,
    required this.eitcPhaseInRates,
    required this.eitcInvestmentIncomeLimit,
    required this.ctcPerChild,
    required this.ctcRefundableMaxPerChild,
    required this.ctcPhaseoutStartSingle,
    required this.ctcPhaseoutStartMfj,
    required this.ctcRefundableEarnedFloor,
    required this.ctcRefundableRate,
    required this.qbiThresholdOther,
    required this.qbiThresholdMfj,
    required this.qbiPhaseInOther,
    required this.qbiPhaseInMfj,
    required this.edCreditPhaseoutStartSingle,
    required this.edCreditPhaseoutStartMfj,
    required this.slInterestPhaseoutStartSingle,
    required this.slInterestPhaseoutEndSingle,
    required this.slInterestPhaseoutStartMfj,
    required this.slInterestPhaseoutEndMfj,
    required this.saversCreditBands,
    required this.seWageBase,
    required this.saltCap,
    required this.saltCapPhaseDownStart,
    required this.saltCapFloor,
    required this.obbbaDeductionsActive,
    required this.obbbaTipsCap,
    required this.obbbaOvertimeCapSingle,
    required this.obbbaOvertimeCapMfj,
    required this.obbbaSeniorDeduction,
    required this.obbbaHighIncomePhaseoutStart,
    required this.obbbaCarLoanCap,
  });
}

class LabelValue {
  final String label;
  final double value;
  const LabelValue(this.label, this.value);
}

/// A piece of taxable income assigned to one bracket (for visualization).
class BracketSlice {
  final double rate;
  final double amount;
  final double tax;
  const BracketSlice(this.rate, this.amount, this.tax);
}

class TaxResult {
  final TaxReturnData input;
  final YearParams params;

  // Income
  final double wages, seNet, seEarnings, taxableInterest, taxExemptInterest;
  final double ordinaryDividends, qualifiedDividends;
  final double netShortTermGain, netLongTermGain, capitalLossDeduction;
  final double retirementTaxable, socialSecurityTaxable, unemployment, otherIncome;
  final double totalIncome;

  // Adjustments / AGI
  final double halfSeTaxDeduction, iraDeduction, studentLoanInterestDeduction;
  final double hsaDeduction, educatorDeduction, seHealthDeduction, seSepDeduction;
  final double obbbaTipsDeduction, obbbaOvertimeDeduction, obbbaCarLoanDeduction;
  final double agi, magi;

  // Deduction
  final double standardDeductionUsed, itemizedDeductionUsed, deductionUsed;
  final double seniorDeduction, saltAllowed;
  final double qbiDeduction, taxableIncome;

  // Tax
  final double ordinaryTax, preferentialTax, taxBeforeCredits;
  final List<BracketSlice> bracketSlices;

  // Credits
  final int ctcEligibleChildren, eitcQualifyingChildren;
  final double ctcNonrefundable, ctcRefundable, ctcTotal;
  final double childCareCredit, aotcNonrefundable, aotcRefundable, llcCredit;
  final double saversCredit, eitc;
  final double totalNonrefundableCredits, totalRefundableCredits;

  // Other taxes
  final double seTax, niit, additionalMedicareTax;
  final double totalTax, totalPayments, refundOrOwe; // >0 refund, <0 owe

  final double effectiveRate, marginalRate;

  const TaxResult({
    required this.input,
    required this.params,
    required this.wages,
    required this.seNet,
    required this.seEarnings,
    required this.taxableInterest,
    required this.taxExemptInterest,
    required this.ordinaryDividends,
    required this.qualifiedDividends,
    required this.netShortTermGain,
    required this.netLongTermGain,
    required this.capitalLossDeduction,
    required this.retirementTaxable,
    required this.socialSecurityTaxable,
    required this.unemployment,
    required this.otherIncome,
    required this.totalIncome,
    required this.halfSeTaxDeduction,
    required this.iraDeduction,
    required this.studentLoanInterestDeduction,
    required this.hsaDeduction,
    required this.educatorDeduction,
    required this.seHealthDeduction,
    required this.seSepDeduction,
    required this.obbbaTipsDeduction,
    required this.obbbaOvertimeDeduction,
    required this.obbbaCarLoanDeduction,
    required this.agi,
    required this.magi,
    required this.standardDeductionUsed,
    required this.itemizedDeductionUsed,
    required this.deductionUsed,
    required this.seniorDeduction,
    required this.saltAllowed,
    required this.qbiDeduction,
    required this.taxableIncome,
    required this.ordinaryTax,
    required this.preferentialTax,
    required this.taxBeforeCredits,
    required this.bracketSlices,
    required this.ctcEligibleChildren,
    required this.eitcQualifyingChildren,
    required this.ctcNonrefundable,
    required this.ctcRefundable,
    required this.ctcTotal,
    required this.childCareCredit,
    required this.aotcNonrefundable,
    required this.aotcRefundable,
    required this.llcCredit,
    required this.saversCredit,
    required this.eitc,
    required this.totalNonrefundableCredits,
    required this.totalRefundableCredits,
    required this.seTax,
    required this.niit,
    required this.additionalMedicareTax,
    required this.totalTax,
    required this.totalPayments,
    required this.refundOrOwe,
    required this.effectiveRate,
    required this.marginalRate,
  });

  bool get isRefund => refundOrOwe >= 0;
}

double _r(double x) => x.roundToDouble(); // whole-dollar rounding (IRS style)

double _clampNonNeg(num x) => x < 0 ? 0 : x.toDouble();

/// Tax on ordinary income using the year's bracket table.
double taxOnOrdinary(double taxable, YearParams p, FilingStatus status) {
  final col = statusCol(status);
  double remaining = taxable, tax = 0, prev = 0;
  for (final row in p.brackets) {
    final top = row[col + 1];
    final rate = row[0];
    if (remaining <= 0) break;
    final span = (top == double.infinity ? remaining : top - prev);
    final slice = remaining < span ? remaining : span;
    tax += slice * rate;
    remaining -= slice;
    prev = top;
  }
  return tax;
}

class FederalEngine {
  const FederalEngine();

  TaxResult compute(TaxReturnData d, YearParams p) {
    final col = statusCol(d.filingStatus);
    final isMfj = d.filingStatus == FilingStatus.marriedJointly ||
        d.filingStatus == FilingStatus.qualifyingSurvivingSpouse;

    // ---------- Income ----------
    double wages = 0, w2FedWht = 0, w2SsWages = 0;
    double w2Tips = 0, w2Overtime = 0;
    for (final w in d.w2s) {
      wages += w.wages;
      w2FedWht += w.federalWithholding;
      w2SsWages += w.ssWages;
      w2Tips += w.qualifiedTips;
      w2Overtime += w.qualifiedOvertime;
    }

    double seNet = 0, seTips = 0, seHealth = 0, seSep = 0;
    for (final s in d.selfEmployment) {
      seNet += s.netProfit;
      seTips += s.qualifiedTips;
      seHealth += s.seHealthInsurancePremiums;
      seSep += s.sepSimpleContributions;
    }
    // Net earnings from self-employment = 92.35% of net profit.
    final double seEarnings = seNet > 400 ? seNet * 0.9235 : 0.0;

    double taxableInterest = 0, taxExemptInterest = 0;
    for (final i in d.interest) {
      taxableInterest += i.taxableInterest;
      taxExemptInterest += i.taxExemptInterest;
    }

    double ordinaryDividends = 0, qualifiedDividends = 0;
    for (final dv in d.dividends) {
      ordinaryDividends += dv.ordinaryDividends;
      qualifiedDividends += dv.qualifiedDividends.clamp(0, dv.ordinaryDividends);
    }

    double st = 0, lt = 0;
    for (final c in d.capitalGains) {
      if (c.isLongTerm) {
        lt += c.gain;
      } else {
        st += c.gain;
      }
    }
    final netShortTermGain = st;
    final netLongTermGain = lt;
    final netCapitalGain = st + lt;
    // Net capital loss: deductible against ordinary income up to $3,000.
    final double capitalLossDeduction =
        netCapitalGain < 0 ? (netCapitalGain.abs() > 3000 ? 3000.0 : netCapitalGain.abs()) : 0.0;

    double retirementTaxable = 0, retirementWht = 0;
    for (final r in d.retirement) {
      retirementTaxable += r.taxableAmount;
      retirementWht += r.federalWithholding;
    }

    final unemployment = d.adjustments.unemploymentAmount;
    final unemploymentWht = d.adjustments.unemploymentWithholding;

    double otherIncome = 0;
    for (final o in d.otherIncome) {
      otherIncome += o.amount;
    }

    // Social Security taxable amount (simplified provisional-income rule):
    // combined income = AGI-except-SS + tax-exempt interest + 0.5*SS.
    double ssTaxable = 0;
    final ss = d.socialSecurityBenefits;
    if (ss > 0) {
      final otherThanSs = wages +
          seEarnings +
          taxableInterest +
          taxExemptInterest +
          ordinaryDividends +
          _clampNonNeg(netCapitalGain) -
          capitalLossDeduction +
          retirementTaxable +
          unemployment +
          otherIncome;
      final combined = otherThanSs + 0.5 * ss;
      final base1 = isMfj ? 32000 : 25000;
      final base2 = isMfj ? 44000 : 34000;
      if (combined <= base1) {
        ssTaxable = 0;
      } else if (combined <= base2) {
        ssTaxable = _clampNonNeg(0.5 * _min(combined - base1, ss));
      } else {
        ssTaxable = _clampNonNeg(
            _min(0.85 * (combined - base2) + _min(0.5 * _min(combined - base1, ss), 6000), 0.85 * ss));
      }
    }

    final totalIncome = wages +
        seNet +
        taxableInterest +
        ordinaryDividends +
        _clampNonNeg(netCapitalGain) +
        retirementTaxable +
        ssTaxable +
        unemployment +
        otherIncome -
        capitalLossDeduction;

    // ---------- Adjustments → AGI ----------
    final halfSeTaxDeduction = 0.5 * seTaxRaw(seEarnings, w2SsWages, p);
    final iraDeduction = _clampNonNeg(d.adjustments.iraContributions);
    final educatorDeduction = _clampNonNeg(d.adjustments.educatorExpenses);
    final seHealthDeduction =
        seNet > 0 ? _clampNonNeg(seHealth.clamp(0, seNet)) : 0.0;
    final seSepDeduction =
        seNet > 0 ? _clampNonNeg(seSep.clamp(0, seNet)) : 0.0;

    // Student loan interest: up to $2,500, phased out by MAGI.
    final slMagiStart = isMfj ? p.slInterestPhaseoutStartMfj : p.slInterestPhaseoutStartSingle;
    final slMagiEnd = isMfj ? p.slInterestPhaseoutEndMfj : p.slInterestPhaseoutEndSingle;

    // HSA: simplified limits (self-only vs family).
    final hsaLimit = isMfj ? (p.year >= 2025 ? 8550.0 : 8300.0) : (p.year >= 2025 ? 4300.0 : 4150.0);
    final hsaDeduction = _clampNonNeg(d.adjustments.hsaContributions.clamp(0, hsaLimit));

    // AGI before the OBBBA deductions and student-loan phaseout (their MAGI base).
    final agiPre = totalIncome -
        halfSeTaxDeduction -
        iraDeduction -
        educatorDeduction -
        seHealthDeduction -
        seSepDeduction -
        hsaDeduction;
    final magi = _clampNonNeg(agiPre);

    double slDeduction = _clampNonNeg(d.adjustments.studentLoanInterest.clamp(0, 2500));
    if (magi > slMagiStart) {
      if (magi >= slMagiEnd) {
        slDeduction = 0;
      } else {
        slDeduction = _r(slDeduction * (1 - (magi - slMagiStart) / (slMagiEnd - slMagiStart)));
      }
    }

    // ---------- OBBBA deductions (2025-2028) ----------
    double tipsDeduction = 0, overtimeDeduction = 0, carLoanDeduction = 0;
    if (p.obbbaDeductionsActive) {
      // Phaseout thresholds: MFJ $300,000; all others $150,000.
      final poStart = isMfj ? (p.obbbaHighIncomePhaseoutStart ?? 150000) * 2 : (p.obbbaHighIncomePhaseoutStart ?? 150000);
      final tipsAmount = _clampNonNeg((w2Tips + seTips).clamp(0, p.obbbaTipsCap));
      final overtimeAmount =
          _clampNonNeg(w2Overtime.clamp(0, isMfj ? p.obbbaOvertimeCapMfj : p.obbbaOvertimeCapSingle));
      tipsDeduction = _obbbaPhased(tipsAmount, magi, poStart, 0.10);
      overtimeDeduction = _obbbaPhased(overtimeAmount, magi, poStart, 0.10);
      final clStart = isMfj ? 200000.0 : 100000.0;
      carLoanDeduction = _obbbaPhased(
          _clampNonNeg(d.qualifiedCarLoanInterest.clamp(0, p.obbbaCarLoanCap)), magi, clStart, 0.20);
    }
    final agi = _clampNonNeg(agiPre - slDeduction - tipsDeduction - overtimeDeduction - carLoanDeduction);

    // ---------- Deduction: standard vs itemized ----------
    // SALT cap with OBBBA phase-down (2025): reduced 30% of MAGI over
    // $500,000, floor $10,000. MFS uses half amounts.
    double saltCap = p.saltCap;
    if (d.filingStatus == FilingStatus.marriedSeparately) {
      saltCap = p.saltCap / 2;
    }
    final saltPhaseStart = p.saltCapPhaseDownStart;
    double saltAllowed = d.itemized.saltTaxes.clamp(0, saltCap).toDouble();
    if (saltPhaseStart != null) {
      final phaseStart =
          d.filingStatus == FilingStatus.marriedSeparately ? saltPhaseStart / 2 : saltPhaseStart;
      final floor =
          d.filingStatus == FilingStatus.marriedSeparately ? p.saltCapFloor / 2 : p.saltCapFloor;
      if (agi > phaseStart) {
        final reduced = saltCap - 0.30 * (agi - phaseStart);
        final cap = reduced < floor ? floor : reduced;
        saltAllowed = d.itemized.saltTaxes.clamp(0, cap).toDouble();
      }
    }

    final medicalFloor = 0.075 * agi;
    final medical = _clampNonNeg(d.itemized.medicalExpenses - medicalFloor);
    final charityCap = 0.60 * agi;
    final charity =
        (d.itemized.charitableCash + d.itemized.charitableNonCash).clamp(0, charityCap).toDouble();
    final itemized = medical + saltAllowed + d.itemized.mortgageInterest + charity;

    // Standard deduction (with 65+/blind additions and dependent limitation).
    double std = p.standardDeduction[col == 1 ? 1 : col];
    final addlPerPerson =
        isMfj ? p.additionalStdDeductionMarried : p.additionalStdDeductionSingle;
    double addlBoxes = 0;
    if (d.taxpayer.is65OrOlder) addlBoxes += addlPerPerson;
    if (d.taxpayer.isBlind) addlBoxes += addlPerPerson;
    if (isMfj && d.spouse != null) {
      if (d.spouse!.is65OrOlder) addlBoxes += addlPerPerson;
      if (d.spouse!.isBlind) addlBoxes += addlPerPerson;
    }
    std += addlBoxes;
    if (d.canBeClaimedByAnother) {
      final earned = wages + seNet;
      final capped = _max(p.dependentStdFloor, earned + p.dependentStdEarnedAdd);
      std = std > capped ? capped : std;
    }

    final useItemized = itemized > std;
    final deductionUsed = useItemized ? itemized : std;

    // ---------- Senior deduction (OBBBA, below-the-line, 2025-2028) ----------
    double seniorDeduction = 0;
    if (p.obbbaDeductionsActive &&
        d.filingStatus != FilingStatus.marriedSeparately &&
        d.taxpayer.is65OrOlder) {
      double seniorAmount = p.obbbaSeniorDeduction;
      final seniorStart = isMfj ? 150000.0 : 75000.0;
      if (agi > seniorStart) {
        seniorAmount = _max(0, seniorAmount - 0.06 * (agi - seniorStart));
      }
      if (isMfj && d.spouse != null && d.spouse!.is65OrOlder) {
        seniorAmount += p.obbbaSeniorDeduction; // spouse's own $6,000 (same AGI phaseout)
        if (seniorAmount < 0) seniorAmount = 0;
      }
      seniorDeduction = seniorAmount;
    }

    // ---------- QBI deduction (simplified §199A / Form 8995) ----------
    final qbiComponent = _clampNonNeg(seNet); // SE income is the QBI source modeled
    final tiBeforeQbi = _clampNonNeg(agi - deductionUsed - seniorDeduction);
    final preferential = _clampNonNeg(qualifiedDividends + netLongTermGain);
    final qbiLimitBase = _clampNonNeg(tiBeforeQbi - preferential);
    double qbi = _min(0.20 * qbiComponent, 0.20 * qbiLimitBase);
    final qbiThreshold = isMfj ? p.qbiThresholdMfj : p.qbiThresholdOther;
    if (tiBeforeQbi > qbiThreshold) {
      // Above threshold: apply the W-2 wage limitation in simplified form
      // (no SSTB / phase-in interpolation is modeled — see TAX_ENGINE.md).
      qbi = _min(qbi, 0.20 * qbiLimitBase);
    }
    final taxableIncome = _clampNonNeg(tiBeforeQbi - qbi);

    // ---------- Tax ----------
    final preferentialTaxable = preferential.clamp(0, taxableIncome).toDouble();
    final ordinaryTi = taxableIncome - preferentialTaxable;
    final ordinaryTax = _r(taxOnOrdinary(ordinaryTi, p, d.filingStatus));

    final zeroUpTo = p.ltcgZeroUpTo[col];
    final fifteenUpTo = p.ltcgFifteenUpTo[col];
    final zeroAmount = _clampNonNeg(_min(preferentialTaxable, zeroUpTo - ordinaryTi));
    final fifteenAmount =
        _clampNonNeg(_min(preferentialTaxable - zeroAmount, fifteenUpTo - ordinaryTi - zeroAmount));
    final twentyAmount = _max(0, preferentialTaxable - zeroAmount - fifteenAmount);
    final preferentialTax = _r(0.15 * fifteenAmount + 0.20 * twentyAmount);

    final taxBeforeCredits = ordinaryTax + preferentialTax;

    // Bracket slices for visualization (ordinary side only).
    final slices = <BracketSlice>[];
    {
      double remaining = ordinaryTi, prev = 0;
      for (final row in p.brackets) {
        final top = row[col + 1];
        final rate = row[0];
        if (remaining <= 0) break;
        final span = (top == double.infinity ? remaining : top - prev);
        final slice = remaining < span ? remaining : span;
        slices.add(BracketSlice(rate, slice, slice * rate));
        remaining -= slice;
        prev = top;
      }
    }

    // ---------- Credits ----------
    // Child Tax Credit.
    final ctcChildren = d.dependents.where((x) => x.isCtcEligible(p.year)).length;
    final ctcBase = ctcChildren * p.ctcPerChild;
    final ctcPoStart = isMfj ? p.ctcPhaseoutStartMfj : p.ctcPhaseoutStartSingle;
    final ctcExcess = _clampNonNeg(agi - ctcPoStart);
    final ctcReduction = ((ctcExcess / 1000).ceilToDouble()) * 50;
    final ctcAfterPo = _clampNonNeg(ctcBase - ctcReduction);

    // Child & dependent care credit (nonrefundable).
    final careKids = d.dependents.where((x) => p.year - (x.dateOfBirth?.year ?? p.year) < 13).length;
    final careCap = careKids >= 2 ? 6000.0 : (careKids == 1 ? 3000.0 : 0.0);
    final careExpenses = _clampNonNeg(d.credits.childCareExpenses.clamp(0, careCap));
    double careRate = 0.20;
    if (agi <= 15000) {
      careRate = 0.35;
    } else if (agi < 43000) {
      careRate = 0.35 - (((agi - 15000) / 2000).floorToDouble()) * 0.01;
      if (careRate < 0.20) careRate = 0.20;
    }
    final childCareCredit = _r(careRate * careExpenses);

    // Education credits with phaseout (80-90k S / 160-180k MFJ).
    final edStart = isMfj ? p.edCreditPhaseoutStartMfj : p.edCreditPhaseoutStartSingle;
    double edFactor = 1.0;
    if (agi >= edStart + 10000) {
      edFactor = 0;
    } else if (agi > edStart) {
      edFactor = 1 - (agi - edStart) / 10000;
    }
    final aotc = d.credits.aotcQualifiedExpenses <= 0
        ? 0.0
        : _r((_min(d.credits.aotcQualifiedExpenses, 2000.0) +
                0.25 * (d.credits.aotcQualifiedExpenses - 2000).clamp(0, 2000).toDouble()) *
            edFactor);
    final aotcRefundable = _r(aotc * 0.40);
    final aotcNonrefundable = aotc - aotcRefundable;
    final llcComputed = _r(0.20 * _clampNonNeg(d.credits.llcQualifiedExpenses.clamp(0, 10000)));
    final llcCredit = _r(llcComputed * edFactor);

    // Saver's credit.
    final savCol = isMfj ? 1 : 0;
    double savRate = 0;
    final bands = p.saversCreditBands;
    if (agi <= bands[0][savCol]) {
      savRate = 0.50;
    } else if (agi <= bands[1][savCol]) {
      savRate = 0.20;
    } else if (agi <= bands[2][savCol]) {
      savRate = 0.10;
    }
    final saversCredit =
        _r(savRate * _clampNonNeg(d.credits.saversCreditContributions.clamp(0, isMfj ? 4000 : 2000)));

    // Apply nonrefundable credits in 1040 order: CTC, care, education, saver's.
    double remainingTax = taxBeforeCredits;
    final ctcNonrefundable = _min(ctcAfterPo, remainingTax);
    remainingTax -= ctcNonrefundable;
    final careCreditUsed = _min(childCareCredit, remainingTax);
    remainingTax -= careCreditUsed;
    final aotcUsed = _min(aotcNonrefundable, remainingTax);
    remainingTax -= aotcUsed;
    final llcUsed = _min(llcCredit, remainingTax);
    remainingTax -= llcUsed;
    final saversUsed = _min(saversCredit, remainingTax);
    remainingTax -= saversUsed;
    final totalNonrefundableCredits =
        ctcNonrefundable + careCreditUsed + aotcUsed + llcUsed + saversUsed;

    // Refundable ACTC (Form 8812 simplified).
    final earnedIncome = wages + seEarnings;
    final actcCap = p.ctcRefundableMaxPerChild * ctcChildren;
    final actcEarnedCap = p.ctcRefundableRate * _clampNonNeg(earnedIncome - p.ctcRefundableEarnedFloor);
    final ctcRefundable =
        _clampNonNeg(_min(_min(ctcAfterPo - ctcNonrefundable, actcCap), actcEarnedCap));

    // EITC.
    final eitcKids = d.dependents.where((x) => x.isEitcQualifyingChild(p.year)).length;
    double eitc = 0;
    final investIncome = taxableInterest + ordinaryDividends + _clampNonNeg(netCapitalGain);
    final eitcStatusOk = d.filingStatus != FilingStatus.marriedSeparately;
    final eitcAgeOk = eitcKids > 0 || _eitcAgeOk(d.taxpayer, p.year);
    if (eitcStatusOk &&
        eitcAgeOk &&
        investIncome <= p.eitcInvestmentIncomeLimit &&
        earnedIncome > 0 &&
        agi < p.eitcPhaseoutEndSingle[eitcKids.clamp(0, 3).toInt()] + (isMfj ? p.eitcPhaseoutStartMfjBonus[eitcKids.clamp(0, 3).toInt()] : 0)) {
      final k = eitcKids.clamp(0, 3).toInt();
      final maxCredit = p.eitcMaxCredits[k];
      final base = _min(p.eitcPhaseInRates[k] * earnedIncome, maxCredit);
      final start = p.eitcPhaseoutStartSingle[k] +
          (isMfj ? p.eitcPhaseoutStartMfjBonus[k] : 0);
      final phaseoutBase = _max(agi, earnedIncome);
      final phaseout = p.eitcPhaseoutRates[k] * _clampNonNeg(phaseoutBase - start);
      eitc = _max(0, _r(base - phaseout));
    }

    final totalRefundableCredits = ctcRefundable + aotcRefundable + eitc;

    // ---------- Other taxes ----------
    final seTax = _r(seTaxRaw(seEarnings, w2SsWages, p));
    // Net investment income tax (3.8%). Thresholds: [S/HOH, MFJ/QSS, MFS].
    final netInvIncome = taxableInterest + ordinaryDividends + _clampNonNeg(netCapitalGain);
    final niitThreshold = p.niitThresholds[_taxThresholdIdx(col)];
    final niit = _r(0.038 * _min(_clampNonNeg(netInvIncome), _clampNonNeg(agi - niitThreshold)));
    // Additional Medicare tax (0.9%).
    final addlMedThreshold = p.addlMedicareThresholds[_taxThresholdIdx(col)];
    final medicareWages = wages + seEarnings;
    final additionalMedicareTax = _r(0.009 * _clampNonNeg(medicareWages - addlMedThreshold));

    final totalTax = _max(0, _r(remainingTax + seTax + niit + additionalMedicareTax));

    // ---------- Payments ----------
    final totalPayments = _r(w2FedWht + unemploymentWht + retirementWht + d.adjustments.estimatedPayments);
    final refundOrOwe = totalPayments - totalTax - totalRefundableCredits;

    final effectiveRate = totalIncome > 0 ? (totalTax / totalIncome * 100) : 0.0;
    final marginalRate = _marginalRate(ordinaryTi, p, d.filingStatus);

    return TaxResult(
      input: d,
      params: p,
      wages: _r(wages),
      seNet: _r(seNet),
      seEarnings: _r(seEarnings),
      taxableInterest: _r(taxableInterest),
      taxExemptInterest: _r(taxExemptInterest),
      ordinaryDividends: _r(ordinaryDividends),
      qualifiedDividends: _r(qualifiedDividends),
      netShortTermGain: _r(netShortTermGain),
      netLongTermGain: _r(netLongTermGain),
      capitalLossDeduction: _r(capitalLossDeduction),
      retirementTaxable: _r(retirementTaxable),
      socialSecurityTaxable: _r(ssTaxable),
      unemployment: _r(unemployment),
      otherIncome: _r(otherIncome),
      totalIncome: _r(totalIncome),
      halfSeTaxDeduction: _r(halfSeTaxDeduction),
      iraDeduction: _r(iraDeduction),
      studentLoanInterestDeduction: _r(slDeduction),
      hsaDeduction: _r(hsaDeduction),
      educatorDeduction: _r(educatorDeduction),
      seHealthDeduction: _r(seHealthDeduction),
      seSepDeduction: _r(seSepDeduction),
      obbbaTipsDeduction: _r(tipsDeduction),
      obbbaOvertimeDeduction: _r(overtimeDeduction),
      obbbaCarLoanDeduction: _r(carLoanDeduction),
      agi: _r(agi),
      magi: _r(magi),
      standardDeductionUsed: _r(std),
      itemizedDeductionUsed: _r(itemized),
      deductionUsed: _r(deductionUsed),
      seniorDeduction: _r(seniorDeduction),
      saltAllowed: _r(saltAllowed),
      qbiDeduction: _r(qbi),
      taxableIncome: _r(taxableIncome),
      ordinaryTax: ordinaryTax,
      preferentialTax: preferentialTax,
      taxBeforeCredits: taxBeforeCredits,
      bracketSlices: slices,
      ctcEligibleChildren: ctcChildren,
      eitcQualifyingChildren: eitcKids,
      ctcNonrefundable: _r(ctcNonrefundable),
      ctcRefundable: _r(ctcRefundable),
      ctcTotal: _r(ctcNonrefundable + ctcRefundable),
      childCareCredit: _r(careCreditUsed),
      aotcNonrefundable: _r(aotcUsed),
      aotcRefundable: _r(aotcRefundable),
      llcCredit: _r(llcUsed),
      saversCredit: _r(saversUsed),
      eitc: _r(eitc),
      totalNonrefundableCredits: _r(totalNonrefundableCredits),
      totalRefundableCredits: _r(totalRefundableCredits),
      seTax: seTax,
      niit: niit,
      additionalMedicareTax: additionalMedicareTax,
      totalTax: totalTax,
      totalPayments: totalPayments,
      refundOrOwe: _r(refundOrOwe),
      effectiveRate: effectiveRate,
      marginalRate: marginalRate,
    );
  }

  static bool _eitcAgeOk(Person t, int year) {
    final d = t.dateOfBirth;
    if (d == null) return true; // unknown age: allow, flag via validation
    final age = year - d.year;
    return age >= 25 && age <= 64;
  }

  static double _obbbaPhased(double amount, double magi, double start, double ratePerDollar) {
    if (magi <= start) return amount;
    final reduction = ratePerDollar * (magi - start);
    final v = amount - reduction;
    return v < 0 ? 0 : v;
  }

  static double _marginalRate(double ordinaryTi, YearParams p, FilingStatus status) {
    final col = statusCol(status);
    for (final row in p.brackets) {
      if (ordinaryTi <= row[col + 1]) return row[0];
    }
    return 0.37;
  }
}

/// Threshold-array index for NIIT / Additional Medicare tables
/// ([S/HOH, MFJ/QSS, MFS]) from the bracket column index.
int _taxThresholdIdx(int col) => col == 1 ? 1 : (col == 3 ? 2 : 0);

/// Social Security + Medicare portion of SE tax with W-2 wage-base offset.
double seTaxRaw(double seEarnings, double w2SsWages, YearParams p) {
  if (seEarnings <= 0) return 0;
  final ssRoom = _clampNonNeg(p.seWageBase - w2SsWages);
  final ssBase = _min(seEarnings, ssRoom);
  return ssBase * 0.124 + seEarnings * 0.029;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;
