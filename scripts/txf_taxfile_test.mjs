#!/usr/bin/env node
// SPDX-License-Identifier: GPL-3.0-only
/**
 * Stage-3 bridge suite (web side): the TXF exporter verification suite
 * plus the .tax container-analysis tests.
 *
 * 1. TXF exporter verification — `exportTxf()` is asserted against the
 *    published Tax Exchange Format spec v042 record structure:
 *    header (V/A/D + '^'), summary records whose fields are single-letter
 *    tagged lines (T/N/C/L/$/P), refnums 460/461/466/287/636 from the
 *    spec's tax line item table, and the sign convention (income
 *    positive, expenses/payments negative). A tiny in-test importer then
 *    reads the exported records back — an exporter whose output a
 *    spec-shaped importer cannot read is a bug, not a style choice.
 * 2. `.tax` analysis — `analyzeTaxFile()` on synthetic containers built
 *    with the app's own `makeZip()`: the ClearFile exchange container
 *    round-trip, the modern Intuit container shape (manifest.xml +
 *    tax:<uuid>) flagged encrypted-and-not-decrypted, and the
 *    non-ZIP/empty honest paths.
 * 3. Unified ClearFile return format (ADR-015) — `serializeCfr`/`parseCfr`
 *    round-trip, the legacy flat layout (`clearfile.return`) the Flutter
 *    app wrote through v1.0.1 accepted and lifted, the version guard
 *    refusing future files (D3), and the v1 (pre-parity web) envelope
 *    migration with its warnings.
 *
 * This script compiles the file modules first:
 *   npx tsc -p scripts/tsconfig.files.json  (emits to .files-build/, gitignored)
 *
 * Usage:  node scripts/txf_taxfile_test.mjs    (from the repo root)
 * Exit code 0 = every check passes.
 */

import { execFileSync } from 'node:child_process'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import assert from 'node:assert/strict'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')
const require = createRequire(import.meta.url)

// --- compile the file modules (idempotent; tsc overwrites the outDir) ---
// CommonJS emit so Node can resolve the extensionless intra-module imports.
execFileSync('npx', ['tsc', '-p', 'scripts/tsconfig.files.json'], {
  cwd: root,
  stdio: 'inherit',
})

const { exportTxf } = require(path.join(root, '.files-build', 'files', 'txf.js'))
const { analyzeTaxFile, makeZip } = require(
  path.join(root, '.files-build', 'files', 'taxfile.js'),
)
const { serializeCfr, parseCfr, CfrParseError } = require(path.join(root, '.files-build', 'files', 'cfr.js'))

const enc = new TextEncoder()
let passed = 0

/* ---------------- tiny spec-shaped TXF reader (verification mirror) ---- */

function readTxf(text) {
  const records = []
  const lines = text.split('\n').map((l) => l.replace('\r', ''))
  let current = null
  let inHeader = true
  for (const line of lines) {
    if (line.trim() === '^') {
      if (inHeader) inHeader = false
      if (current) records.push(current)
      current = null
      continue
    }
    if (!line.trim()) continue
    if (inHeader) continue
    current = current ?? { amounts: [] }
    const tag = line[0]
    const value = line.substring(1).trim()
    if (tag === 'T') current.type = value
    if (tag === 'N') current.refnum = Number(value)
    if (tag === 'C') current.copy = Number(value)
    if (tag === 'L') current.line = Number(value)
    if (tag === 'P') current.text = value
    if (tag === '$' && value !== '') current.amounts.push(Number(value.replace(/[$,]/g, '')))
  }
  return records
}

/* ---------------- 1. exporter verification ------------------------------ */

{
  const filing = {
    taxYear: 2025,
    w2s: [
      { employer: 'Acme Corp', wages: 52500.5, withholding: 6200 },
      { employer: 'Beta School District', wages: 38200, withholding: 3410.5 },
      { employer: '  ', wages: 1000, withholding: 0 }, // blank employer: no 466
    ],
    interestIncome: 120.25,
    studentLoanInterest: 900,
  }
  const out = exportTxf(filing)
  const lines = out.split('\n')

  // header per spec §VIII
  assert.equal(lines[0], 'V042')
  assert.ok(lines[1].startsWith('A ClearFile 2025'), 'A program line')
  assert.match(lines[2], /^D \d{2}\/\d{2}\/\d{4}$/, 'D export date')
  assert.equal(lines[3], '^')

  const records = readTxf(out)
  assert.ok(records.every((r) => r.type === 'S'), 'summary records only')
  assert.ok(records.every((r) => r.refnum > 0), 'every record has an N refnum')

  // W-2 copies: 466 payer (format 2, no $), 460 salary, 461 withholding
  const payers = records.filter((r) => r.refnum === 466)
  assert.equal(payers.length, 2) // the blank employer emits none
  assert.equal(payers[0].text, 'Acme Corp')
  assert.equal(payers[0].copy, 1)
  assert.equal(payers[1].text, 'Beta School District')
  assert.equal(payers[1].copy, 2)
  assert.ok(payers.every((r) => r.amounts.length === 0), 'payer records carry text only')

  const salaries = records.filter((r) => r.refnum === 460)
  assert.deepEqual(salaries.map((r) => r.copy), [1, 2, 3])
  assert.equal(salaries[0].amounts[0], 52500.5)

  // spec sign convention: money paid is negative (zero stays plain zero)
  const withholdings = records.filter((r) => r.refnum === 461)
  assert.deepEqual(withholdings.map((r) => r.amounts[0]), [-6200, -3410.5, 0])

  // interest + student loan
  const interest = records.find((r) => r.refnum === 287)
  assert.equal(interest.amounts[0], 120.25)
  const sli = records.find((r) => r.refnum === 636)
  assert.equal(sli.amounts[0], -900)

  // C defaults are explicit and L lines are 1
  assert.ok(records.every((r) => r.copy >= 1 && r.line === 1))

  assert.ok(out.endsWith('\n'), 'trailing newline')
  passed += 1
  console.log('[txf] exporter verified against spec v042 structure: OK')
}

