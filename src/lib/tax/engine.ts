// SPDX-License-Identifier: GPL-3.0-only
/**
 * ClearFile web tax engine — Stage-3 parity port of the Flutter reference
 * engine (`clearfile/lib/tax/calculator.dart`, line for line).
 *
 * Implements the same simplified, clearly-labelled TY2025 Form 1040 flow:
 * income → student-loan adjustment → (standard | itemized) deduction with
 * the OBBBA senior deduction → brackets with qualified-dividend / LTCG
 * stacking → NIIT → CTC/ACTC/ODC → payments. Money is carried at cent
 * precision (no whole-dollar rounding); display formatting happens in the
 * UI layer, exactly as in the reference.
 *
 * Parity proof: `scripts/web_parity_test.mjs` runs this engine against the
 * shared golden fixtures in `fixtures/tax/` — the same 16 IRS-pinned
 * `(TaxReturnData, TaxResult)` pairs the Dart suite runs. Any disagreement
 * between the engines is settled by the IRS publication each fixture cites.
 *
 * THIS IS DEMONSTRATION SOFTWARE. It omits many real-return rules (see the
 * README "Engine limitations" section) and must not be used to file.
 */

import type { Bracket, DeductionMethod, FilingStatus, TaxYearParameters } from './config'

/* ------------------------------------------------------------------ */
/* Input model (mirrors clearfile/lib/models/tax_return.dart)          */
/* ------------------------------------------------------------------ */

export interface W2Entry {
  /** Client-side identity for React keys / store updates; never affects
   * computation (fixture inputs omit it). */
  id?: string
  employer: string
  /** Box 1 — wages, tips, other compensation. */
  wages: number
  /** Box 2 — federal income tax withheld. */
  withholding: number
}

export interface Dependent {
  id?: string
  name: string
  age: number
  relationship: string
  /** Qualifying child under 17 at year end (Child Tax Credit). */
  qualifyingChild: boolean
  /** Qualifies for the $500 Credit for Other Dependents. */
  otherDependentCredit: boolean
}

export interface TaxReturnData {
  taxYear: number
  filingStatus: FilingStatus
  taxpayer65OrOlder: boolean
  spouse65OrOlder: boolean
  taxpayerBlind: boolean
  spouseBlind: boolean
  w2s: W2Entry[]
  interestIncome: number
  /** Dividends that are NOT qualified (taxed as ordinary income). */
  ordinaryDividends: number
  qualifiedDividends: number
  longTermCapitalGains: number
  otherIncome: number
  studentLoanInterest: number
  deductionMethod: DeductionMethod
  stateLocalIncomeOrSalesTax: number
  realEstateTax: number
  mortgageInterest: number
  charitableCash: number
  charitableNonCash: number
  estimatedPayments: number
  dependents: Dependent[]
}

export const totalWages = (r: Pick<TaxReturnData, 'w2s'>): number =>
  r.w2s.reduce((s, w) => s + (w.wages || 0), 0)

export const totalWithholding = (r: Pick<TaxReturnData, 'w2s'>): number =>
  r.w2s.reduce((s, w) => s + (w.withholding || 0), 0)

export const totalIncome = (
  r: Pick<TaxReturnData, 'w2s' | 'interestIncome' | 'ordinaryDividends' | 'qualifiedDividends' | 'longTermCapitalGains' | 'otherIncome'>
): number =>
  totalWages(r) +
  (r.interestIncome || 0) +
  (r.ordinaryDividends || 0) +
  (r.qualifiedDividends || 0) +
  (r.longTermCapitalGains || 0) +
  (r.otherIncome || 0)

/* ------------------------------------------------------------------ */
/* Result model (mirrors clearfile/lib/tax/results.dart)               */
/* ------------------------------------------------------------------ */

export interface TaxResult {
  totalIncome: number
  studentLoanDeduction: number
  agi: number
  basicStandardDeduction: number
  additionalStandardDeduction: number
  seniorDeduction: number
  standardDeductionTotal: number
  saltPaid: number
  saltCap: number
  saltAllowed: number
  itemizedDeductionTotal: number
  deductionMethodUsed: 'standard' | 'itemized'
  deductionUsed: number
  taxableIncome: number
  ordinaryTax: number
  preferentialIncome: number
  preferentialTax: number
  niit: number
  nonRefundableCredits: number
  refundableCredits: number
  totalTax: number
  totalPayments: number
  refund: number
  amountOwed: number
  effectiveRate: number
  marginalRate: number
  qualifyingChildren: number
}

/** True when the return projects a refund (Dart: `refund > 0`). */
export const isRefund = (c: TaxResult): boolean => c.refund > 0

