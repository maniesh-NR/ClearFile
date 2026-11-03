'use client'

import * as React from 'react'
import { Bot, Send, Loader2, Sparkles, ExternalLink, AlertTriangle, Info, CheckCircle2, Wand2, ClipboardType } from 'lucide-react'
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Checkbox } from '@/components/ui/checkbox'
import { useToast } from '@/hooks/use-toast'
import { useClearFile, filingFromStore } from '@/lib/store'
import { YEARS } from '@/lib/tax/config'
import { compute, type RuleCheck } from '@/lib/tax/engine'
import { runLadder, LadderError, ERROR_KIND_LABEL } from '@/lib/ai/ladder'
import {
  chatTurn,
  extractPrompt,
  parseExtracted,
  reviewPrompt,
  parseReview,
  type ChatTurn,
  type ExtractedForm,
  type AiReview,
} from '@/lib/ai/tasks'
import { cn } from '@/lib/utils'

/* ------------------------------------------------------------------ */
/* Shared: ladder error card                                           */
/* ------------------------------------------------------------------ */

export function LadderErrorCard({ error }: { error: LadderError }) {
  if (error.noKeys || error.attempts.length === 0) {
    return <KeyOnboardingCard />
  }
  const rateLimited = error.attempts.some((a) => a.errorKind === 'rate-limit')
  return (
    <div className="rounded-3xl border border-md-outline-variant bg-md-error-container/40 p-4 space-y-3">
      <div className="flex items-center gap-2 text-md-on-surface">
        <AlertTriangle className="size-4 text-md-error" aria-hidden />
        <p className="text-sm font-medium">No model on the ladder responded</p>
      </div>
      <ul className="space-y-1.5">
        {error.attempts
          .filter((a) => a.errorKind !== 'no-key')
          .map((a) => (
            <li key={a.model} className="flex items-center justify-between gap-2 text-xs">
              <span className="font-medium">{a.label}</span>
              <Badge variant="outline" className="rounded-full border-md-outline text-md-on-surface-variant font-normal">
                {a.errorKind ? ERROR_KIND_LABEL[a.errorKind] : 'Failed'}
              </Badge>
            </li>
          ))}
      </ul>
      <div className="space-y-1 text-xs text-md-on-surface-variant">
        {rateLimited && (
          <p>
            Free-tier rate limits were hit (20 requests/minute and a daily cap on OpenRouter; per-model limits on Google).
            The ladder will automatically try the next model down on your next request — just ask again in a minute.
          </p>
        )}
        {!rateLimited && <p>Check the key in Settings, or try again shortly.</p>}
      </div>
    </div>
  )
}

/* ------------------------------------------------------------------ */
/* Shared: key onboarding card                                         */
/* ------------------------------------------------------------------ */

export function KeyOnboardingCard() {
  const setSettingsOpen = useClearFile((s) => s.setSettingsOpen)
  return (
    <div className="rounded-3xl border border-md-outline-variant bg-md-surface-1 p-5 space-y-4">
      <div className="flex items-center gap-2">
        <Sparkles className="size-5 text-md-primary" aria-hidden />
        <h3 className="font-semibold">AI assistance is not connected yet</h3>
      </div>
      <p className="text-sm text-md-on-surface-variant">
        ClearFile&apos;s copilot, document auto-fill, and return review run on free keys you own. Get one from Google AI
        Studio (Gemini) or OpenRouter — both have free tiers. Keys stay in this browser; requests go directly from your
        browser to the provider.
      </p>
      <div className="flex flex-wrap gap-2">
        <Button onClick={() => setSettingsOpen(true)} className="rounded-full h-10">
          <Sparkles className="size-4" aria-hidden />
          Connect a free key
        </Button>
        <Button asChild variant="outline" className="rounded-full h-10">
          <a href="https://aistudio.google.com/apikey" target="_blank" rel="noreferrer">
            Google AI Studio <ExternalLink className="size-3.5" aria-hidden />
          </a>
        </Button>
        <Button asChild variant="outline" className="rounded-full h-10">
          <a href="https://openrouter.ai/settings/keys" target="_blank" rel="noreferrer">
            OpenRouter keys <ExternalLink className="size-3.5" aria-hidden />
          </a>
        </Button>
      </div>
    </div>
  )
}

