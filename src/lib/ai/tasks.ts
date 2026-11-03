/**
 * ClearFile AI — task prompts and response parsing.
 *
 * Privacy rules baked into every prompt:
 *  - ClearFile never collects names, SSNs, or addresses; the context sent to
 *    models is limited to the summary below.
 *  - Models are instructed to answer in plain language, avoid inventing
 *    numbers, and point back to the app for calculations.
 */

import type { Computed, FilingData } from '../tax/engine'
import { usd } from '../tax/config'

const DISCLAIMER = 'ClearFile is a prototype demo, not licensed tax advice or filing software.'

export function filingSummary(f: FilingData, c: Computed): string {
  const lines = [
    `Tax year: ${f.taxYear}`,
    `Filing status: ${f.status}`,
    `W-2 forms: ${f.w2s.length}` +
      (f.w2s.length
        ? ` (wages ${usd(c.earnedIncome)}, federal withholding ${usd(c.withholding)})`
        : ''),
    `Interest income: ${usd(f.interest)}`,
    `Dividend income (ordinary): ${usd(f.dividends)}`,
    `Other income: ${usd(f.otherIncome)}`,
    `Adjustments to income: ${usd(f.adjustments)}`,
    `Deduction used: ${c.deductionChoice} (${usd(c.deduction)})`,
    `Qualifying children under 17: ${f.qualifyingChildren}`,
    `Other dependents: ${f.otherDependents}`,
    `Estimated payments: ${usd(f.estimatedPayments)}`,
    `Computed: total income ${usd(c.totalIncome)}, AGI ${usd(c.agi)}, taxable income ${usd(c.taxableIncome)}, tax before credits ${usd(c.taxBeforeCredits)}, CTC applied ${usd(c.ctcApplied)}, refundable CTC ${usd(c.actc)}, total tax ${usd(c.totalTax)}, projected ${c.isRefund ? 'refund' : 'balance due'} ${usd(Math.abs(c.balance))}`,
  ]
  return lines.join('\n')
}

export interface ChatTurn {
  role: 'user' | 'assistant'
  content: string
}

const CHAT_SYSTEM = `You are the ClearFile Copilot, an assistant inside a clean-room, open tax-filing prototype. ${DISCLAIMER}
Rules:
- Answer in plain language a first-time filer understands; define jargon in one clause when you must use it.
- Be concise: under 180 words unless the user asks for more.
- Use ONLY the numbers in the provided filing context for anything quantitative; never invent thresholds, rates, or amounts. If the answer depends on rules outside the context (state taxes, credits this demo does not model), say so and suggest checking IRS.gov.
- You explain concepts and help the user decide what to enter; the app does the math.`

export function chatTurn(question: string, f: FilingData, c: Computed, history: ChatTurn[]): { system: string; user: string } {
  const convo = history
    .slice(-6)
    .map((t) => `${t.role === 'user' ? 'User' : 'Assistant'}: ${t.content}`)
    .join('\n')
  const user = [
    'Filing context (the only data you have about this user):',
    filingSummary(f, c),
    '',
    convo ? `Recent conversation:\n${convo}` : '',
    '',
    `User's new question: ${question}`,
  ]
    .filter(Boolean)
    .join('\n')
  return { system: CHAT_SYSTEM, user }
}

export interface ExtractedForm {
  type: 'W-2' | '1099-INT' | '1099-DIV' | '1099-NEC' | 'OTHER'
  employer: string
  wages?: number
  federalWithheld?: number
  interest?: number
  dividends?: number
}

const EXTRACT_SYSTEM = `You convert pasted tax form text (W-2, 1099-INT, 1099-DIV, 1099-NEC, or CSV) into structured data for the ClearFile tax prototype.
Respond with ONLY a JSON object, no prose, no code fences:
{"forms":[{"type":"W-2|1099-INT|1099-DIV|1099-NEC|OTHER","employer":string,"wages":number|null,"federalWithheld":number|null,"interest":number|null,"dividends":number|null}]}
Rules:
- Include every distinct form found. employer is the paying company; use "Unknown" when not present.
- Amounts are plain numbers (no $ or commas). Use null when the field is absent.
- Never guess or average numbers. Only transcribe values that literally appear in the text.`

