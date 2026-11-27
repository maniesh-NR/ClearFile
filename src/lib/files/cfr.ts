// SPDX-License-Identifier: GPL-3.0-only

// RETIRED 2026-11-27 (N6, the epilogue's terminal gate): per ADR-016, the
// maintenance freeze converted to retirement the day the shared Rust core
// began serving the web (WASM); per ADR-017 this engine is now a FROZEN
// TRANSITION ARTIFACT — out of the app's runtime import graph, kept
// in-tree as a study artifact, still tsc-checked, and BYTE-FROZEN from
// this edit: no further changes of any class land here, bug and security
// fixes included — they go to the Rust core (src/lib/wasm/ is the
// successor adapter).
/**
 * ClearFile Return — open, documented JSON save format (ADR-015).
 *
 * The unified envelope (also what the Flutter app writes and what rides
 * inside a ClearFile exchange container's clearfile.json entry):
 *
 *   { "format": "clearfile-return", "version": 2, "app": …,
 *     "savedAt": …, "filing": { …TaxReturnData shape… } }
 *
 * Schema v2 (Stage-3 parity, 2026-11-15): `filing` holds the reference
 * engine's TaxReturnData shape (the same fields clearfile/lib/models/
 * tax_return.dart serializes), including the qualified-dividend / LTCG /
 * senior / SALT / student-loan fields and the dependents list.
 *
 * Schema v1 (pre-parity web shape: interest / dividends / adjustments /
 * nested itemized / child counts) is accepted on load and migrated with
 * the same conservative mapping the browser store's persist migration
 * uses — see migrateV1 below. Version guard: files claiming a version
 * higher than CFR_VERSION are refused (no format change ships before a
 * version guard, DEBT D3).
 *
 * The legacy flat layout the Flutter app wrote through v1.0.1
 * (`format: "clearfile.return"`, filing fields at the top level, flat
 * `formatVersion`) is accepted on load and lifted losslessly into the
 * envelope shape — the fields are the same model (ADR-015 unification).
 */

import type { Dependent, TaxReturnData, W2Entry } from '../tax/engine'
import type { DeductionMethod, FilingStatus } from '../tax/config'

export const CFR_FORMAT = 'clearfile-return'
export const CFR_VERSION = 2
export const LEGACY_FLAT_FORMAT = 'clearfile.return'
export const APP_LABEL = 'ClearFile prototype 0.2'

export interface CfrFile {
  format: string
  version: number
  app: string
  savedAt: string
  filing: TaxReturnData
}

const STATUSES: FilingStatus[] = [
  'single', 'marriedJoint', 'marriedSeparate', 'headOfHousehold', 'survivingSpouse',
]
const METHODS: DeductionMethod[] = ['auto', 'standard', 'itemized']

export function serializeCfr(filing: TaxReturnData): string {
  const file: CfrFile = {
    format: CFR_FORMAT,
    version: CFR_VERSION,
    app: APP_LABEL,
    savedAt: new Date().toISOString(),
    filing,
  }
  return JSON.stringify(file, null, 2)
}

export class CfrParseError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'CfrParseError'
  }
}

const num = (v: unknown, fallback = 0): number => (typeof v === 'number' && Number.isFinite(v) ? v : fallback)
const flag = (v: unknown): boolean => v === true

/** v1 → v2 filing-shape migration (same conservative mapping as the
 * Dart `ReturnFileCodec._migrateWebV1`; see clearfile/lib/io/return_format.dart).
 * The exact warning wording and order are pinned by BOTH suites against the
 * shared fixtures (fixtures/migration/, DEBT D34). */