/** Positive when a refund, negative when owed (Dart: `refund - amountOwed`). */
export const refundOrOwed = (c: TaxResult): number => c.refund - c.amountOwed

/* ------------------------------------------------------------------ */
/* Engine                                                              */
/* ------------------------------------------------------------------ */

const min = Math.min
const max = Math.max

/** Ordinary-bracket walk (Dart `_bracketTax`). */
function bracketTax(income: number, brackets: Bracket[]): number {
  let tax = 0
  let lowerBound = 0
  for (const br of brackets) {
    if (income <= lowerBound) break
    const upper = br.upTo == null ? income : min(income, br.upTo)
    tax += (upper - lowerBound) * br.rate
    if (br.upTo == null) break
    lowerBound = br.upTo
  }
  return tax
}

/** Marginal rate at an ordinary income level (Dart `_marginalRate`). */
function marginalRateAt(income: number, brackets: Bracket[]): number {
  let lowerBound = 0
  for (const br of brackets) {
    if (income <= lowerBound) return brackets[0].rate
    if (income <= (br.upTo ?? Number.POSITIVE_INFINITY)) return br.rate
    lowerBound = br.upTo ?? lowerBound
  }
  return brackets[brackets.length - 1].rate
}

/** SALT cap for a MAGI (Dart `TaxYearParameters.saltCapFor`). */
export function saltCapFor(status: FilingStatus, magi: number, p: TaxYearParameters): number {
  const base = p.saltBaseCap[status]
  const start = p.saltPhaseoutStart[status]
  const floor = p.saltFloor[status]
  if (magi <= start) return base
  const reduced = base - p.saltPhaseoutRate * (magi - start)
  return reduced < floor ? floor : reduced
}

/** Student-loan interest deduction. MAGI is total income (the deduction is
 * below the line it affects). MFS is not eligible (Dart convention: start >
 * end). */
function studentLoanDeduction(paid: number, status: FilingStatus, magi: number, p: TaxYearParameters): number {
  const capped = min(paid, p.studentLoanMax)
  if (capped <= 0) return 0
  const start = p.studentLoanPhaseoutStart[status]
  const end = p.studentLoanPhaseoutEnd[status]
  if (end <= start) return 0 // MFS: not eligible.
  if (magi <= start) return capped
  if (magi >= end) return 0
  return capped * (end - magi) / (end - start)
}

/** OBBBA senior deduction (Schedule 1-A Part V: married filers must file
 * jointly to claim it; MFS gets nothing). */
function seniorDeduction(r: TaxReturnData, status: FilingStatus, agi: number, p: TaxYearParameters): number {
  if (status === 'marriedSeparate') return 0
  const hasSpouse = status === 'marriedJoint'
  const seniorPersons = (r.taxpayer65OrOlder ? 1 : 0) + (r.spouse65OrOlder && hasSpouse ? 1 : 0)
  if (seniorPersons === 0) return 0
  const start = p.seniorPhaseoutStart[status]
  const per = p.seniorDeductionPerPerson
  if (agi <= start) return per * seniorPersons
  const phasedPer = per - p.seniorPhaseoutRate * (agi - start)
  return max(0, phasedPer) * seniorPersons
}

/** Schedule 8812 (2025) lines 9-11: the excess MAGI is cents-normalized,
 * then rounded UP to the next multiple of $1,000 BEFORE the 5% phase-out
 * ("if the result is $425, enter $1,000; if $1,025, enter $2,000"). */
function ctcPhaseoutAmount(status: FilingStatus, agi: number, p: TaxYearParameters): number {
  const rawExcess = agi - p.ctcPhaseoutStart[status]
  if (rawExcess <= 0) return 0
  const excessCents = Math.round(rawExcess * 100)
  if (excessCents <= 0) return 0
  const phaseOutBase = Math.ceil(excessCents / 100000) * 1000
  return p.ctcPhaseoutRate * phaseOutBase
}

