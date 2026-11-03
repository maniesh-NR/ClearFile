/**
 * ClearFile — simplified federal tax engine (demo scope).
 *
 * Computes: total income → AGI → (standard | itemized) deduction →
 * taxable income → bracket walk → CTC (incl. simplified ACTC refundable
 * portion) + ODC → total tax → payments → refund/owed.
 *
 * Simplifications vs. a production engine (documented in the blueprint):
 *  - No qualified-dividend / capital-gain preferential stacking.
 *  - ACTC uses the 15%-of-earned-income-above-$2,500 formula, capped at the
 *    per-child refundable maximum, without the full Schedule 8812 worksheets.
 *  - No NIIT, AMT, self-employment tax, or credits beyond CTC/ACTC/ODC.
 * All money rounded to whole dollars.
 */

import type { Bracket, FilingStatus, YearConfig } from './config'

export interface W2 {
  id: string
  employer: string
  wages: number
  federalWithheld: number
}

export interface Itemized {
  medical: number
  taxesPaid: number
  mortgageInterest: number
  charity: number
  other: number
}

export interface FilingData {
  taxYear: 2025 | 2026
  status: FilingStatus
  w2s: W2[]
  interest: number
  dividends: number
  otherIncome: number
  adjustments: number // above-the-line adjustments (demo aggregate)
  itemized: Itemized
  qualifyingChildren: number
  otherDependents: number
  estimatedPayments: number
}

export interface BracketRow {
  rate: number
  lo: number
  hi: number | null
  income: number
  tax: number
}

export interface Computed {
  totalIncome: number
  agi: number
  itemizedTotal: number
  standardDeduction: number
  deduction: number
  deductionChoice: 'standard' | 'itemized'
  taxableIncome: number
  taxBeforeCredits: number
  bracketRows: BracketRow[]
  earnedIncome: number
  ctcMax: number
  ctcPhaseout: number
  ctcApplied: number
  actc: number
  odcMax: number
  odcApplied: number
  totalTax: number
  withholding: number
  totalPayments: number
  balance: number
  isRefund: boolean
  effectiveRate: number
  marginalRate: number
}

const r = (n: number): number => Math.round(n)
const clamp0 = (n: number): number => Math.max(0, n)

function bracketWalk(taxable: number, brackets: Bracket[]): { tax: number; rows: BracketRow[] } {
  let tax = 0
  let lo = 0
  const rows: BracketRow[] = []
  for (const br of brackets) {
    const hi = br.upTo ?? Number.POSITIVE_INFINITY
    const income = clamp0(Math.min(taxable, hi) - lo)
    const rowTax = r(income * br.rate)
    rows.push({ rate: br.rate, lo, hi: br.upTo, income, tax: rowTax })
    tax += rowTax
    lo = hi
    if (taxable <= hi) break
  }
  return { tax, rows }
}