function migrateV1(f: Record<string, unknown>, warnings: string[]): Record<string, unknown> {
  const o: Record<string, unknown> = { ...f }
  o.taxYear = 2025
  warnings.push('Saved with an older prototype: the return was migrated to the current engine model.')
  if (o.status === 'mfj') o.status = 'marriedJoint'
  else if (o.status === 'mfs') o.status = 'marriedSeparate'
  else if (o.status === 'hoh') o.status = 'headOfHousehold'
  o.interestIncome = num(o.interest)
  o.ordinaryDividends = num(o.dividends)
  if (num(o.adjustments) > 0) warnings.push('"Adjustments to income" had no equivalent in the current model and was dropped — re-enter it as student loan interest if that is what it was.')
  delete o.interest
  delete o.dividends
  delete o.adjustments

  const item = o.itemized && typeof o.itemized === 'object' && !Array.isArray(o.itemized)
    ? (o.itemized as Record<string, unknown>)
    : {}
  o.stateLocalIncomeOrSalesTax = num(item.taxesPaid)
  o.realEstateTax = 0
  o.mortgageInterest = num(item.mortgageInterest)
  o.charitableCash = num(item.charity)
  o.charitableNonCash = 0
  if (num(item.medical) > 0 || num(item.other) > 0) {
    warnings.push('Medical and "other" itemized expenses have no equivalent in the current model and were dropped.')
  }
  delete o.itemized

  // D34 parity correction (2026-11-23): the dependent-count bound is
  // 0..100 placeholder rows on BOTH file readers — the Dart reference's
  // historical clamp, now pinned by the shared edge fixture
  // (fixtures/migration/v1-web-envelope-edge-clamp.json).
  const kids = Math.min(100, Math.max(0, Math.round(num(o.qualifyingChildren))))
  const otherDeps = Math.min(100, Math.max(0, Math.round(num(o.otherDependents))))
  delete o.qualifyingChildren
  delete o.otherDependents
  const dependents: Dependent[] = []
  for (let i = 0; i < kids; i++) dependents.push({ name: '', age: 0, relationship: '', qualifyingChild: true, otherDependentCredit: false })
  for (let i = 0; i < otherDeps; i++) dependents.push({ name: '', age: 0, relationship: '', qualifyingChild: false, otherDependentCredit: true })
  if (dependents.length > 0) warnings.push('Dependent counts were migrated; re-enter their names in the Dependents step.')
  o.dependents = dependents
  return o
}

