// SPDX-License-Identifier: GPL-3.0-only
/**
 * The WASM core adapter (N6, the ADR-017 epilogue's terminal lane): the
 * TypeScript web prototype's compute + format layer over the shared Rust
 * core compiled to wasm32-unknown-unknown — the SAME flat C ABI every
 * native lane consumes (the committed core-ffi/clearfile.h), loaded with
 * the platform's own WebAssembly API. The TS engine + the TS codecs are
 * RETIRED frozen transition artifacts (ADR-016's conversion day: the
 * shared Rust core now serves the web).
 *
 * NEGATIVE PROVENANCE (the N6 gate's clean-room ruling, LEGAL-5): this
 * loader is written from the committed header's own contract alone — no
 * wasm-bindgen, no Emscripten, no tutorial code; the alloc/pointer/
 * NUL-terminated-read pattern is the unprotectable functional method of
 * that ABI, expressed in our own code. ZERO npm dependencies.
 *
 * The N6 gate's engineering rulings this adapter owns:
 * - ENG-1/SEC-1: alloc/dealloc are LENGTH-PAIRED (interior-NUL payloads —
 *   every .tax container — are the probe-verified trap class of a
 *   strlen-derived free; the C ABI's own clearfile_free pair stays
 *   untouched for the data functions' returns).
 * - SEC-2/ENG-3: catch_unwind does NOT transfer to wasm32 (a Rust panic is
 *   an abort — a WebAssembly RuntimeError trap): every call is
 *   try/catch-mapped to the guard's own wording family, and after a trap
 *   the instance is treated as POISONED (the recorded posture).
 * - ENG-4: the export year rides a BigInt (the i64 ABI parameter); input
 *   lengths >= 2^32 are refused (a JS Number would silently wrap the
 *   wasm32 i32 lengths); no views are cached across calls (memory growth
 *   detaches buffers).
 * - The output read is NUL-terminated (the CString return contract) and
 *   hard-fails at the memory's end rather than scan past it.
 */
import type { FilingStatus, DeductionMethod, TaxYear, TaxYearParameters, Bracket } from '../tax/config'

// The display constants this adapter owns (the retired config.ts YEARS
// record's selection surface — the same values, carried; config.ts keeps
// its own copies for the UI's labels/pickers). Keeping them local keeps
// the emitted module's imports TYPE-ONLY (erased at emit), the suite
// tsconfigs' own discipline.
const DEFAULT_YEAR: TaxYear = 2025
const SUPPORTED_YEARS: TaxYear[] = [2025]

// ---------------------------------------------------------------------------
// The retired engine's carried-on surface (PROD-1's ruling: the types,
// labels, and formatters live on; the engine, the parameter table, and the
// codecs retire — every interface below is the same contract the frozen
// transition artifacts carry, verbatim).
// ---------------------------------------------------------------------------

export interface W2Entry {
  id?: string
  employer: string
  wages: number
  withholding: number
}

