/**
 * ClearFile Return (.cfr) — open, documented JSON save format.
 *
 * Schema (v1):
 * {
 *   "format": "clearfile-return",
 *   "version": 1,
 *   "app": "ClearFile <version>",
 *   "savedAt": "<ISO timestamp>",
 *   "filing": { ...FilingData }
 * }
 */

import type { FilingData, Itemized, W2 } from '../tax/engine'

export const CFR_FORMAT = 'clearfile-return'
export const CFR_VERSION = 1
export const APP_LABEL = 'ClearFile prototype 0.1'

export interface CfrFile {
  format: string
  version: number
  app: string
  savedAt: string
  filing: FilingData
}

const emptyItemized: Itemized = { medical: 0, taxesPaid: 0, mortgageInterest: 0, charity: 0, other: 0 }

export function serializeCfr(filing: FilingData): string {
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

export function parseCfr(text: string): { filing: FilingData; warnings: string[] } {
  let parsed: unknown
  try {
    parsed = JSON.parse(text)
  } catch {
    throw new CfrParseError('The file is not valid JSON.')
  }
  if (!parsed || typeof parsed !== 'object') throw new CfrParseError('The file does not contain a ClearFile return.')
  const obj = parsed as Record<string, unknown>
  if (obj.format !== CFR_FORMAT) {
    throw new CfrParseError(
      `Unrecognized format "${String(obj.format)}" — expected "${CFR_FORMAT}". This is not a ClearFile .cfr return.`
    )
  }
  if (typeof obj.version !== 'number' || obj.version > CFR_VERSION) {
    throw new CfrParseError(`Unsupported version ${String(obj.version)} (this build supports up to ${CFR_VERSION}).`)
  }
  const f = (obj.filing ?? {}) as Record<string, unknown>
  const warnings: string[] = []

  const num = (v: unknown, fallback = 0): number => (typeof v === 'number' && Number.isFinite(v) ? v : fallback)
  const status = ['single', 'mfj', 'mfs', 'hoh'].includes(String(f.status)) ? (String(f.status) as FilingData['status']) : 'single'
  if (!['single', 'mfj', 'mfs', 'hoh'].includes(String(f.status))) warnings.push('Filing status was missing; defaulted to single.')
  const year = f.taxYear === 2025 || f.taxYear === 2026 ? f.taxYear : 2026
  if (year !== f.taxYear) warnings.push('Tax year was missing or unsupported; defaulted to 2026.')

  const w2sIn = Array.isArray(f.w2s) ? f.w2s : []
  if (!Array.isArray(f.w2s) && f.w2s !== undefined) warnings.push('W-2 list was invalid; it was dropped.')
  const w2s: W2[] = w2sIn
    .filter((w): w is Record<string, unknown> => !!w && typeof w === 'object')
    .map((w, i) => ({
      id: typeof w.id === 'string' ? w.id : `w2-import-${i}`,
      employer: typeof w.employer === 'string' ? w.employer : 'Unknown',
      wages: num(w.wages),
      federalWithheld: num(w.federalWithheld),
    }))

  const itemIn = (f.itemized ?? {}) as Record<string, unknown>
  const itemized: Itemized = {
    medical: num(itemIn.medical),
    taxesPaid: num(itemIn.taxesPaid),
    mortgageInterest: num(itemIn.mortgageInterest),
    charity: num(itemIn.charity),
    other: num(itemIn.other),
  }

  return {
    filing: {
      taxYear: year,
      status,
      w2s,
      interest: num(f.interest),
      dividends: num(f.dividends),
      otherIncome: num(f.otherIncome),
      adjustments: num(f.adjustments),
      itemized,
      qualifyingChildren: Math.max(0, Math.round(num(f.qualifyingChildren))),
      otherDependents: Math.max(0, Math.round(num(f.otherDependents))),
      estimatedPayments: num(f.estimatedPayments),
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