{
  // Empty return: header only, still a valid TXF file.
  const out = exportTxf({
    taxYear: 2025,
    w2s: [],
    interestIncome: 0,
    studentLoanInterest: 0,
  })
  const records = readTxf(out)
  assert.equal(records.length, 0)
  assert.equal(out.split('\n')[0], 'V042')
  passed += 1
  console.log('[txf] empty-return edge: header-only file: OK')
}

/* ---------------- 2. .tax analysis -------------------------------------- */

{
  // ClearFile exchange container: makeZip + serializeCfr round-trip.
  const filing = {
    taxYear: 2025,
    w2s: [{ employer: 'Acme Corp', wages: 52500, withholding: 6200 }],
    interestIncome: 120,
  }
  const bytes = makeZip([
    { name: 'clearfile.json', data: enc.encode(serializeCfr(filing)) },
    { name: 'README.txt', data: enc.encode('ClearFile exchange container') },
  ])
  const a = analyzeTaxFile(bytes)
  assert.equal(a.isZip, true)
  assert.equal(a.clearfileContainer, true)
  assert.equal(a.intuitModernContainer, false)
  assert.equal(a.filing.interestIncome, 120)
  assert.equal(a.entries.length, 2)
  passed += 1
  console.log('[tax] ClearFile exchange container round-trip: OK')
}

{
  // Modern Intuit container shape: manifest.xml + tax:<uuid>, high-entropy
  // synthetic payload. Detected, flagged, never decrypted.
  const payload = new Uint8Array(1024)
  let seed = 123456789
  for (let i = 0; i < payload.length; i++) {
    // xorshift32 — deterministic uniform-looking bytes for the fixture
    seed ^= seed << 13
    seed ^= seed >>> 17
    seed ^= seed << 5
    payload[i] = seed & 0xff
  }
  const bytes = makeZip([
    { name: 'manifest.xml', data: enc.encode('<manifest/>') },
    { name: 'tax:7a1c2d3e-4f5a-6789-abcd-ef0123456789', data: payload },
  ])
  const a = analyzeTaxFile(bytes)
  assert.equal(a.isZip, true)
  assert.equal(a.intuitModernContainer, true)
  assert.equal(a.clearfileContainer, false)
  assert.equal(a.filing, undefined)
  const data = a.entries.find((e) => e.name.startsWith('tax:'))
  assert.ok(data.entropy > 7.5, `entropy ${data.entropy}`)
  assert.equal(data.likelyEncrypted, true)
  assert.ok(a.summary.includes('does not decrypt'))
  assert.ok(a.summary.includes('TXF'))
  passed += 1
  console.log('[tax] Intuit container shape detected + flagged encrypted: OK')
}

{
  // Low-entropy textual entry: preview, no encryption flag.
  const bytes = makeZip([
    {
      name: 'notes.txt',
      data: enc.encode('hello '.repeat(64)),
    },
  ])
  const a = analyzeTaxFile(bytes)
  const e = a.entries[0]
  assert.equal(e.likelyEncrypted, false)
  assert.ok(e.preview.startsWith('hello'))
  passed += 1
  console.log('[tax] low-entropy textual entry: OK')
}

{
  // Non-ZIP + empty honest paths.
  const a = analyzeTaxFile(enc.encode('just some text'))
  assert.equal(a.isZip, false)
  assert.ok(a.summary.includes('not high-entropy'))
  const b = analyzeTaxFile(new Uint8Array(0))
  assert.equal(b.summary, 'The file is empty.')
  passed += 1
  console.log('[tax] non-ZIP and empty honest paths: OK')
}

/* ---------------- 3. unified return format (ADR-015) -------------------- */