export interface Dependent {
  id?: string
  name: string
  age: number
  relationship: string
  qualifyingChild: boolean
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

export interface BracketSlice {
  rate: number
  lo: number
  hi: number | null
  income: number
  tax: number
}

export interface RuleCheck {
  id: string
  severity: 'info' | 'warn'
  title: string
  detail: string
}

/** The open-failure family (the retired cfr.ts's error contract, carried). */
export class CfrParseError extends Error {}

/** The core-module failure family (the guard's own wording). */
class CoreError extends Error {}

// The display glue (PROD-1: formatters live on — pure sums over the
// editing return, before any compute).
export const totalWages = (r: Pick<TaxReturnData, 'w2s'>): number =>
  r.w2s.reduce((s, w) => s + (w.wages || 0), 0)

export const totalWithholding = (r: Pick<TaxReturnData, 'w2s'>): number =>
  r.w2s.reduce((s, w) => s + (w.withholding || 0), 0)

export const totalIncome = (
  r: Pick<TaxReturnData, 'w2s' | 'interestIncome' | 'ordinaryDividends' | 'qualifiedDividends' | 'longTermCapitalGains' | 'otherIncome'>,
): number =>
  totalWages(r) +
  (r.interestIncome || 0) +
  (r.ordinaryDividends || 0) +
  (r.qualifiedDividends || 0) +
  (r.longTermCapitalGains || 0) +
  (r.otherIncome || 0)

export const isRefund = (c: TaxResult): boolean => c.refund > 0

export const refundOrOwed = (c: TaxResult): number => c.refund - c.amountOwed

// The display walk over the core-served table (the parameter DATA comes
// from the core through the boundary — zero parameter logic here).
export function bracketWalk(taxable: number, brackets: Bracket[]): BracketSlice[] {
  const rows: BracketSlice[] = []
  let lo = 0
  for (const br of brackets) {
    const income = Math.max(0, Math.min(taxable, br.upTo ?? Number.POSITIVE_INFINITY) - lo)
    rows.push({ rate: br.rate, lo, hi: br.upTo, income, tax: income * br.rate })
    if (br.upTo == null || taxable <= br.upTo) break
    lo = br.upTo
  }
  return rows
}

// The app-side review heuristics (the retired engine.ts's own UI family —
// the review_rules.dart analogue: reads the filing + the result, produces
// UI hints; no parameter or compute logic).
export function ruleChecks(f: TaxReturnData, c: TaxResult): RuleCheck[] {
  const usd = (n: number): string => `$${n.toFixed(2)}`
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
      detail: `Your itemized total (after the SALT cap) is ${usd(c.itemizedDeductionTotal)} and the standard deduction for your status is ${usd(c.standardDeductionTotal)}. ClearFile automatically uses the larger amount, so nothing is lost.`,
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

// ---------------------------------------------------------------------------
// The loader (the one-time async init; the adapter's functions are sync
// after it — the app boots its loading gate until wasmReady()).
// ---------------------------------------------------------------------------

interface WasmExports {
  memory: WebAssembly.Memory
  clearfile_alloc: (len: number) => number
  clearfile_dealloc: (ptr: number, len: number) => void
  clearfile_free: (ptr: number) => void
  clearfile_last_error: () => number
  clearfile_params_json: () => number
  clearfile_compute: (ptr: number, len: number) => number
  clearfile_decode_envelope: (ptr: number, len: number) => number
  clearfile_encode_envelope: (fptr: number, flen: number, sptr: number, slen: number) => number
  clearfile_import_txf: (ptr: number, len: number) => number
  clearfile_export_txf: (ptr: number, len: number, month: number, day: number, year: bigint) => number
  clearfile_inspect_tax: (ptr: number, len: number) => number
  clearfile_load_and_compute: (ptr: number, len: number) => number
  clearfile_export_tax_container: (eptr: number, elen: number, out: number, cap: number, outLen: number) => number
}

let wasm: WasmExports | null = null
let poisoned = false
let paramsCache: TaxYearParameters | null = null
const encoder = new TextEncoder()
const decoder = new TextDecoder('utf-8', { fatal: false })

export function wasmReady(): boolean {
  return wasm !== null && !poisoned
}

/** Initialize from bytes (the CI suites' path — the node harness reads the
 * module file; no node: import ever lands in this browser module). */
export function initWasmFromBuffer(bytes: ArrayBuffer | Uint8Array): Promise<void> {
  if (wasm) return Promise.resolve()
  return WebAssembly.instantiate(bytes, {}).then((instantiated) => {
    // The bufferSource overload resolves { module, instance } per the
    // spec (some TS lib typings model it as Instance — handle both
    // shapes, the runtime decides).
    const instance =
      instantiated instanceof WebAssembly.Instance
        ? instantiated
        : (instantiated as { instance: WebAssembly.Instance }).instance
    wasm = instance.exports as unknown as WasmExports
    poisoned = false
    paramsCache = null
  })
}

/** Initialize from the same-origin module URL (the browser path; any
 * cross-origin/CDN change re-opens the privacy copy — LEGAL-5). */
export async function initWasm(url = '/clearfile-core.wasm'): Promise<void> {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`The core module could not be loaded (${response.status}).`)
  }
  await initWasmFromBuffer(await response.arrayBuffer())
}