/* ------------------------------------------------------------------ */
/* Copilot drawer                                                      */
/* ------------------------------------------------------------------ */

const SUGGESTIONS = [
  'Why is my refund lower than I expected?',
  'Standard or itemized — which should I use?',
  'What counts as a qualifying child?',
]

export function CopilotDrawer() {
  const open = useClearFile((s) => s.copilotOpen)
  const setOpen = useClearFile((s) => s.setCopilotOpen)
  const googleKey = useClearFile((s) => s.googleKey)
  const openrouterKey = useClearFile((s) => s.openrouterKey)
  const lastWorkingModel = useClearFile((s) => s.lastWorkingModel)

  const [messages, setMessages] = React.useState<ChatTurn[]>([])
  const [input, setInput] = React.useState('')
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState<LadderError | null>(null)
  const [meta, setMeta] = React.useState<{ label: string; ms: number } | null>(null)

  const hasKeys = Boolean(googleKey || openrouterKey)

  async function send(question?: string) {
    const q = (question ?? input).trim()
    if (!q || busy) return
    setInput('')
    setBusy(true)
    setError(null)
    setMessages((m) => [...m, { role: 'user', content: q }])
    try {
      const s = useClearFile.getState()
      const filing = filingFromStore(s)
      const computed = compute(filing, YEARS[filing.taxYear])
      const { system, user } = chatTurn(q, filing, computed, messages)
      const res = await runLadder(system, user, { googleKey, openrouterKey })
      setMessages((m) => [...m, { role: 'assistant', content: res.text }])
      setMeta({ label: res.label, ms: res.ms })
      useClearFile.getState().setLastWorkingModel(res.model)
    } catch (e) {
      setError(e instanceof LadderError ? e : new LadderError(String(e), []))
    } finally {
      setBusy(false)
    }
  }

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetContent side="right" className="w-full sm:max-w-md p-0 flex flex-col">
        <SheetHeader className="p-4 pb-3 border-b border-md-outline-variant/60">
          <SheetTitle className="flex items-center gap-2 text-base">
            <span className="flex size-8 items-center justify-center rounded-full bg-md-primary-container text-md-on-primary-container">
              <Bot className="size-4" aria-hidden />
            </span>
            ClearFile Copilot
          </SheetTitle>
          <SheetDescription className="flex items-center gap-2 text-xs">
            {hasKeys ? (
              lastWorkingModel ? (
                <span className="flex items-center gap-1.5">
                  <span className="size-1.5 rounded-full bg-md-success" aria-hidden /> Last answered by {lastWorkingModel}
                </span>
              ) : (
                <span className="flex items-center gap-1.5">
                  <span className="size-1.5 rounded-full bg-md-success" aria-hidden /> Connected — highest free model is tried first
                </span>
              )
            ) : (
              <span className="flex items-center gap-1.5">
                <span className="size-1.5 rounded-full bg-md-outline" aria-hidden /> Not connected
              </span>
            )}
          </SheetDescription>
        </SheetHeader>

        <ScrollArea className="flex-1 min-h-0">
          <div className="p-4 space-y-4">
            {messages.length === 0 && (
              <div className="space-y-3">
                <p className="text-sm text-md-on-surface-variant">
                  Ask anything about what you are seeing. The copilot knows your filing context (no names or SSNs —
                  ClearFile never collects them) and answers in plain language.
                </p>
                {!hasKeys && <KeyOnboardingCard />}
                {hasKeys && (
                  <div className="flex flex-wrap gap-2">
                    {SUGGESTIONS.map((s) => (
                      <button
                        key={s}
                        type="button"
                        onClick={() => send(s)}
                        className="rounded-full border border-md-outline-variant bg-md-surface-1 px-3 py-1.5 text-xs text-md-on-surface-variant hover:bg-md-surface-2 transition-colors"
                      >
                        {s}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}

            {messages.map((m, i) => (
              <div
                key={i}
                className={cn(
                  'max-w-[92%] rounded-3xl px-4 py-2.5 text-sm leading-relaxed whitespace-pre-wrap',
                  m.role === 'user'
                    ? 'ml-auto bg-md-primary text-md-on-primary rounded-br-lg'
                    : 'mr-auto bg-md-surface-2 text-md-on-surface rounded-bl-lg'
                )}
              >
                {m.content}
              </div>
            ))}

            {busy && (
              <div className="mr-auto flex items-center gap-2 text-sm text-md-on-surface-variant">
                <Loader2 className="size-4 animate-spin" aria-hidden /> Trying the ladder…
              </div>
            )}

            {error && <LadderErrorCard error={error} />}
          </div>
        </ScrollArea>

        <div className="border-t border-md-outline-variant/60 p-3 flex items-center gap-2">
          <Input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault()
                void send()
              }
            }}
            placeholder={hasKeys ? 'Ask about your return…' : 'Connect a key to chat…'}
            disabled={!hasKeys || busy}
            className="rounded-full h-11"
            aria-label="Message the copilot"
          />
          <Button
            onClick={() => void send()}
            disabled={!hasKeys || busy || !input.trim()}
            className="rounded-full h-11 w-11 p-0 shrink-0"
            aria-label="Send"
          >
            {busy ? <Loader2 className="size-4 animate-spin" aria-hidden /> : <Send className="size-4" aria-hidden />}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}

/* ------------------------------------------------------------------ */
/* W-2 / 1099 auto-fill (Income step)                                  */
/* ------------------------------------------------------------------ */

const AUTOFILL_SAMPLE = `W-2 Wage and Tax Statement (2026)
Employer: Acme Corp
Box 1 wages, tips: 52,500.00
Box 2 federal income tax withheld: 4,200.00

W-2 Wage and Tax Statement (2026)
Employer: Star Labs
Box 1 wages, tips: 18,000.00
Box 2 federal income tax withheld: 900.00

1099-INT
Payer: First National Bank
Interest income: 320.00`

export function AutofillPanel() {
  const addW2 = useClearFile((s) => s.addW2)
  const setIncomeField = useClearFile((s) => s.setIncomeField)
  const googleKey = useClearFile((s) => s.googleKey)
  const openrouterKey = useClearFile((s) => s.openrouterKey)
  const setSettingsOpen = useClearFile((s) => s.setSettingsOpen)
  const { toast } = useToast()

  const [raw, setRaw] = React.useState('')
  const [busy, setBusy] = React.useState(false)
  const [forms, setForms] = React.useState<ExtractedForm[] | null>(null)
  const [selected, setSelected] = React.useState<Record<number, boolean>>({})
  const [error, setError] = React.useState<LadderError | null>(null)

  const hasKeys = Boolean(googleKey || openrouterKey)

  async function extract() {
    if (!raw.trim() || busy) return
    setBusy(true)
    setError(null)
    setForms(null)
    try {
      const { system, user } = extractPrompt(raw)
      const res = await runLadder(system, user, { googleKey, openrouterKey }, { temperature: 0 })
      const parsed = parseExtracted(res.text)
      if (!parsed) {
        setError(new LadderError('The model did not return usable form data. Try pasting the text again.', []))
      } else {
        setForms(parsed)
        setSelected(Object.fromEntries(parsed.map((_, i) => [i, true])))
      }
      useClearFile.getState().setLastWorkingModel(res.model)
    } catch (e) {
      setError(e instanceof LadderError ? e : new LadderError(String(e), []))
    } finally {
      setBusy(false)
    }
  }

  function apply() {
    if (!forms) return
    const s = useClearFile.getState()
    let w2Count = 0
    let interest = 0
    let dividends = 0
    for (let i = 0; i < forms.length; i++) {
      if (!selected[i]) continue
      const f = forms[i]
      if (f.type === 'W-2') {
        addW2({ employer: f.employer, wages: f.wages ?? 0, federalWithheld: f.federalWithheld ?? 0 })
        w2Count++
      } else if (f.type === '1099-INT') {
        interest += f.interest ?? 0
      } else if (f.type === '1099-DIV') {
        dividends += f.dividends ?? 0
      }
    }
    if (interest) setIncomeField('interest', (s.interest || 0) + interest)
    if (dividends) setIncomeField('dividends', (s.dividends || 0) + dividends)
    toast({
      title: 'Forms applied',
      description: `${w2Count} W-2${w2Count === 1 ? '' : 's'} added${interest ? `, ${fmtMoney(interest)} interest` : ''}${dividends ? `, ${fmtMoney(dividends)} dividends` : ''}. Review the values below.`,
    })
    setForms(null)
    setRaw('')
  }

  return (
    <Card className="rounded-3xl border-md-outline-variant bg-md-surface-1/60">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Wand2 className="size-4 text-md-primary" aria-hidden /> Auto-fill from pasted forms
        </CardTitle>
        <CardDescription>
          Paste W-2 or 1099 text (or CSV rows). The AI reads it into structured fields — you review before anything is
          saved to your return.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {!hasKeys && (
          <div className="space-y-2">
            <p className="text-sm text-md-on-surface-variant">Auto-fill needs a free AI key (Google AI Studio or OpenRouter).</p>
            <Button variant="outline" className="rounded-full h-9" onClick={() => setSettingsOpen(true)}>
              <Sparkles className="size-4" aria-hidden /> Connect a key
            </Button>
          </div>
        )}
        {hasKeys && !forms && (
          <>
            <Textarea
              value={raw}
              onChange={(e) => setRaw(e.target.value)}
              placeholder="Paste form text here — e.g. Box 1 wages: 52,500.00 …"
              className="min-h-28 rounded-2xl font-mono text-xs scrollbar-slim"
              aria-label="Pasted tax form text"
            />
            <div className="flex flex-wrap gap-2">
              <Button onClick={() => void extract()} disabled={busy || !raw.trim()} className="rounded-full h-10">
                {busy ? <Loader2 className="size-4 animate-spin" aria-hidden /> : <Wand2 className="size-4" aria-hidden />}
                Extract with AI
              </Button>
              <Button variant="ghost" className="rounded-full h-10 text-md-on-surface-variant" onClick={() => setRaw(AUTOFILL_SAMPLE)}>
                <ClipboardType className="size-4" aria-hidden /> Use sample text
              </Button>
            </div>
          </>
        )}
        {forms && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Review before applying — nothing is saved yet.</p>
            <div className="space-y-1.5">
              {forms.map((f, i) => (
                <label
                  key={i}
                  className="flex items-center gap-3 rounded-2xl border border-md-outline-variant bg-md-surface p-3 cursor-pointer"
                >
                  <Checkbox
                    checked={selected[i] ?? true}
                    onCheckedChange={(v) => setSelected((s) => ({ ...s, [i]: v === true }))}
                  />
                  <span className="flex-1 text-sm">
                    <span className="font-medium">{f.type}</span>
                    <span className="text-md-on-surface-variant"> — {f.employer}</span>
                  </span>
                  <span className="text-xs text-md-on-surface-variant">
                    {[
                      f.wages != null && `wages ${fmtMoney(f.wages)}`,
                      f.federalWithheld != null && `withheld ${fmtMoney(f.federalWithheld)}`,
                      f.interest != null && `interest ${fmtMoney(f.interest)}`,
                      f.dividends != null && `dividends ${fmtMoney(f.dividends)}`,
                    ]
                      .filter(Boolean)
                      .join(' · ') || 'no amounts found'}
                  </span>
                </label>
              ))}
            </div>
            <div className="flex flex-wrap gap-2">
              <Button onClick={apply} className="rounded-full h-10">
                <CheckCircle2 className="size-4" aria-hidden /> Apply selected forms
              </Button>
              <Button variant="ghost" className="rounded-full h-10" onClick={() => setForms(null)}>
                Discard
              </Button>
            </div>
          </div>
        )}
        {error && <LadderErrorCard error={error} />}
      </CardContent>
    </Card>
  )
}

/* ------------------------------------------------------------------ */
/* AI review (Results step)                                            */
/* ------------------------------------------------------------------ */

export function ReviewPanel({ checks }: { checks: RuleCheck[] }) {
  const googleKey = useClearFile((s) => s.googleKey)
  const openrouterKey = useClearFile((s) => s.openrouterKey)
  const setSettingsOpen = useClearFile((s) => s.setSettingsOpen)

  const [review, setReview] = React.useState<AiReview | null>(null)
  const [busy, setBusy] = React.useState(false)
  const [error, setError] = React.useState<LadderError | null>(null)

  const hasKeys = Boolean(googleKey || openrouterKey)

  async function run() {
    if (busy) return
    setBusy(true)
    setError(null)
    try {
      const s = useClearFile.getState()
      const filing = filingFromStore(s)
      const computed = compute(filing, YEARS[filing.taxYear])
      const { system, user } = reviewPrompt(filing, computed, checks)
      const res = await runLadder(system, user, { googleKey, openrouterKey }, { temperature: 0.2, maxTokens: 1400 })
      setReview(parseReview(res.text) ?? { summary: res.text, findings: [] })
      useClearFile.getState().setLastWorkingModel(res.model)
    } catch (e) {
      setError(e instanceof LadderError ? e : new LadderError(String(e), []))
    } finally {
      setBusy(false)
    }
  }

  return (
    <Card className="rounded-3xl border-md-outline-variant">
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-base">
          <Sparkles className="size-4 text-md-primary" aria-hidden /> AI review before you finish
        </CardTitle>
        <CardDescription>
          A second look at your whole return: likely mistakes, credits worth checking, and a plain-language summary.
          Local rule checks below always run — AI adds the narrative.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {!review && !error && (
          <div className="flex flex-wrap gap-2">
            <Button onClick={() => void run()} disabled={busy || !hasKeys} className="rounded-full h-10">
              {busy ? <Loader2 className="size-4 animate-spin" aria-hidden /> : <Sparkles className="size-4" aria-hidden />}
              Run AI review
            </Button>
            {!hasKeys && (
              <Button variant="outline" className="rounded-full h-10" onClick={() => setSettingsOpen(true)}>
                Connect a free key first
              </Button>
            )}
          </div>
        )}
        {review && (
          <div className="space-y-3">
            <p className="text-sm leading-relaxed">{review.summary}</p>
            {review.findings.length > 0 && (
              <ul className="space-y-2">
                {review.findings.map((f, i) => (
                  <li key={i} className="flex gap-2.5 rounded-2xl bg-md-surface-1 p-3 text-sm">
                    {f.severity === 'warn' ? (
                      <AlertTriangle className="size-4 shrink-0 text-md-error" aria-hidden />
                    ) : f.severity === 'positive' ? (
                      <CheckCircle2 className="size-4 shrink-0 text-md-success" aria-hidden />
                    ) : (
                      <Info className="size-4 shrink-0 text-md-primary" aria-hidden />
                    )}
                    <span>
                      <span className="font-medium">{f.title}</span>
                      {f.detail && <span className="block text-md-on-surface-variant">{f.detail}</span>}
                    </span>
                  </li>
                ))}
              </ul>
            )}
            <p className="text-xs text-md-on-surface-variant">
              AI-generated — verify anything you rely on. Not tax advice.
            </p>
            <Button variant="ghost" size="sm" className="rounded-full text-md-on-surface-variant" onClick={() => setReview(null)}>
              Run again
            </Button>
          </div>
        )}
        {error && <LadderErrorCard error={error} />}
      </CardContent>
    </Card>
  )
}

function fmtMoney(n: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n)
}
