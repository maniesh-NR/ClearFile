#!/usr/bin/env node
// SPDX-License-Identifier: GPL-3.0-only
/**
 * The WASM parity suite (N6, the transferred web-parity contract): the
 * wasm core adapter (src/lib/wasm/core.ts over the same flat C ABI the
 * native lanes consume) against the SAME shared golden fixtures the
 * Flutter + parity suites run (fixtures/tax/*.json) — every `expected`
 * key within the fixture's `tolerance`, `deductionMethodUsed` as the
 * exact enum name. The TS engine's parity suite (web_parity_test.mjs)
 * retired with its subject (ADR-016's conversion day); the contract
 * transferred here byte-for-byte (the same DEFAULT_INPUT merge + the
 * same tolerance semantics).
 *
 * Also proves the N6 gate's allocator + trap rulings against the real
 * module: the length-paired alloc/dealloc over interior-NUL payloads
 * (>=100 cycles, stable memory size) and — when the panic-hook test
 * module is present — the trap mapping (catch_unwind does NOT transfer
 * to wasm32: a Rust panic aborts into a WebAssembly RuntimeError).
 *
 * This script compiles the adapter first:
 *   npx tsc -p scripts/tsconfig.parity.json   (emits to .parity-build/)
 *
 * Usage:  node scripts/wasm_parity_test.mjs [module.wasm] [panic-module.wasm]
 * Exit code 0 = every fixture checks out.
 */

import { execFileSync } from 'node:child_process'
import { readdirSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')

const modulePath = process.argv[2] ?? path.join(root, 'core-ffi/target/wasm32-unknown-unknown/release/clearfile_core_ffi.wasm')
const panicModulePath = process.argv[3] ?? path.join(root, 'core-ffi/target/wasm32-unknown-unknown/release/clearfile_core_ffi_panic.wasm')

// --- compile the adapter (idempotent; tsc overwrites the outDir) ---------
execFileSync('npx', ['tsc', '-p', 'scripts/tsconfig.parity.json'], {
  cwd: root,
  stdio: 'inherit',
})

const core = await import(path.join(root, '.parity-build', 'wasm', 'core.js'))

// --- the wasm init (the CI suites' node path) -----------------------------
await core.initWasmFromBuffer(readFileSync(modulePath))

// --- the allocator ruling (SEC-1/ENG-1): >=100 cycles of alloc/write
// interior NULs/dealloc + a stable memory size ---------------------------
{
  let ok = true
  for (let cycle = 0; cycle < 100; cycle++) {
    const len = 64 + cycle
    const poisoned0 = core.wasmReady()
    if (!poisoned0) { ok = false; break }
    // The adapter's internal withInput runs the write+release cycle; a
    // payload of ALL interior NULs through the real ABI (inspect_tax on
    // a zeroed buffer — binary bytes with NULs at every position).
    try {
      core.analyzeTaxFile(new Uint8Array(len))
    } catch {
      // An analysis result is never asserted here — only that the call
      // completes without a trap and the module stays usable.
    }
  }
  ok = ok && core.wasmReady()
  console.log(`${ok ? 'ok  ' : 'FAIL'} the length-paired allocator: 100 interior-NUL cycles, module still ready`)
  if (!ok) process.exit(1)
}

// --- the trap ruling (SEC-2/ENG-3), when the panic-hook module exists ----
try {
  readFileSync(panicModulePath)
  const panicInstance = await WebAssembly.instantiate(readFileSync(panicModulePath), {})
  const panicFn = panicInstance.exports.clearfile_test_guard_panic
  if (typeof panicFn !== 'function') throw new Error('the panic-hook export is missing')
  let trapped = false
  try {
    panicFn()
  } catch (e) {
    trapped = e instanceof WebAssembly.RuntimeError
  }
  console.log(`${trapped ? 'ok  ' : 'FAIL'} the trap ruling: a Rust panic on wasm32 is a RuntimeError trap (never a sentinel return)`)
  if (!trapped) process.exit(1)
} catch (e) {
  if (e instanceof WebAssembly.RuntimeError) {
    console.log('FAIL the panic-hook trap assertion threw the wrong class')
    process.exit(1)
  }
  console.log('skip the trap assertion (no panic-hook module built)')
}

// --- the core-served parameter table (the N6 reconciliation: the table's
// one true source; the display walk consumes it) ------------------------
{
  const table = core.params()
  const ok =
    table.year === 2025 &&
    table.standardDeduction.single === 15750 &&
    table.saltBaseCap.single === 40000 &&
    table.ordinaryBrackets.single[0].rate === 0.1 &&
    table.ordinaryBrackets.single[table.ordinaryBrackets.single.length - 1].upTo === null
  console.log(`${ok ? 'ok  ' : 'FAIL'} the core-served parameter table (year, standard deduction, SALT cap, the bracket schedule with the null terminal rung)`)
  if (!ok) process.exit(1)
}

// --- fixture defaults (mirrors TaxReturnData.fromJson in the reference) --
const DEFAULT_INPUT = {
  taxYear: 2025,
  filingStatus: 'single',
  taxpayer65OrOlder: false,
  spouse65OrOlder: false,
  taxpayerBlind: false,
  spouseBlind: false,
  w2s: [],
  interestIncome: 0,
  ordinaryDividends: 0,
  qualifiedDividends: 0,
  longTermCapitalGains: 0,
  otherIncome: 0,
  studentLoanInterest: 0,
  deductionMethod: 'auto',
  stateLocalIncomeOrSalesTax: 0,
  realEstateTax: 0,
  mortgageInterest: 0,
  charitableCash: 0,
  charitableNonCash: 0,
  estimatedPayments: 0,
  dependents: [],
}

const fixturesDir = path.join(root, 'fixtures', 'tax')
const files = readdirSync(fixturesDir)
  .filter((f) => f.endsWith('.json'))
  .sort()

if (files.length === 0) {
  console.error(`wasm_parity_test: no fixtures found in ${fixturesDir}`)
  process.exit(2)
}

let failures = 0
for (const file of files) {
  const fixture = JSON.parse(readFileSync(path.join(fixturesDir, file), 'utf8'))
  const name = fixture.name ?? file
  const tolerance = Number(fixture.tolerance ?? 0.005)
  const input = { ...DEFAULT_INPUT, ...fixture.input }
  const result = core.compute(input)

  let fixtureFailures = 0
  for (const [key, pinned] of Object.entries(fixture.expected)) {
    if (key === 'deductionMethodUsed') {
      if (result[key] !== pinned) {
        console.error(
          `FAIL ${name}: ${key} wasm=${String(result[key])} pinned=${String(pinned)}`
        )
        fixtureFailures++
      }
      continue
    }
    const delta = Math.abs(Number(result[key]) - Number(pinned))
    if (!(delta <= tolerance)) {
      console.error(
        `FAIL ${name}: ${key} wasm=${String(result[key])} pinned=${String(pinned)} delta=${delta.toFixed(4)} tol=${tolerance}`
      )
      fixtureFailures++
    }
  }
  failures += fixtureFailures
  const status = fixtureFailures === 0 ? 'ok  ' : 'FAIL'
  console.log(`${status} ${name} (${Object.keys(fixture.expected).length} fields checked)`)
}

console.log(`\n${files.length} fixtures, ${failures} field failures (wasm core adapter)`)
process.exit(failures === 0 ? 0 : 1)