function assertReady(): WasmExports {
  if (!wasm || poisoned) {
    throw new CoreError(
      poisoned
        ? 'The operation failed unexpectedly — an internal error occurred.'
        : 'The core module is not loaded yet.',
    )
  }
  return wasm
}

/** Map a trap (a Rust panic aborts on wasm32 — SEC-2/ENG-3) to the
 * guard's own wording family and poison the instance. */
function mapped<T>(body: () => T): T {
  try {
    return body()
  } catch (e) {
    if (e instanceof WebAssembly.RuntimeError) {
      poisoned = true
      throw new CoreError('The operation failed unexpectedly — an internal error occurred.')
    }
    throw e
  }
}

function lastError(): string {
  const w = wasm
  if (!w) return 'The core module is not loaded yet.'
  return readCString(mapped(() => w.clearfile_last_error()), false)
}

/** Write `bytes` into a length-paired module buffer, run `body(ptr, len)`,
 * and release the buffer on every path (SEC-1/ENG-1: interior NULs are
 * legal payload bytes — the length governs, never a strlen). */
function withInput<T>(bytes: Uint8Array, body: (ptr: number, len: number) => T): T {
  const w = assertReady()
  const len = bytes.length
  if (len >= 0x1_0000_0000) {
    throw new RangeError('The input is too large for the core module.')
  }
  const ptr = mapped(() => w.clearfile_alloc(len))
  if (ptr === 0) throw new CoreError(lastError())
  try {
    // A fresh view AFTER alloc: growth during alloc may detach any earlier
    // buffer (ENG-4: no cached views across calls).
    new Uint8Array(w.memory.buffer, ptr, len).set(bytes)
    return body(ptr, len)
  } finally {
    // A trap poisoned the instance: a post-trap dealloc could itself trap
    // (the poisoning may leave the allocator's state suspect) and would
    // mask the mapped wording — the leaked buffer is the honest cost of
    // the poisoned posture (the N6-exit ENG-3 rider).
    if (!poisoned) w.clearfile_dealloc(ptr, len)
  }
}

/** Read a NUL-terminated owned C string at `ptr`; optionally free it
 * through the data functions' own free (NEVER for alloc buffers). */
function readCString(ptr: number, free: boolean): string {
  const w = assertReady()
  const buf = new Uint8Array(w.memory.buffer)
  let end = ptr
  if (end >= buf.length) {
    throw new CoreError('The core module returned a buffer outside its memory.')
  }
  while (end < buf.length && buf[end] !== 0) end++
  if (end >= buf.length) {
    throw new CoreError('The core module returned an unterminated buffer — an internal error occurred.')
  }
  const text = decoder.decode(buf.subarray(ptr, end))
  if (free) w.clearfile_free(ptr)
  return text
}

function callText(payload: string | Uint8Array, fn: (w: WasmExports, ptr: number, len: number) => number): string {
  const w = assertReady()
  const bytes = typeof payload === 'string' ? encoder.encode(payload) : payload
  return withInput(bytes, (ptr, len) => {
    const owned = mapped(() => fn(w, ptr, len))
    if (owned === 0) throw new CoreError(lastError())
    return readCString(owned, true)
  })
}

// ---------------------------------------------------------------------------
// The serving surface (the same contracts the retired TS modules carried).
// ---------------------------------------------------------------------------

function inputJson(f: TaxReturnData): string {
  const clone: Record<string, unknown> = { ...f }
  clone.w2s = (f.w2s ?? []).map((w) => ({ employer: w.employer, wages: w.wages, withholding: w.withholding }))
  clone.dependents = (f.dependents ?? []).map((d) => ({
    name: d.name,
    age: d.age,
    relationship: d.relationship,
    qualifyingChild: d.qualifyingChild,
    otherDependentCredit: d.otherDependentCredit,
  }))
  return JSON.stringify(clone)
}

