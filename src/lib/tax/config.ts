/**
 * ClearFile — verified federal tax parameters.
 *
 * Sources (checked 2026-11-03):
 *  - TY2026: IRS Rev. Proc. 2025-32 (published 2025-10-09), as reported by
 *    CPA Practice Advisor and Tax Foundation; bracket tables cross-checked
 *    against Fidelity's IRS-sourced tables.
 *  - TY2025: IRS "Federal income tax rates and brackets" (irs.gov), One Big
 *    Beautiful Bill Act amounts (standard deduction) per NTU/CPA Practice
 *    Advisor.
 *  - CTC/ACTC/ODC: IRS.gov "Child Tax Credit" page ($2,200 max, $1,700
 *    refundable, $200k/$400k phase-outs, $50 per $1,000 over); TY2026
 *    refundable amount per Jackson Hewitt's 2026 CTC guide ($1,700).
 */

export type FilingStatus = 'single' | 'mfj' | 'mfs' | 'hoh'
export type TaxYear = 2025 | 2026

export interface Bracket {
  /** Upper bound of this bracket (null = top bracket). */
  upTo: number | null
  rate: number
}

export interface YearConfig {
  year: TaxYear
  standardDeduction: Record<FilingStatus, number>
  brackets: Record<FilingStatus, Bracket[]>
  ctc: {
    maxPerChild: number
    refundablePerChild: number
    phaseoutThresholdMfj: number
    phaseoutThresholdOther: number
    phaseoutRate: number // dollars per $1,000 over threshold
    earnedThreshold: number
    refundableRate: number
  }
  odc: { maxPerDependent: number }
}

export const STATUS_LABELS: Record<FilingStatus, string> = {
  single: 'Single',
  mfj: 'Married filing jointly',
  mfs: 'Married filing separately',
  hoh: 'Head of household',
}

export const STATUS_HELP: Record<FilingStatus, string> = {
  single: 'You were unmarried or legally separated on December 31.',
  mfj: 'You and your spouse combine incomes on one return. Usually the larger deduction.',
  mfs: 'You file separately from your spouse. Some credits and deductions are limited.',
  hoh: 'You are unmarried and paid more than half the cost of keeping up a home for a qualifying person.',
}

const b = (rates: [number, number | null][]): Bracket[] =>
  rates.map(([rate, upTo]) => ({ rate, upTo }))

export const YEARS: Record<TaxYear, YearConfig> = {
  2025: {
    year: 2025,
    standardDeduction: { single: 15750, mfj: 31500, mfs: 15750, hoh: 23625 },
    brackets: {
      single: b([
        [0.1, 11925], [0.12, 48475], [0.22, 103350], [0.24, 197300],
        [0.32, 250525], [0.35, 626350], [0.37, null],
      ]),
      mfj: b([
        [0.1, 23850], [0.12, 96950], [0.22, 206700], [0.24, 394600],
        [0.32, 501050], [0.35, 751600], [0.37, null],
      ]),
      mfs: b([
        [0.1, 11925], [0.12, 48475], [0.22, 103350], [0.24, 197300],
        [0.32, 250525], [0.35, 375800], [0.37, null],
      ]),
      hoh: b([
        [0.1, 17000], [0.12, 64850], [0.22, 103350], [0.24, 197300],
        [0.32, 250500], [0.35, 626350], [0.37, null],
      ]),
    },
    ctc: {
      maxPerChild: 2200,
      refundablePerChild: 1700,
      phaseoutThresholdMfj: 400000,
      phaseoutThresholdOther: 200000,
      phaseoutRate: 50,
      earnedThreshold: 2500,
      refundableRate: 0.15,
    },
    odc: { maxPerDependent: 500 },
  },
  2026: {
    year: 2026,
    standardDeduction: { single: 16100, mfj: 32200, mfs: 16100, hoh: 24150 },
    brackets: {
      single: b([
        [0.1, 12400], [0.12, 50400], [0.22, 105700], [0.24, 201775],
        [0.32, 256225], [0.35, 640600], [0.37, null],
      ]),
      mfj: b([
        [0.1, 24800], [0.12, 100800], [0.22, 211400], [0.24, 403550],
        [0.32, 512450], [0.35, 768700], [0.37, null],
      ]),
      mfs: b([
        [0.1, 12400], [0.12, 50400], [0.22, 105700], [0.24, 201775],
        [0.32, 256225], [0.35, 384350], [0.37, null],
      ]),
      hoh: b([
        [0.1, 17700], [0.12, 67450], [0.22, 105700], [0.24, 201750],
        [0.32, 256200], [0.35, 640600], [0.37, null],
      ]),
    },
    ctc: {
      maxPerChild: 2200,
      refundablePerChild: 1700,
      phaseoutThresholdMfj: 400000,
      phaseoutThresholdOther: 200000,
      phaseoutRate: 50,
      earnedThreshold: 2500,
      refundableRate: 0.15,
    },
    odc: { maxPerDependent: 500 },
  },
}

export const DEFAULT_YEAR: TaxYear = 2026

export const usd = (n: number): string =>
  new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(Math.round(n))

export const pct = (n: number): string => `${(n * 100).toFixed(1)}%`
