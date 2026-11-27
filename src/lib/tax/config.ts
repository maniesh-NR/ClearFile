// SPDX-License-Identifier: GPL-3.0-only
/**
 * ClearFile — verified federal tax parameters (web engine).
 *
 * Stage-3 parity (ADR-009, ratified 2026-11-14): this module now carries the
 * SAME parameter set as the Flutter reference engine
 * (`clearfile/lib/models/tax_year.dart`) — same values, same per-status
 * maps, same source citations. The web engine supports exactly the
 * reference's year (TY2025): the previously projected TY2026 brackets were
 * dropped rather than half-supported, because parity with a reference that
 * has no TY2026 parameter set cannot be invented (DEBT D32). TY2026 returns
 * when the reference engine gains verified TY2026 parameters.
 *
 * TY2025 values cross-checked in November 2026 against:
 *  - IRS VITA "Standard Deduction" page (basic and 65+/blind amounts, OBBBA)
 *  - Tax Foundation 2025 brackets (rates, SALT phase-down, senior deduction)
 *  - IRS newsroom, enhanced senior deduction (P.L. 119-21 / OBBBA)
 *  - IRS Form 1040 instructions, Qualified Dividends worksheet breakpoints
 *  - H&R Block & Jackson Hewitt TY2025 pages (student loan interest phaseouts)
 *
 * DEMO SOFTWARE: verify every number against official IRS tables before
 * relying on any calculation produced with this module.
 */

export type FilingStatus =
  | 'single'
  | 'marriedJoint'
  | 'marriedSeparate'
  | 'headOfHousehold'
  | 'survivingSpouse'

export type TaxYear = 2025

/** How the taxpayer wants their deduction determined ('auto' = compare). */
export type DeductionMethod = 'auto' | 'standard' | 'itemized'

/** One rung of a progressive rate schedule (upTo null = top bracket). */
export interface Bracket {
  rate: number
  upTo: number | null
}

export interface TaxYearParameters {
  year: TaxYear
  /** Basic standard deduction by filing status (OBBBA amounts for 2025). */
  standardDeduction: Record<FilingStatus, number>
  /** Additional standard deduction per person 65+ or blind
   * (standard-deduction route only). IRS VITA: $2,000 single/HoH, $1,600
   * married per person for 2025. */
  additionalPerAgedOrBlindPerson: Record<FilingStatus, number>
  /** OBBBA "senior deduction": $6,000 per person 65+ for 2025-2028, usable
   * with the standard deduction OR itemizing, phased out at 6% of MAGI over
   * the phaseout start. */
  seniorDeductionPerPerson: number
  seniorPhaseoutStart: Record<FilingStatus, number>
  seniorPhaseoutRate: number
  /** Ordinary income rate schedules. */
  ordinaryBrackets: Record<FilingStatus, Bracket[]>
  /** Qualified dividends / net LTCG: top of the 0% band and top of the 15%
   * band, by filing status (stacked on ordinary income) — QDIVCG worksheet
   * lines 6 and 13, Instructions for Form 1040 (2025). The MFS 15% cap is a
   * flat $300,000 by statute (NOT half of MFJ's $600,050 — corrected by the
   * golden fixtures, 2026-11-14). */
  qdiZeroCap: Record<FilingStatus, number>
  qdiFifteenCap: Record<FilingStatus, number>
  /** SALT cap (OBBBA): $40,000 for 2025 ($20,000 MFS), reduced by 30% of
   * MAGI over the phaseout start, never below the floor. */
  saltBaseCap: Record<FilingStatus, number>
  saltPhaseoutStart: Record<FilingStatus, number>
  saltPhaseoutRate: number
  saltFloor: Record<FilingStatus, number>
  /** Net investment income tax (simplified: interest, dividends, gains).
   * Thresholds per the Instructions for Form 8960 (2025). */
  niitRate: number
  niitThreshold: Record<FilingStatus, number>
  /** Child Tax Credit / Additional CTC (OBBBA: $2,200 per child, up to
   * $1,700 refundable). Phase-out per Schedule 8812 (2025): 5% of the
   * excess MAGI rounded up to the next $1,000. */
  ctcPerChild: number
  actcPerChild: number
  actcRate: number
  actcEarnedIncomeFloor: number
  ctcPhaseoutStart: Record<FilingStatus, number>
  ctcPhaseoutRate: number
  /** Credit for other dependents. */
  odcPerDependent: number
  /** Student loan interest deduction (MFS not eligible — encoded by the
   * phaseout start being greater than the end, mirroring the reference). */
  studentLoanMax: number
  studentLoanPhaseoutStart: Record<FilingStatus, number>
  studentLoanPhaseoutEnd: Record<FilingStatus, number>
  /** Charitable deduction AGI ceilings (simplified). */
  charitableCashAgiLimit: number
  charitableNonCashAgiLimit: number
}

export const STATUS_LABELS: Record<FilingStatus, string> = {
  single: 'Single',
  marriedJoint: 'Married filing jointly',
  marriedSeparate: 'Married filing separately',
  headOfHousehold: 'Head of household',
  survivingSpouse: 'Qualifying surviving spouse',
}

export const STATUS_HELP: Record<FilingStatus, string> = {
  single: 'You were unmarried or legally separated as of December 31, 2025.',
  marriedJoint:
    'You were married and are reporting both spouses’ income on one return. This is usually (not always) the lower-tax option.',
  marriedSeparate:
    'You were married but each spouse files their own return. Some credits and deductions are limited or unavailable with this status.',
  headOfHousehold:
    'You were unmarried on December 31, 2025, paid more than half the cost of keeping up a home, and can claim a qualifying person such as a child.',
  survivingSpouse:
    'Your spouse died in 2023 or 2024, you have a dependent child, and you have not remarried. You use the married-jointly rates.',
}

export const DEDUCTION_METHOD_LABELS: Record<DeductionMethod, string> = {
  auto: 'Compare and pick the better one',
  standard: 'Use the standard deduction',
  itemized: 'Itemize my deductions',
}

/** Sources shown in the app's About surfaces. */
export const PARAMETER_SOURCES: string[] = [
  'https://apps.irs.gov/app/vita/content/00/00_13_005.jsp',
  'https://taxfoundation.org/data/all/federal/2025-tax-brackets/',
  'https://www.irs.gov/newsroom/check-your-eligibility-for-the-new-enhanced-deduction-for-seniors',
  'https://www.irs.gov/instructions/i1040gi',
  'https://www.irs.gov/pub/irs-pdf/f1040s1a.pdf',
  'https://www.irs.gov/pub/irs-pdf/i1040sca.pdf',
  'https://www.irs.gov/pub/irs-pdf/f1040s8.pdf',
  'https://www.irs.gov/instructions/i8960',
  'https://www.irs.gov/taxtopics/tc456',
  'https://www.congress.gov/bill/119th-congress/house-bill/1',
]

const b = (rates: [number, number | null][]): Bracket[] =>
  rates.map(([rate, upTo]) => ({ rate, upTo }))

// The parameter TABLE retired at N6 (2026-11-27, ADR-016's conversion
// day): the shared Rust core now serves the web through wasm32 — the
// table's ONE true source is the core's own params (served via
// clearfile_params_json; the adapter's params()/yearParams()). The
// labels, formatters, and display constants below live on.
export const DEFAULT_YEAR: TaxYear = 2025
export const SUPPORTED_YEARS: TaxYear[] = [2025]

export const usd = (n: number): string =>
  new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(Math.round(n))

export const pct = (n: number): string => `${(n * 100).toFixed(1)}%`