function parseResult(text: string): TaxResult {
  const result = JSON.parse(text) as TaxResult
  if (result.deductionMethodUsed !== 'standard' && result.deductionMethodUsed !== 'itemized') {
    throw new CoreError('The core module returned an unknown deduction method.')
  }
  return result
}

/** The compute (the ONLY engine — the wasm core through the flat ABI). */
export function compute(filing: TaxReturnData): TaxResult {
  return parseResult(callText(inputJson(filing), (w, ptr, len) => w.clearfile_compute(ptr, len)))
}

/** The parameter table, served by the core (parsed once at first use;
 * the display constants stay in config.ts — the DATA is the core's). */
export function params(): TaxYearParameters {
  if (!paramsCache) {
    const w = assertReady()
    const owned = mapped(() => w.clearfile_params_json())
    if (owned === 0) throw new CoreError(lastError())
    paramsCache = JSON.parse(readCString(owned, true)) as TaxYearParameters
  }
  return paramsCache
}

/** The year table the UI selects over (the retired config.ts YEARS
 * record's successor: the display constants + the core-served table). */
export function yearParams(year: TaxYear): TaxYearParameters {
  if (year !== DEFAULT_YEAR && !SUPPORTED_YEARS.includes(year)) {
    throw new RangeError(`Tax year ${year} is not supported (the table serves ${SUPPORTED_YEARS.join(', ')}).`)
  }
  return params()
}

/** Open a `.clearfile.json` envelope (the v1→v2 migrations surface as
 * the warnings array, verbatim from the core's own wording). */
export function parseCfr(text: string): { filing: TaxReturnData; warnings: string[] } {
  let decoded: { filing: TaxReturnData; warnings: string[] }
  try {
    decoded = JSON.parse(callText(text, (w, ptr, len) => w.clearfile_decode_envelope(ptr, len)))
  } catch (e) {
    if (e instanceof CoreError) throw new CfrParseError(e.message)
    throw e
  }
  if (!decoded.filing || !Array.isArray(decoded.warnings)) {
    throw new CfrParseError('The file could not be opened as a ClearFile return.')
  }
  return decoded
}

/** Save a `.clearfile.json` envelope (the core's writer; the savedAt
 * timestamp is the caller's). */
export function serializeCfr(filing: TaxReturnData, savedAt = new Date().toISOString()): string {
  const w = assertReady()
  const filingBytes = encoder.encode(inputJson(filing))
  const savedBytes = encoder.encode(savedAt)
  return withInput(filingBytes, (fptr, flen) =>
    withInput(savedBytes, (sptr, slen) => {
      const owned = mapped(() => w.clearfile_encode_envelope(fptr, flen, sptr, slen))
      if (owned === 0) throw new CoreError(lastError())
      return readCString(owned, true)
    }),
  )
}

/** Export TXF text (the export date is today's, as the retired writer). */
export function exportTxf(f: TaxReturnData, now = new Date()): string {
  const w = assertReady()
  const filingBytes = encoder.encode(inputJson(f))
  return withInput(filingBytes, (ptr, len) => {
    const owned = mapped(() =>
      // ENG-4: the i64 year rides a BigInt.
      w.clearfile_export_txf(ptr, len, now.getMonth() + 1, now.getDate(), BigInt(now.getFullYear())),
    )
    if (owned === 0) throw new CoreError(lastError())
    return readCString(owned, true)
  })
}

/** Import TXF text (the documented bridge's importer — the same payload
 * the Flutter app's importer produces). */
export function importTxf(text: string): { displayName: string; input: TaxReturnData; warnings: string[]; unknownCodes: string[] } {
  return JSON.parse(callText(text, (w, ptr, len) => w.clearfile_import_txf(ptr, len)))
}

/** The `.tax` container analysis (the retired taxfile.ts's own interface,
 * carried verbatim — the core's inspect serves it; the optional filing
 * rides the composed container-import pipeline, the N3-recorded
 * addition). */