export function compute(r: TaxReturnData, params: TaxYearParameters): TaxResult {
  const status = r.filingStatus
  const hasSpouse = status === 'marriedJoint'

  // ---- Income ---------------------------------------------------------
  const wages = totalWages(r)
  const income = totalIncome(r)

  // ---- Adjustments: student loan interest -----------------------------
  const sli = studentLoanDeduction(r.studentLoanInterest, status, income, params)
  const agi = income - sli

  // ---- Itemized (Schedule A-lite) --------------------------------------
  const saltPaid = max(0, r.stateLocalIncomeOrSalesTax + r.realEstateTax)
  const saltCap = saltCapFor(status, agi, params)
  const saltAllowed = min(saltPaid, saltCap)
  const positiveAgi = max(0, agi)
  const charitableAllowed =
    min(r.charitableCash, params.charitableCashAgiLimit * positiveAgi) +
    min(r.charitableNonCash, params.charitableNonCashAgiLimit * positiveAgi)
  const itemizedRaw = max(0, saltAllowed + r.mortgageInterest + charitableAllowed)

  // ---- Senior deduction (OBBBA) -----------------------------------------
  const senior = seniorDeduction(r, status, agi, params)

  // ---- Standard deduction ------------------------------------------------
  const basic = params.standardDeduction[status]
  const agedOrBlindPersons =
    (r.taxpayer65OrOlder ? 1 : 0) +
    (r.taxpayerBlind ? 1 : 0) +
    ((r.spouse65OrOlder || r.spouseBlind) && hasSpouse ? 1 : 0)
  const additional = agedOrBlindPersons * params.additionalPerAgedOrBlindPerson[status]
  const standardTotal = basic + additional

  const standardDeductionTotal = standardTotal + senior
  const itemizedDeductionTotal = itemizedRaw + senior

  // ---- Choose method -----------------------------------------------------
  let deductionMethodUsed: 'standard' | 'itemized'
  if (r.deductionMethod === 'standard') deductionMethodUsed = 'standard'
  else if (r.deductionMethod === 'itemized') deductionMethodUsed = 'itemized'
  else deductionMethodUsed = itemizedDeductionTotal > standardDeductionTotal ? 'itemized' : 'standard'
  const deductionUsed = deductionMethodUsed === 'itemized' ? itemizedDeductionTotal : standardDeductionTotal

  // ---- Taxable income ------------------------------------------------------
  const taxable = max(0, agi - deductionUsed)

  // ---- Tax with qualified-dividend / LTCG stacking --------------------------
  const preferentialIncome = min(max(0, r.qualifiedDividends + r.longTermCapitalGains), taxable)
  const ordinaryTaxable = taxable - preferentialIncome
  const ordinaryTax = bracketTax(ordinaryTaxable, params.ordinaryBrackets[status])

  const zeroCap = params.qdiZeroCap[status]
  const fifteenCap = params.qdiFifteenCap[status]
  let preferentialRemaining = preferentialIncome
  const zeroRoom = max(0, zeroCap - ordinaryTaxable)
  const atZeroRate = min(preferentialRemaining, zeroRoom)
  preferentialRemaining -= atZeroRate
  const fifteenRoom = max(0, fifteenCap - max(ordinaryTaxable, zeroCap))
  const atFifteenRate = min(preferentialRemaining, fifteenRoom)
  preferentialRemaining -= atFifteenRate
  const preferentialTax = 0.15 * atFifteenRate + 0.2 * preferentialRemaining

  // ---- Net investment income tax (simplified) -------------------------------
  const investmentIncome = max(
    0,
    (r.interestIncome || 0) + (r.ordinaryDividends || 0) + (r.qualifiedDividends || 0) + (r.longTermCapitalGains || 0)
  )
  const niitThreshold = params.niitThreshold[status]
  const niit = agi > niitThreshold ? params.niitRate * min(investmentIncome, agi - niitThreshold) : 0

  // ---- Credits --------------------------------------------------------------
  const kids = r.dependents.filter((d) => d.qualifyingChild).length
  const otherDependents = r.dependents.filter((d) => d.otherDependentCredit).length
  const phaseOutAmount = ctcPhaseoutAmount(status, agi, params)
  const grossCtc = kids * params.ctcPerChild
  const grossOdc = otherDependents * params.odcPerDependent
  // 8812 line 12: the phase-out reduces the COMBINED CTC + ODC amount,
  // floored at zero (not each credit separately).
  const phasedTotal = max(0, grossCtc + grossOdc - phaseOutAmount)
  // ODC is strictly non-refundable, so only the CTC portion feeds the
  // refundable ACTC side.
  const phasedCtc = max(0, grossCtc - phaseOutAmount)

  const taxBeforeCredits = ordinaryTax + preferentialTax
  const nonRefundableCredits = min(phasedTotal, taxBeforeCredits)

  // Refundable ACTC (simplified): 15% of earned income above the floor,
  // capped at the per-child refundable amount.
  const earnedIncome = wages
  const remainingCtc = max(0, phasedCtc - nonRefundableCredits)
  const refundableCredits = min(
    remainingCtc,
    min(params.actcPerChild * kids, params.actcRate * max(0, earnedIncome - params.actcEarnedIncomeFloor))
  )

  // Refundable credits are paid out like withholding (1040 payments side).
  const totalTax = max(0, taxBeforeCredits - nonRefundableCredits + niit)

  // ---- Payments ------------------------------------------------------------
  const payments = totalWithholding(r) + (r.estimatedPayments || 0)
  const refund = max(0, payments + refundableCredits - totalTax)
  const amountOwed = max(0, totalTax - payments - refundableCredits)

  const effectiveRate = agi > 0 ? totalTax / agi : 0
  const marginalRate = marginalRateAt(ordinaryTaxable, params.ordinaryBrackets[status])

  return {
    totalIncome: income,
    studentLoanDeduction: sli,
    agi,
    basicStandardDeduction: basic,
    additionalStandardDeduction: additional,
    seniorDeduction: senior,
    standardDeductionTotal,
    saltPaid,
    saltCap,
    saltAllowed,
    itemizedDeductionTotal,
    deductionMethodUsed,
    deductionUsed,
    taxableIncome: taxable,
    ordinaryTax,
    preferentialIncome,
    preferentialTax,
    niit,
    nonRefundableCredits,
    refundableCredits,
    totalTax,
    totalPayments: payments,
    refund,
    amountOwed,
    effectiveRate,
    marginalRate,
    qualifyingChildren: kids,
  }
}

