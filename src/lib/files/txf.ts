// SPDX-License-Identifier: GPL-3.0-only
/**
 * TXF (Tax Exchange Format) export — spec v042.
 *
 * TXF is the published interchange format supported by many desktop tax
 * packages (TurboTax among them). This exporter writes the V042 structure
 * from the published spec: a header (V version / A program / D export date)
 * followed by `^`-terminated summary records whose fields are
 * single-letter-tagged lines (T type, N refnum, C copy, L line, $ amount,
 * P description).
 *
 * Record codes from the spec's tax line item table:
 *   460 — Salary (W-2 box 1)          461 — Federal withholding (W-2 box 2)
 *   466 — Payer (W-2)                 287 — Interest income (Schedule B)
 *   636 — Student loan interest (1040)
 * Each W-2 is exported as its own copy (C1, C2, …) so receiving software
 * maps them back to separate W-2 forms; interest is one summary line.
 *
 * Sign convention per spec §VII.B: income is positive; expenses and tax
 * payments are negative — so withholding and the student-loan interest
 * deduction are written negative.
 *
 * Warnings shown in the UI:
 *  - Only W-2 wages/withholding/payers, interest and student-loan interest
 *    are exported (demo scope).
 *  - Verify the import in the receiving software.
 */

import type { TaxReturnData } from '../tax/engine'

function txfDate(): string {
  const d = new Date()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${mm}/${dd}/${d.getFullYear()}`
}

function money(value: number): string {
  const negative = value < 0
  const abs = Math.abs(value).toFixed(2)
  return `${negative ? '-' : ''}${abs}`
}

/** One summary record; amount null for text-only (format 2) records. */
function tsRecord(
  code: number,
  amount: number | null,
  opts: { copy?: number; line?: number; text?: string } = {},
): string[] {
  const out = [
    'TS',
    `N${code}`,
    `C${opts.copy ?? 1}`,
    `L${opts.line ?? 1}`,
  ]
  if (amount !== null) out.push(`$${money(amount)}`)
  if (opts.text) out.push(`P${opts.text}`)
  out.push('^')
  return out
}

export function exportTxf(f: TaxReturnData): string {
  const lines: string[] = [
    'V042',
    `A ClearFile ${f.taxYear} (web prototype)`,
    `D ${txfDate()}`,
    '^',
  ]
  f.w2s.forEach((w2, i) => {
    const copy = i + 1
    if (w2.employer.trim()) {
      lines.push(...tsRecord(466, null, { copy, text: w2.employer.trim() }))
    }
    lines.push(...tsRecord(460, w2.wages, { copy }))
    lines.push(...tsRecord(461, -w2.withholding, { copy }))
  })
  if (f.interestIncome > 0) {
    lines.push(...tsRecord(287, f.interestIncome, { text: 'Interest income' }))
  }
  if (f.studentLoanInterest > 0) {
    lines.push(...tsRecord(636, -f.studentLoanInterest))
  }
  return `${lines.join('\n')}\n`
}