export function compute(f: FilingData, cfg: YearConfig): Computed {
  const wages = f.w2s.reduce((s, w) => s + (w.wages || 0), 0)
  const withholding = f.w2s.reduce((s, w) => s + (w.federalWithheld || 0), 0)

  const totalIncome = r(wages + (f.interest || 0) + (f.dividends || 0) + (f.otherIncome || 0))
  const agi = r(clamp0(totalIncome - (f.adjustments || 0)))

  const itemizedTotal = r(
    (f.itemized.medical || 0) +
      (f.itemized.taxesPaid || 0) +
      (f.itemized.mortgageInterest || 0) +
      (f.itemized.charity || 0) +
      (f.itemized.other || 0)
  )
  const standardDeduction = cfg.standardDeduction[f.status]
  const deductionChoice: 'standard' | 'itemized' = itemizedTotal > standardDeduction ? 'itemized' : 'standard'
  const deduction = Math.max(standardDeduction, itemizedTotal)

  const taxableIncome = r(clamp0(agi - deduction))
  const { tax: taxBeforeCredits, rows: bracketRows } = bracketWalk(taxableIncome, cfg.brackets[f.status])

  // Child Tax Credit (with MAGI phase-out) — MAGI approximated by AGI here.
  const threshold = f.status === 'mfj' ? cfg.ctc.phaseoutThresholdMfj : cfg.ctc.phaseoutThresholdOther
  const kids = f.qualifyingChildren || 0
  const ctcBeforePhaseout = kids * cfg.ctc.maxPerChild
  const phaseoutUnits = Math.max(0, Math.ceil((agi - threshold) / 1000))
  const ctcPhaseout = phaseoutUnits * cfg.ctc.phaseoutRate
  const ctcMax = clamp0(ctcBeforePhaseout - ctcPhaseout)
  const ctcApplied = Math.min(ctcMax, taxBeforeCredits)

  // Credit for Other Dependents (nonrefundable), applied after CTC.
  const odcMax = clamp0((f.otherDependents || 0) * cfg.odc.maxPerDependent - phaseoutUnits * 0)
  const odcApplied = Math.min(odcMax, clamp0(taxBeforeCredits - ctcApplied))

  // Additional (refundable) CTC — simplified Schedule 8812 formula.
  const earned = wages
  const remainingCtc = ctcMax - ctcApplied
  const actc =
    kids > 0
      ? clamp0(
          Math.min(
            remainingCtc,
            r(cfg.ctc.refundableRate * clamp0(earned - cfg.ctc.earnedThreshold)),
            kids * cfg.ctc.refundablePerChild
          )
        )
      : 0

  const totalTax = r(clamp0(taxBeforeCredits - ctcApplied - odcApplied))
  const totalPayments = r(withholding + (f.estimatedPayments || 0))
  const balance = r(totalPayments + actc - totalTax)

  const marginalRate =
    bracketRows.length > 0 ? bracketRows[bracketRows.length - 1].rate : cfg.brackets[f.status][0].rate
  const effectiveRate = totalIncome > 0 ? totalTax / totalIncome : 0

  return {
    totalIncome,
    agi,
    itemizedTotal,
    standardDeduction,
    deduction,
    deductionChoice,
    taxableIncome,
    taxBeforeCredits,
    bracketRows,
    earnedIncome: earned,
    ctcMax,
    ctcPhaseout,
    ctcApplied,
    actc,
    odcMax,
    odcApplied,
    totalTax,
    withholding,
    totalPayments,
    balance,
    isRefund: balance >= 0,
    effectiveRate,
    marginalRate,
  }
}

/** Local, no-AI sanity checks shown on the review screen. */
export interface RuleCheck {
  id: string
  severity: 'info' | 'warn'
  title: string
  detail: string
}

export function ruleChecks(f: FilingData, c: Computed): RuleCheck[] {
  const checks: RuleCheck[] = []
  if (f.w2s.length > 0 && c.withholding === 0) {
    checks.push({
      id: 'no-withholding',
      severity: 'warn',
      title: 'No federal withholding on any W-2',
      detail:
        'Wages are reported but federal income tax withheld is $0 on every form. If any W-2 shows withholding, enter it — this directly changes your refund.',
    })
  }
  if (f.itemized && c.itemizedTotal > 0 && c.itemizedTotal <= c.standardDeduction) {
    checks.push({
      id: 'itemized-below-standard',
      severity: 'info',
      title: 'Itemized deductions are below your standard deduction',
      detail: `You listed ${fmt(c.itemizedTotal)} but the standard deduction for your status is ${fmt(c.standardDeduction)}. ClearFile automatically uses the larger amount, so nothing is lost.`,
    })
  }
  if (f.qualifyingChildren === 0 && f.otherDependents === 0) {
    checks.push({
      id: 'no-dependents',
      severity: 'info',
      title: 'No dependents claimed',
      detail:
        'If you have children under 17 or other dependents, claiming them can be worth up to $2,200 (refundable portion up to $1,700) or $500 each. You can add them in the Dependents step.',
    })
  }
  if (c.isRefund && c.balance > 6000) {
    checks.push({
      id: 'large-refund',
      severity: 'info',
      title: 'Large refund expected',
      detail:
        'A refund above $6,000 usually means significant over-withholding during the year. You may prefer to adjust your W-4 to keep that money in each paycheck.',
    })
  }
  if (!c.isRefund && c.balance > 2000) {
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