export function parseCfr(text: string): { filing: TaxReturnData; warnings: string[] } {
  let parsed: unknown
  try {
    parsed = JSON.parse(text)
  } catch {
    throw new CfrParseError('The file is not valid JSON.')
  }
  if (!parsed || typeof parsed !== 'object') throw new CfrParseError('The file does not contain a ClearFile return.')
  const obj = parsed as Record<string, unknown>

  let f: Record<string, unknown>
  const warnings: string[] = []
  if (obj.format === LEGACY_FLAT_FORMAT) {
    // Legacy flat layout (the Flutter app through v1.0.1, and its autosave
    // store): the same filing fields at the top level beside the marker.
    // Guard, then lift losslessly (ADR-015).
    if (typeof obj.formatVersion === 'number' && obj.formatVersion > 1) {
      throw new CfrParseError(`Unsupported version ${obj.formatVersion} (this build supports up to ${CFR_VERSION}).`)
    }
    f = { ...obj }
    delete f.format
    delete f.formatVersion
    if (typeof f.displayName === 'string' || typeof f.id === 'string') {
      warnings.push('Return metadata (name, dates) from the Flutter app is kept in the file but not carried by the web prototype.')
    }
  } else {
    if (obj.format !== CFR_FORMAT) {
      throw new CfrParseError(
        `Unrecognized format "${String(obj.format)}" — expected "${CFR_FORMAT}". This is not a ClearFile return.`
      )
    }
    if (typeof obj.version !== 'number' || obj.version > CFR_VERSION) {
      throw new CfrParseError(`Unsupported version ${String(obj.version)} (this build supports up to ${CFR_VERSION}).`)
    }
    f = (obj.filing ?? {}) as Record<string, unknown>
    if (obj.version < 2) f = migrateV1(f, warnings)
  }
  if (!f || typeof f !== 'object' || Array.isArray(f)) {
    throw new CfrParseError('The file has no return payload.')
  }

  const status = STATUSES.includes(String(f.filingStatus ?? f.status) as FilingStatus)
    ? (String(f.filingStatus ?? f.status) as FilingStatus)
    : 'single'
  if (!STATUSES.includes(String(f.filingStatus ?? f.status) as FilingStatus)) {
    warnings.push('Filing status was missing; defaulted to single.')
  }
  let year = num(f.taxYear)
  if (year !== 2025) {
    year = 2025
    warnings.push('Tax year was missing or unsupported; defaulted to 2025 (the engine supports TY2025).')
  }
  const deductionMethod = METHODS.includes(String(f.deductionMethod) as DeductionMethod)
    ? (String(f.deductionMethod) as DeductionMethod)
    : 'auto'

  const w2sIn = Array.isArray(f.w2s) ? f.w2s : []
  if (!Array.isArray(f.w2s) && f.w2s !== undefined) warnings.push('W-2 list was invalid; it was dropped.')
  const w2s: W2Entry[] = w2sIn
    .filter((w): w is Record<string, unknown> => !!w && typeof w === 'object')
    .map((w, i) => ({
      id: typeof w.id === 'string' ? w.id : `w2-import-${i}`,
      employer: typeof w.employer === 'string' ? w.employer : 'Unknown',
      wages: num(w.wages),
      withholding: num(w.withholding),
    }))

  const depsIn = Array.isArray(f.dependents) ? f.dependents : []
  if (!Array.isArray(f.dependents) && f.dependents !== undefined) warnings.push('Dependent list was invalid; it was dropped.')
  const dependents: Dependent[] = depsIn
    .filter((d): d is Record<string, unknown> => !!d && typeof d === 'object')
    .map((d, i) => ({
      id: typeof d.id === 'string' ? d.id : `dep-import-${i}`,
      name: typeof d.name === 'string' ? d.name : '',
      age: Math.max(0, Math.round(num(d.age))),
      relationship: typeof d.relationship === 'string' ? d.relationship : '',
      qualifyingChild: flag(d.qualifyingChild),
      otherDependentCredit: flag(d.otherDependentCredit),
    }))

  return {
    filing: {
      taxYear: year,
      filingStatus: status,
      taxpayer65OrOlder: flag(f.taxpayer65OrOlder),
      spouse65OrOlder: flag(f.spouse65OrOlder),
      taxpayerBlind: flag(f.taxpayerBlind),
      spouseBlind: flag(f.spouseBlind),
      w2s,
      interestIncome: num(f.interestIncome),
      ordinaryDividends: num(f.ordinaryDividends),
      qualifiedDividends: num(f.qualifiedDividends),
      longTermCapitalGains: num(f.longTermCapitalGains),
      otherIncome: num(f.otherIncome),
      studentLoanInterest: num(f.studentLoanInterest),
      deductionMethod,
      stateLocalIncomeOrSalesTax: num(f.stateLocalIncomeOrSalesTax),
      realEstateTax: num(f.realEstateTax),
      mortgageInterest: num(f.mortgageInterest),
      charitableCash: num(f.charitableCash),
      charitableNonCash: num(f.charitableNonCash),
      estimatedPayments: num(f.estimatedPayments),
      dependents,
    },
    warnings,
  }
}

/** Trigger a browser download for a text payload. */
export function downloadText(filename: string, content: string, mime = 'application/json'): void {
  const blob = new Blob([content], { type: `${mime};charset=utf-8` })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 5000)
}

/** Trigger a browser download for binary payload. */
export function downloadBytes(filename: string, bytes: Uint8Array, mime = 'application/octet-stream'): void {
  const blob = new Blob([bytes as unknown as BlobPart], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 5000)
}