export interface TaxAnalysis {
  isZip: boolean
  clearfileContainer: boolean
  /** True when the entries match the modern Intuit container shape
   * (`manifest.xml` + a `tax:<uuid>` data entry — public write-up, RE
   * protocol §5). Nothing is decrypted; the summary says so. */
  intuitModernContainer: boolean
  filing?: TaxReturnData
  warnings: string[]
  entries: {
    name: string
    size: number
    method?: number
    /** Shannon entropy in bits/byte over stored data (stored entries
     * with ≥128 bytes only). */
    entropy?: number
    /** Entropy ≥ 7.5 — the signature of encrypted/compressed content. */
    likelyEncrypted?: boolean
    preview?: string
  }[]
  summary: string
}

export function analyzeTaxFile(buf: Uint8Array): TaxAnalysis {
  const analysis = JSON.parse(
    callText(buf, (w, ptr, len) => w.clearfile_inspect_tax(ptr, len)),
  ) as Omit<TaxAnalysis, 'filing'>
  let filing: TaxReturnData | undefined
  try {
    // The ClearFile container's own payload through the composed import
    // pipeline (the N3-recorded addition — everything the viewer needs);
    // a non-ClearFile container leaves the filing absent, exactly as the
    // retired analyzer did.
    filing = loadAndCompute(buf).filing
  } catch {
    filing = undefined
  }
  return { ...analysis, filing }
}

/** Export a ClearFile exchange container (the `.tax` STORE-only ZIP): the
 * envelope serializes through the core's own writer, then the binary
 * container bytes ride the caller-allocated length-out channel (the ONE
 * binary export — never the NUL-terminated CString returns). */
export function exportTaxContainer(filing: TaxReturnData): Uint8Array {
  const w = assertReady()
  const envelopeBytes = encoder.encode(serializeCfr(filing))
  return withInput(envelopeBytes, (eptr, elen) => {
    // The length-out slot: 4 bytes on wasm32 (a uintptr_t).
    const lenSlot = mapped(() => w.clearfile_alloc(4))
    if (lenSlot === 0) throw new CoreError(lastError())
    try {
      const probe = mapped(() => w.clearfile_export_tax_container(eptr, elen, 0, 0, lenSlot))
      if (probe === -1) throw new CoreError(lastError())
      const needed = new DataView(w.memory.buffer).getUint32(lenSlot, true)
      const out = mapped(() => w.clearfile_alloc(needed))
      if (out === 0) throw new CoreError(lastError())
      try {
        const rc = mapped(() => w.clearfile_export_tax_container(eptr, elen, out, needed, lenSlot))
        if (rc === -1) throw new CoreError(lastError())
        if (rc !== 0) throw new CoreError('The container export could not be written.')
        return new Uint8Array(new Uint8Array(w.memory.buffer, out, needed))
      } finally {
        if (!poisoned) w.clearfile_dealloc(out, needed)
      }
    } finally {
      if (!poisoned) w.clearfile_dealloc(lenSlot, 4)
    }
  })
}

/** The composed open pipeline (the container import / the envelope
 * decode + compute — what the native lanes' viewers run). */
export interface LoadedReturn {
  source: string
  filing: TaxReturnData
  result: TaxResult
  warnings: string[]
}

export function loadAndCompute(bytes: Uint8Array): LoadedReturn {
  return JSON.parse(callText(bytes, (w, ptr, len) => w.clearfile_load_and_compute(ptr, len)))
}

// ---------------------------------------------------------------------------
// The browser download helpers (carried from the retired cfr.ts — pure
// DOM glue, nothing codec-shaped).
// ---------------------------------------------------------------------------

export function downloadText(filename: string, content: string, mime = 'application/json'): void {
  const blob = new Blob([content], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}

export function downloadBytes(filename: string, bytes: Uint8Array, mime = 'application/octet-stream'): void {
  const blob = new Blob([bytes as BlobPart], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