export function extractPrompt(raw: string): { system: string; user: string } {
  return {
    system: EXTRACT_SYSTEM,
    user: `Transcribe the tax form data in the text below.\n\n---BEGIN FORMS---\n${raw.slice(0, 8000)}\n---END FORMS---`,
  }
}

export function parseExtracted(text: string): ExtractedForm[] | null {
  const json = extractJson(text)
  if (!json) return null
  const forms = (json as { forms?: unknown }).forms
  if (!Array.isArray(forms)) return null
  const out: ExtractedForm[] = []
  for (const raw of forms) {
    if (!raw || typeof raw !== 'object') continue
    const f = raw as Record<string, unknown>
    const type = String(f.type ?? 'OTHER').toUpperCase()
    const num = (v: unknown): number | undefined =>
      typeof v === 'number' && Number.isFinite(v) ? v : undefined
    out.push({
      type: (['W-2', '1099-INT', '1099-DIV', '1099-NEC'].includes(type) ? type : 'OTHER') as ExtractedForm['type'],
      employer: typeof f.employer === 'string' && f.employer.trim() ? f.employer.trim() : 'Unknown',
      wages: num(f.wages),
      federalWithheld: num(f.federalWithheld),
      interest: num(f.interest),
      dividends: num(f.dividends),
    })
  }
  return out.length ? out : null
}

export interface ReviewFinding {
  severity: 'info' | 'warn' | 'positive'
  title: string
  detail: string
}

export interface AiReview {
  summary: string
  findings: ReviewFinding[]
}

const REVIEW_SYSTEM = `You are the pre-submit reviewer inside the ClearFile tax prototype. ${DISCLAIMER}
You receive a plain summary of a simplified federal return plus rule-based checks the app already ran.
Respond with ONLY a JSON object, no prose, no code fences:
{"summary":string,"findings":[{"severity":"info|warn|positive","title":string,"detail":string}]}
Rules:
- "summary" explains the whole return in 3-4 plain-language sentences (what drives the result, what the number means).
- 2-5 findings. Mark anything that looks like a probable entry mistake or eligibility question as "warn"; things done well as "positive"; neutral observations as "info".
- Use only the numbers provided. For credits this demo does not model (EITC, education credits, saver's credit), phrase findings as questions to consider, not amounts.
- Never recommend specific dollar adjustments you cannot derive from the provided data.`

export function reviewPrompt(f: FilingData, c: Computed, localChecks: { title: string; detail: string; severity: string }[]): { system: string; user: string } {
  return {
    system: REVIEW_SYSTEM,
    user: [
      filingSummary(f, c),
      '',
      'Checks the app already flagged locally:',
      localChecks.length ? localChecks.map((ch) => `- [${ch.severity}] ${ch.title}: ${ch.detail}`).join('\n') : '- none',
    ].join('\n'),
  }
}

export function parseReview(text: string): AiReview | null {
  const json = extractJson(text)
  if (!json) return null
  const obj = json as { summary?: unknown; findings?: unknown }
  if (typeof obj.summary !== 'string') return null
  const findings: ReviewFinding[] = Array.isArray(obj.findings)
    ? obj.findings
        .filter((x): x is Record<string, unknown> => !!x && typeof x === 'object')
        .map((x) => ({
          severity: (['info', 'warn', 'positive'].includes(String(x.severity)) ? String(x.severity) : 'info') as ReviewFinding['severity'],
          title: typeof x.title === 'string' ? x.title : 'Observation',
          detail: typeof x.detail === 'string' ? x.detail : '',
        }))
    : []
  return { summary: obj.summary, findings }
}

function extractJson(text: string): unknown | null {
  const stripped = text.replace(/```json/gi, '```').replace(/```/g, '').trim()
  const start = stripped.indexOf('{')
  const end = stripped.lastIndexOf('}')
  if (start === -1 || end === -1 || end <= start) return null
  try {
    return JSON.parse(stripped.slice(start, end + 1))
  } catch {
    return null
  }
}