/** Walk a taxable amount through a bracket schedule for display (the
 * "where your tax comes from" card). Returns per-bracket slices. */
export interface BracketSlice {
  rate: number
  lo: number
  hi: number | null
  income: number
  tax: number
}

export function bracketWalk(taxable: number, brackets: Bracket[]): BracketSlice[] {
  const rows: BracketSlice[] = []
  let lo = 0
  for (const br of brackets) {
    const income = max(0, min(taxable, br.upTo ?? Number.POSITIVE_INFINITY) - lo)
    rows.push({ rate: br.rate, lo, hi: br.upTo, income, tax: income * br.rate })
    if (br.upTo == null || taxable <= br.upTo) break
    lo = br.upTo
  }
  return rows
}

/* ------------------------------------------------------------------ */
/* Local, no-AI sanity checks shown on the review screen                */
/* ------------------------------------------------------------------ */

export interface RuleCheck {
  id: string
  severity: 'info' | 'warn'
  title: string
  detail: string
}

export function ruleChecks(f: TaxReturnData, c: TaxResult): RuleCheck[] {
  const checks: RuleCheck[] = []
  if (f.w2s.length > 0 && totalWithholding(f) === 0) {
    checks.push({
      id: 'no-withholding',
      severity: 'warn',
      title: 'No federal withholding on any W-2',
      detail:
        'Wages are reported but federal income tax withheld is $0 on every form. If any W-2 shows withholding, enter it — this directly changes your refund.',
    })
  }
  if (c.itemizedDeductionTotal > 0 && c.itemizedDeductionTotal <= c.standardDeductionTotal) {
    checks.push({
      id: 'itemized-below-standard',
      severity: 'info',
      title: 'Itemized deductions are below your standard deduction',
      detail: `Your itemized total (after the SALT cap) is ${fmt(c.itemizedDeductionTotal)} and the standard deduction for your status is ${fmt(c.standardDeductionTotal)}. ClearFile automatically uses the larger amount, so nothing is lost.`,
    })
  }
  if (f.dependents.length === 0) {
    checks.push({
      id: 'no-dependents',
      severity: 'info',
      title: 'No dependents claimed',
      detail:
        'If you have children under 17 or other dependents, claiming them can be worth up to $2,200 (refundable portion up to $1,700) or $500 each. You can add them in the Dependents step.',
    })
  }
  if (c.refund > 6000) {
    checks.push({
      id: 'large-refund',
      severity: 'info',
      title: 'Large refund expected',
      detail:
        'A refund above $6,000 usually means significant over-withholding during the year. You may prefer to adjust your W-4 to keep that money in each paycheck.',
    })
  }
  if (c.amountOwed > 2000) {
    checks.push({
      id: 'large-owe',
      severity: 'warn',
      title: 'Balance due above $2,000',
      detail:
        'If you expect to owe more than $1,000 beyond withholding, the IRS generally requires estimated tax payments during the year to avoid an underpayment penalty.',
    })
  }
  if (f.w2s.length === 0) {
    checks.push({
      id: 'no-w2',
      severity: 'warn',
      title: 'No income entered yet',
      detail: 'Add at least one W-2 or other income source so the engine can compute your return.',
    })
  }
  return checks
}

function fmt(n: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n)
}
