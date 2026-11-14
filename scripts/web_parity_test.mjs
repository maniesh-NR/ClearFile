#!/usr/bin/env node
// SPDX-License-Identifier: GPL-3.0-only
/**
 * Stage-3 web-parity suite (ADR-009): runs the TypeScript web engine
 * (`src/lib/tax/engine.ts`) against the SAME shared golden fixtures the
 * Flutter suite runs (`fixtures/tax/*.json`) — every `expected` key within
 * the fixture's `tolerance`, `deductionMethodUsed` as an exact enum name.
 *
 * The fixtures are IRS-pinned and engine-agnostic (authoring discipline in
 * fixtures/tax/README.md: never derive an expected value by running
 * either engine). A failure here is a finding about the web engine — fix
 * it against the form, not the fixture.
 *
 * This script compiles the engine first:
 *   npx tsc -p scripts/tsconfig.parity.json   (emits to .parity-build/, gitignored)
 *
 * Usage:  node scripts/web_parity_test.mjs        (from the repo root)
 * Exit code 0 = every fixture checks out.
 */

import { execFileSync } from 'node:child_process'
import { readdirSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '..')

// --- compile the engine (idempotent; tsc overwrites the outDir) ----------
execFileSync('npx', ['tsc', '-p', 'scripts/tsconfig.parity.json'], {
  cwd: root,
  stdio: 'inherit',
})

const { compute } = await import(path.join(root, '.parity-build', 'engine.js'))
const { TY2025 } = await import(path.join(root, '.parity-build', 'config.js'))

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
  console.error(`web_parity_test: no fixtures found in ${fixturesDir}`)
  process.exit(2)
}

let failures = 0
for (const file of files) {
  const fixture = JSON.parse(readFileSync(path.join(fixturesDir, file), 'utf8'))
  const name = fixture.name ?? file
  const tolerance = Number(fixture.tolerance ?? 0.005)
  const input = { ...DEFAULT_INPUT, ...fixture.input }
  const result = compute(input, TY2025)

  let fixtureFailures = 0
  for (const [key, pinned] of Object.entries(fixture.expected)) {
    if (key === 'deductionMethodUsed') {
      if (result[key] !== pinned) {
        console.error(
          `FAIL ${name}: ${key} web=${String(result[key])} pinned=${String(pinned)}`
        )
        fixtureFailures++
      }
      continue
    }
    const delta = Math.abs(Number(result[key]) - Number(pinned))
    if (!(delta <= tolerance)) {
      console.error(
        `FAIL ${name}: ${key} web=${String(result[key])} pinned=${String(pinned)} delta=${delta.toFixed(4)} tol=${tolerance}`
      )
      fixtureFailures++
    }
  }
  failures += fixtureFailures
  const status = fixtureFailures === 0 ? 'ok  ' : 'FAIL'
  console.log(`${status} ${name} (${Object.keys(fixture.expected).length} fields checked)`)
}

console.log(`\n${files.length} fixtures, ${failures} field failures (web engine)`)
process.exit(failures === 0 ? 0 : 1)