{
  // Envelope round-trip: what the app writes, the app reads back.
  const filing = {
    taxYear: 2025,
    filingStatus: 'marriedJoint',
    w2s: [{ employer: 'Acme Corp', wages: 52500.5, withholding: 6200 }],
    interestIncome: 120.25,
    qualifiedDividends: 400,
    studentLoanInterest: 900,
  }
  const text = serializeCfr(filing)
  const envelope = JSON.parse(text)
  assert.equal(envelope.format, 'clearfile-return')
  assert.equal(envelope.version, 2)
  const { filing: back, warnings } = parseCfr(text)
  assert.deepEqual(warnings, [])
  assert.equal(back.filingStatus, 'marriedJoint')
  assert.equal(back.w2s[0].wages, 52500.5)
  assert.equal(back.interestIncome, 120.25)
  assert.equal(back.qualifiedDividends, 400)
  assert.equal(back.studentLoanInterest, 900)
  passed += 1
  console.log('[cfr] envelope v2 round-trip: OK')
}

{
  // Legacy flat layout (Flutter app <= v1.0.1): fields at the top level
  // beside the marker — accepted, lifted, metadata honestly noted.
  const flat = JSON.stringify({
    format: 'clearfile.return',
    formatVersion: 1,
    displayName: 'From the Flutter app',
    id: 'abc123',
    taxYear: 2025,
    filingStatus: 'single',
    interestIncome: 42,
    w2s: [{ employer: 'Initech', wages: 60000, withholding: 6000 }],
    dependents: [{ name: 'Kid', age: 8, relationship: 'daughter', qualifyingChild: true, otherDependentCredit: false }],
  })
  const { filing, warnings } = parseCfr(flat)
  assert.equal(filing.interestIncome, 42)
  assert.equal(filing.w2s[0].employer, 'Initech')
  assert.equal(filing.dependents.length, 1)
  assert.ok(warnings.some((w) => w.includes('not carried by the web prototype')))
  // flat guard: a future formatVersion is refused, not guessed at (D3)
  assert.throws(
    () => parseCfr(JSON.stringify({ format: 'clearfile.return', formatVersion: 7 })),
    (e) => e instanceof CfrParseError && e.message.includes('Unsupported version 7'),
  )
  passed += 1
  console.log('[cfr] legacy flat layout accepted + guarded: OK')
}

{
  // Version guard: future envelopes are refused with a readable error.
  assert.throws(
    () => parseCfr(JSON.stringify({ format: 'clearfile-return', version: 3, filing: {} })),
    (e) => e instanceof CfrParseError && e.message.includes('Unsupported version 3'),
  )
  assert.throws(
    () => parseCfr('not json at all'),
    (e) => e instanceof CfrParseError && e.message.includes('not valid JSON'),
  )
  assert.throws(
    () => parseCfr(JSON.stringify({ hello: 'world' })),
    (e) => e instanceof CfrParseError && e.message.includes('Unrecognized format'),
  )
  passed += 1
  console.log('[cfr] version guard + honest failures: OK')
}

{
  // v1 (pre-parity web) envelope: conservative migration + warnings.
  const v1 = JSON.stringify({
    format: 'clearfile-return',
    version: 1,
    app: 'ClearFile prototype 0.1',
    savedAt: '2026-11-03T00:00:00.000Z',
    filing: {
      status: 'mfj',
      taxYear: 2026,
      interest: 500,
      dividends: 300,
      adjustments: 120,
      itemized: { taxesPaid: 8000, mortgageInterest: 9000, charity: 1000, medical: 200, other: 50 },
      qualifyingChildren: 2,
      otherDependents: 1,
      w2s: [{ employer: 'Acme', wages: 90000, withholding: 9000 }],
    },
  })
  const { filing, warnings } = parseCfr(v1)
  assert.equal(filing.filingStatus, 'marriedJoint')
  assert.equal(filing.taxYear, 2025)
  assert.equal(filing.interestIncome, 500)
  assert.equal(filing.ordinaryDividends, 300)
  assert.equal(filing.stateLocalIncomeOrSalesTax, 8000)
  assert.equal(filing.mortgageInterest, 9000)
  assert.equal(filing.charitableCash, 1000)
  assert.equal(filing.dependents.length, 3)
  assert.equal(filing.dependents.filter((d) => d.qualifyingChild).length, 2)
  assert.ok(warnings.some((w) => w.includes('older prototype')))
  assert.ok(warnings.some((w) => w.includes('Adjustments to income')))
  assert.ok(warnings.some((w) => w.includes('Medical and "other"')))
  assert.ok(warnings.some((w) => w.includes('Dependent counts')))
  passed += 1
  console.log('[cfr] v1 envelope migrated with warnings: OK')
}

console.log(`\n[txf_taxfile] ${passed}/10 groups passed`)
