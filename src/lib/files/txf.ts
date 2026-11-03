/**
 * TXF (Tax Exchange Format) export — best-effort.
 *
 * TXF is the published interchange format supported by many desktop tax
 * packages. This exporter writes the classic V042 structure with the two
 * record codes relevant to ClearFile's demo scope:
 *   425 — W-2 wages, salaries, tips
 *   426 — Federal income tax withheld (W-2)
 * Amounts are aggregated across forms because TXF importers typically map
 * each record to one schedule line. Warnings shown in the UI:
 *  - Only wages and federal withholding are exported (demo scope).
 *  - Verify the import in the receiving software.
 */

import type { Computed, FilingData } from '../tax/engine'

function txfDate(): string {
  const d = new Date()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${mm}/${dd}/${d.getFullYear()}`
}

function record(code: number, description: string, amount: number): string[] {
  if (!amount || amount <= 0) return []
  return [
    `N ${code}`,
    `C ${description}`,
    `$ ${Math.round(amount)}`,
    '$',
    '^',
  ]
}

export function exportTxf(f: FilingData, c: Computed): string {
  const lines: string[] = [
    'V042',
    'A N 1',
    `D ${txfDate()}`,
    '^',
    ...record(425, 'W-2 wages, salaries, tips (all forms combined)', c.earnedIncome),
    ...record(426, 'Federal income tax withheld (all W-2s combined)', c.withholding),
    ...record(425, `Interest income (${f.taxYear})`, f.interest),
  ]
  return `${lines.join('\n')}\n`
}
