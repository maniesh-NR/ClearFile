'use client'

import * as React from 'react'
import {
  Plus, Minus, Trash2, Printer, Save, FileDown, Archive, ShieldCheck,
  FileCheck2, ArrowRight, TriangleAlert, Info, Sparkles, BadgeCheck,
} from 'lucide-react'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useToast } from '@/hooks/use-toast'
import { useClearFile, filingFromStore } from '@/lib/store'
import { YEARS, usd, pct, STATUS_LABELS, STATUS_HELP } from '@/lib/tax/config'
import type { FilingStatus } from '@/lib/tax/config'
import { compute, ruleChecks, type Computed, type FilingData, type W2 } from '@/lib/tax/engine'
import { KeyOnboardingCard, AutofillPanel, ReviewPanel } from './ai-ui'
import { serializeCfr, downloadText, downloadBytes } from '@/lib/files/cfr'
import { exportTxf } from '@/lib/files/txf'
import { exportTaxContainer } from '@/lib/files/taxfile'
import { cn } from '@/lib/utils'

/* ---------------------------------------------------------------- */

function useFilingComputed(): { filing: FilingData; computed: Computed } {
  const store = useClearFile()
  const filing = filingFromStore(store)
  const computed = compute(filing, YEARS[filing.taxYear])
  return { filing, computed }
}

function StepHeader({ title, sub }: { title: string; sub: string }) {
  return (
    <div className="mb-5">
      <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
      <p className="mt-1.5 text-md-on-surface-variant max-w-2xl leading-relaxed">{sub}</p>
    </div>
  )
}

function MoneyInput({
  label,
  value,
  onChange,
  hint,
  ariaLabel,
}: {
  label: string
  value: number
  onChange: (v: number) => void
  hint?: string
  ariaLabel?: string
}) {
  return (
    <div className="space-y-1.5">
      <Label className="text-sm font-normal text-md-on-surface-variant">{label}</Label>
      <div className="relative">
        <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm text-md-on-surface-variant" aria-hidden>$</span>
        <Input
          type="number"
          min={0}
          step="1"
          inputMode="numeric"
          value={value === 0 ? '' : value}
          placeholder="0"
          onChange={(e) =>
            onChange(e.target.value === '' ? 0 : Math.max(0, Math.round(Number(e.target.value) || 0)))
          }
          className="pl-7 rounded-xl h-12 text-sm tabular-nums"
          aria-label={ariaLabel ?? label}
        />
      </div>
      {hint && <p className="text-xs text-md-on-surface-variant/90 leading-snug">{hint}</p>}
    </div>
  )
}

function DisclaimerAlert({ className }: { className?: string }) {
  return (
    <div
      role="note"
      className={cn(
        'flex gap-2.5 rounded-2xl border border-md-tertiary/40 bg-md-tertiary-container/30 p-3.5 text-xs leading-relaxed text-md-on-surface',
        className
      )}
    >
      <TriangleAlert className="size-4 shrink-0 mt-0.5 text-md-tertiary" aria-hidden />
      <p>
        <span className="font-semibold">Prototype software.</span> ClearFile demonstrates a clean-room tax workflow with
        verified TY2025/TY2026 federal parameters, but it is simplified (no preferential capital-gain rates, AMT, or
        state returns) and is not IRS e-file software. Do not use it to file a real return.
      </p>
    </div>
  )
}

/* ---------------------------------------------------------------- */
/* Welcome                                                           */
/* ---------------------------------------------------------------- */

export function WelcomeStep() {
  const next = useClearFile((s) => s.next)
  const loadSample = useClearFile((s) => s.loadSample)
  const googleKey = useClearFile((s) => s.googleKey)
  const openrouterKey = useClearFile((s) => s.openrouterKey)
  const { toast } = useToast()
  const hasKeys = Boolean(googleKey || openrouterKey)

  return (
    <div className="space-y-5">
      <div className="rounded-[28px] bg-md-primary-container p-6 sm:p-8 text-md-on-primary-container">
        <BadgeCheck className="size-8 mb-3" aria-hidden />
        <h1 className="text-3xl font-semibold tracking-tight">Let&apos;s figure out your taxes.</h1>
        <p className="mt-2 max-w-xl leading-relaxed">
          Plain questions, one decision at a time. ClearFile does the math with verified federal parameters and shows
          every number behind your result.
        </p>
        <div className="mt-5 flex flex-wrap gap-2.5">
          <Button onClick={next} className="rounded-full h-12 px-6 gap-1.5">
            Start my return <ArrowRight className="size-4" aria-hidden />
          </Button>
          <Button
            variant="secondary"
            className="rounded-full h-12 px-5"
            onClick={() => {
              loadSample()
              toast({ title: 'Sample return loaded', description: 'A married-filing-jointly demo with two W-2s, interest income, and two kids.' })
            }}
          >
            Load sample return
          </Button>
        </div>
      </div>

      <DisclaimerAlert />

      <Card className="rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">What this prototype does</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3 sm:grid-cols-3 text-sm">
          <div className="flex gap-2.5">
            <ShieldCheck className="size-5 shrink-0 text-md-primary" aria-hidden />
            <p className="text-md-on-surface-variant">Local-first: your return lives in this browser and in files you export — never on a server.</p>
          </div>
          <div className="flex gap-2.5">
            <Sparkles className="size-5 shrink-0 text-md-primary" aria-hidden />
            <p className="text-md-on-surface-variant">Optional AI copilot, auto-fill, and return review running on free keys you own.</p>
          </div>
          <div className="flex gap-2.5">
            <FileCheck2 className="size-5 shrink-0 text-md-primary" aria-hidden />
            <p className="text-md-on-surface-variant">Open .cfr save format, TXF export, and an honest best-effort .tax inspector.</p>
          </div>
        </CardContent>
      </Card>

      {!hasKeys && <KeyOnboardingCard />}
    </div>
  )
}

/* ---------------------------------------------------------------- */
/* Filing status                                                     */
/* ---------------------------------------------------------------- */

export function StatusStep() {
  const status = useClearFile((s) => s.status)
  const setStatus = useClearFile((s) => s.setStatus)
  const { computed } = useFilingComputed()

  return (
    <section aria-labelledby="status-heading">
      <StepHeader
        title="How were you set up at the end of the year?"
        sub="Your filing status sets your standard deduction and your tax brackets. Not sure? The IRS Interactive Tax Assistant can help you decide."
      />
      <RadioGroup
        value={status}
        onValueChange={(v) => setStatus(v as FilingStatus)}
        className="grid gap-3 sm:grid-cols-2"
      >
        {(['single', 'mfj', 'mfs', 'hoh'] as const).map((st) => (
          <label
            key={st}
            className={cn(
              'flex cursor-pointer gap-3 rounded-3xl border p-4 transition-colors',
              status === st
                ? 'border-md-primary bg-md-primary-container/35'
                : 'border-md-outline-variant hover:bg-md-surface-1'
            )}
          >
            <RadioGroupItem value={st} className="mt-1" />
            <span>
              <span className="block font-medium">{STATUS_LABELS[st]}</span>
              <span className="mt-1 block text-xs leading-relaxed text-md-on-surface-variant">{STATUS_HELP[st]}</span>
              <span className="mt-2 block text-xs font-medium text-md-primary">
                Standard deduction: {usd(YEARS[useClearFile.getState().taxYear].standardDeduction[st])}
              </span>
            </span>
          </label>
        ))}
      </RadioGroup>
      <p className="mt-4 text-xs text-md-on-surface-variant">
        With your current entries the engine would use the {STATUS_LABELS[status]} brackets — top marginal rate{' '}
        {pct(computed.marginalRate)}.
      </p>
    </section>
  )
}

/* ---------------------------------------------------------------- */
/* Income                                                            */
/* ---------------------------------------------------------------- */

function W2Card({ w2 }: { w2: W2 }) {
  const updateW2 = useClearFile((s) => s.updateW2)
  const removeW2 = useClearFile((s) => s.removeW2)
  return (
    <div className="rounded-3xl border border-md-outline-variant bg-card p-4 space-y-3">
      <div className="flex items-center gap-2">
        <Input
          value={w2.employer}
          onChange={(e) => updateW2(w2.id, { employer: e.target.value })}
          placeholder="Employer name"
          className="rounded-xl h-10"
          aria-label="Employer name"
        />
        <Button
          variant="ghost"
          size="icon"
          className="rounded-full size-10 shrink-0 text-md-error hover:bg-md-error-container/40"
          onClick={() => removeW2(w2.id)}
          aria-label={`Remove W-2 for ${w2.employer || 'this employer'}`}
        >
          <Trash2 className="size-4" aria-hidden />
        </Button>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <MoneyInput
          label="Box 1 — Wages, tips, other comp"
          value={w2.wages}
          onChange={(v) => updateW2(w2.id, { wages: v })}
        />
        <MoneyInput
          label="Box 2 — Federal income tax withheld"
          value={w2.federalWithheld}
          onChange={(v) => updateW2(w2.id, { federalWithheld: v })}
        />
      </div>
    </div>
  )
}

export function IncomeStep() {
  const addW2 = useClearFile((s) => s.addW2)
  const setIncomeField = useClearFile((s) => s.setIncomeField)
  const w2s = useClearFile((s) => s.w2s)
  const { filing, computed } = useFilingComputed()

  return (
    <section aria-labelledby="income-heading">
      <StepHeader
        title="Income"
        sub="Start with your W-2s, then any bank interest or dividends. ClearFile adds everything up as you go."
      />
      <div className="space-y-4">
        <Card className="rounded-3xl border-md-outline-variant">
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center justify-between gap-2">
              W-2 forms
              <Badge variant="outline" className="rounded-full font-normal text-md-on-surface-variant">
                wages {usd(computed.earnedIncome)}
              </Badge>
            </CardTitle>
            <CardDescription>Box 1 and Box 2 from each form.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {w2s.map((w) => (
              <W2Card key={w.id} w2={w} />
            ))}
            <Button
              variant="secondary"
              onClick={() => addW2({ employer: '', wages: 0, federalWithheld: 0 })}
              className="rounded-full h-10"
            >
              <Plus className="size-4" aria-hidden /> Add a W-2
            </Button>
          </CardContent>
        </Card>

        <AutofillPanel />

        <Card className="rounded-3xl border-md-outline-variant">
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Other income</CardTitle>
            <CardDescription>Common 1099 items. Enter totals for the year.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <MoneyInput
              label="Interest (1099-INT)"
              value={filing.interest}
              onChange={(v) => setIncomeField('interest', v)}
              hint="Bank and brokerage interest."
            />
            <MoneyInput
              label="Dividends (1099-DIV, ordinary)"
              value={filing.dividends}
              onChange={(v) => setIncomeField('dividends', v)}
              hint="Demo engine taxes these as ordinary income."
            />
            <MoneyInput
              label="Other income"
              value={filing.otherIncome}
              onChange={(v) => setIncomeField('otherIncome', v)}
              hint="Miscellaneous income in this simplified demo."
            />
            <MoneyInput
              label="Adjustments to income"
              value={filing.adjustments}
              onChange={(v) => setIncomeField('adjustments', v)}
              hint="Above-the-line items, e.g. student loan interest, HSA."
            />
          </CardContent>
        </Card>

        <div className="flex items-center justify-between rounded-3xl bg-md-surface-1 px-5 py-4">
          <span className="text-sm text-md-on-surface-variant">Total income so far</span>
          <span className="text-xl font-semibold tabular-nums">{usd(computed.totalIncome)}</span>
        </div>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------------- */
/* Deductions                                                        */
/* ---------------------------------------------------------------- */

export function DeductionsStep() {
  const setItemizedField = useClearFile((s) => s.setItemizedField)
  const { filing, computed } = useFilingComputed()
  const itemized = filing.itemized

  return (
    <section aria-labelledby="deductions-heading">
      <StepHeader
        title="Deductions"
        sub="Two ways to lower your taxable income. ClearFile automatically uses whichever is larger — you cannot lose by trying itemized."
      />
      <div className="grid gap-3 sm:grid-cols-2">
        <div
          className={cn(
            'rounded-3xl border p-5',
            computed.deductionChoice === 'standard'
              ? 'border-md-primary bg-md-primary-container/30'
              : 'border-md-outline-variant'
          )}
        >
          <div className="flex items-center justify-between">
            <h3 className="font-medium">Standard deduction</h3>
            {computed.deductionChoice === 'standard' && (
              <Badge className="rounded-full bg-md-primary text-md-on-primary hover:bg-md-primary font-normal">used</Badge>
            )}
          </div>
          <p className="mt-2 text-2xl font-semibold tabular-nums">{usd(computed.standardDeduction)}</p>
          <p className="mt-1 text-xs text-md-on-surface-variant">Automatic for your filing status — no receipts needed.</p>
        </div>
        <div
          className={cn(
            'rounded-3xl border p-5',
            computed.deductionChoice === 'itemized'
              ? 'border-md-primary bg-md-primary-container/30'
              : 'border-md-outline-variant'
          )}
        >
          <div className="flex items-center justify-between">
            <h3 className="font-medium">Itemized deductions</h3>
            {computed.deductionChoice === 'itemized' && (
              <Badge className="rounded-full bg-md-primary text-md-on-primary hover:bg-md-primary font-normal">used</Badge>
            )}
          </div>
          <p className="mt-2 text-2xl font-semibold tabular-nums">{usd(computed.itemizedTotal)}</p>
          <p className="mt-1 text-xs text-md-on-surface-variant">Your qualifying expenses added up below.</p>
        </div>
      </div>

      <Card className="mt-4 rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Itemized expenses (optional)</CardTitle>
          <CardDescription>
            Demo simplification: amounts are deducted at face value — no SALT cap or 7.5% medical floor. Production rules
            are specified in the engineering blueprint.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2">
          <MoneyInput label="Medical & dental" value={itemized.medical} onChange={(v) => setItemizedField('medical', v)} />
          <MoneyInput label="State & local taxes paid" value={itemized.taxesPaid} onChange={(v) => setItemizedField('taxesPaid', v)} />
          <MoneyInput label="Mortgage interest" value={itemized.mortgageInterest} onChange={(v) => setItemizedField('mortgageInterest', v)} />
          <MoneyInput label="Charitable gifts" value={itemized.charity} onChange={(v) => setItemizedField('charity', v)} />
          <MoneyInput label="Other deductible expenses" value={itemized.other} onChange={(v) => setItemizedField('other', v)} />
        </CardContent>
      </Card>
    </section>
  )
}

/* ---------------------------------------------------------------- */
/* Dependents                                                        */
/* ---------------------------------------------------------------- */

function Counter({
  label,
  description,
  value,
  onChange,
}: {
  label: string
  description: string
  value: number
  onChange: (v: number) => void
}) {
  return (
    <div className="flex items-center gap-4 rounded-3xl border border-md-outline-variant p-4">
      <div className="flex-1 min-w-0">
        <p className="font-medium">{label}</p>
        <p className="mt-0.5 text-xs leading-relaxed text-md-on-surface-variant">{description}</p>
      </div>
      <div className="flex items-center gap-1.5">
        <Button
          variant="outline"
          size="icon"
          className="rounded-full size-10"
          onClick={() => onChange(value - 1)}
          aria-label={`Remove one — ${label}`}
        >
          <Minus className="size-4" aria-hidden />
        </Button>
        <span className="w-7 text-center text-lg font-semibold tabular-nums" aria-live="polite">{value}</span>
        <Button
          variant="outline"
          size="icon"
          className="rounded-full size-10"
          onClick={() => onChange(value + 1)}
          aria-label={`Add one — ${label}`}
        >
          <Plus className="size-4" aria-hidden />
        </Button>
      </div>
    </div>
  )
}

export function DependentsStep() {
  const setDependentField = useClearFile((s) => s.setDependentField)
  const { filing, computed } = useFilingComputed()
  const threshold = filing.status === 'mfj' ? 400000 : 200000
  const nearPhaseout = computed.agi > threshold * 0.9

  return (
    <section aria-labelledby="dependents-heading">
      <StepHeader
        title="Dependents"
        sub="People you support can lower your tax — the child tax credit is worth up to $2,200 per qualifying child, part of it refundable."
      />
      <div className="space-y-3">
        <Counter
          label="Qualifying children under 17"
          description="Lived with you over half the year, under 17 at year end, and you provided over half their support."
          value={filing.qualifyingChildren}
          onChange={(v) => setDependentField('qualifyingChildren', v)}
        />
        <Counter
          label="Other dependents"
          description="Dependents who do not qualify for the child tax credit — worth $500 each (Credit for Other Dependents)."
          value={filing.otherDependents}
          onChange={(v) => setDependentField('otherDependents', v)}
        />
      </div>

      <Card className="mt-4 rounded-3xl border-md-outline-variant bg-md-surface-1/50">
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Credit estimate</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-md-on-surface-variant">Child tax credit (max, before phase-out)</span>
            <span className="font-semibold tabular-nums">{usd(computed.ctcMax)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-md-on-surface-variant">Applied against this year&apos;s tax</span>
            <span className="font-semibold tabular-nums">{usd(computed.ctcApplied)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-md-on-surface-variant">Refundable portion (ACTC, simplified)</span>
            <span className="font-semibold tabular-nums">{usd(computed.actc)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-md-on-surface-variant">Credit for other dependents</span>
            <span className="font-semibold tabular-nums">{usd(computed.odcApplied)}</span>
          </div>
          {nearPhaseout && (
            <p className="flex gap-2 rounded-2xl bg-md-tertiary-container/40 p-3 text-xs leading-relaxed">
              <Info className="size-4 shrink-0 mt-0.5 text-md-tertiary" aria-hidden />
              The credit phases out above {usd(threshold)} of income for your filing status (your AGI:{' '}
              {usd(computed.agi)}), reducing the credit by $50 per $1,000 over.
            </p>
          )}
        </CardContent>
      </Card>
    </section>
  )
}

/* ---------------------------------------------------------------- */
/* Payments                                                          */
/* ---------------------------------------------------------------- */

export function PaymentsStep() {
  const setIncomeField = useClearFile((s) => s.setIncomeField)
  const setStep = useClearFile((s) => s.setStep)
  const { filing, computed } = useFilingComputed()

  const coveredRatio = computed.totalTax > 0 ? (computed.totalPayments + computed.actc) / computed.totalTax : 1
  const coverageLabel =
    computed.totalTax === 0
      ? 'No tax due with your current entries.'
      : coveredRatio < 0.9
        ? 'Payments are below your computed tax — expect to owe at filing.'
        : coveredRatio <= 1.1
          ? 'Payments are roughly on target for your computed tax.'
          : 'Payments exceed your computed tax — expect a refund.'

  return (
    <section aria-labelledby="payments-heading">
      <StepHeader
        title="Payments"
        sub="Tax you already paid during the year — withholding from paychecks plus any estimated payments — comes back to you as a refund if it exceeds your tax."
      />
      <div className="space-y-4">
        <Card className="rounded-3xl border-md-outline-variant">
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center justify-between">
              Federal withholding (from W-2s)
              <Badge variant="outline" className="rounded-full font-normal text-md-on-surface-variant">
                {usd(computed.withholding)}
              </Badge>
            </CardTitle>
            <CardDescription>Box 2 totals from the Income step.</CardDescription>
          </CardHeader>
          <CardContent>
            <Button variant="outline" className="rounded-full h-9" onClick={() => setStep(2)}>
              Edit W-2s
            </Button>
          </CardContent>
        </Card>

        <Card className="rounded-3xl border-md-outline-variant">
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Estimated tax payments</CardTitle>
            <CardDescription>Quarterly payments you made directly (1040-ES).</CardDescription>
          </CardHeader>
          <CardContent>
            <MoneyInput
              label="Total estimated payments for the year"
              value={filing.estimatedPayments}
              onChange={(v) => setIncomeField('estimatedPayments', v)}
            />
          </CardContent>
        </Card>

        <Card className="rounded-3xl border-md-outline-variant bg-md-surface-1/50">
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Coverage ballpark</CardTitle>
            <CardDescription>{coverageLabel}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            <Progress value={Math.min(100, Math.round(coveredRatio * 100))} className="h-2.5" aria-label="Payment coverage" />
            <div className="flex justify-between text-xs text-md-on-surface-variant">
              <span>Paid so far: {usd(computed.totalPayments + computed.actc)}</span>
              <span>Computed tax: {usd(computed.totalTax)}</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </section>
  )
}

/* ---------------------------------------------------------------- */
/* Results                                                           */
/* ---------------------------------------------------------------- */

export function ResultsStep() {
  const { filing, computed } = useFilingComputed()
  const { toast } = useToast()
  const checks = ruleChecks(filing, computed)

  const rows: [string, string, string?][] = [
    ['Total income', usd(computed.totalIncome), 'Wages + interest + dividends + other'],
    ['Adjustments to income', `−${usd(filing.adjustments)}`],
    ['Adjusted gross income (AGI)', usd(computed.agi)],
    [
      `Deduction — ${computed.deductionChoice}`,
      `−${usd(computed.deduction)}`,
      computed.deductionChoice === 'itemized'
        ? 'Itemized total (larger than standard)'
        : `Standard deduction for ${STATUS_LABELS[filing.status]}`,
    ],
    ['Taxable income', usd(computed.taxableIncome)],
    ['Tax before credits', usd(computed.taxBeforeCredits), 'Bracket walk on taxable income'],
    ['Child tax credit (nonrefundable)', `−${usd(computed.ctcApplied)}`, `of up to ${usd(computed.ctcMax)}`],
    ['Credit for other dependents', `−${usd(computed.odcApplied)}`],
    ['Total tax', usd(computed.totalTax)],
    ['Refundable child tax credit (ACTC)', `+${usd(computed.actc)}`, 'Simplified Schedule 8812 formula'],
    ['Withholding + estimated payments', `+${usd(computed.totalPayments)}`],
  ]

  function saveCfr() {
    downloadText(`clearfile-${filing.taxYear}-return.cfr`, serializeCfr(filing))
    toast({ title: 'Return saved', description: 'Open .cfr file — keep it anywhere, reopen it here anytime.' })
  }
  function saveTxf() {
    downloadText(`clearfile-${filing.taxYear}.txf`, exportTxf(filing, computed), 'application/octet-stream')
    toast({
      title: 'TXF exported',
      description: 'Wages + withholding only (demo scope). Verify after import.',
    })
  }
  function saveTax() {
    downloadBytes(`clearfile-${filing.taxYear}-exchange.tax`, exportTaxContainer(filing))
    toast({
      title: '.tax container exported',
      description: 'Experimental open container — not Intuit format.',
    })
  }

  return (
    <section aria-labelledby="results-heading" className="space-y-5">
      <div className="hidden print:block mb-2">
        <p className="text-lg font-semibold">ClearFile — return summary (prototype)</p>
        <p className="text-xs">
          Tax year {filing.taxYear} · {STATUS_LABELS[filing.status]} · Demo output — not for filing. Generated locally in
          your browser.
        </p>
      </div>

      <StepHeader
        title="Review & results"
        sub="Every number below traces back to what you entered. Run the AI review for a second look, print a summary, or save your return."
      />

      <div
        className={cn(
          'rounded-[28px] p-6 sm:p-8',
          computed.isRefund ? 'bg-md-success-container text-md-on-success-container' : 'bg-md-error-container text-md-on-error-container'
        )}
      >
        <p className="text-sm font-medium uppercase tracking-wide">
          {computed.isRefund ? 'Projected refund' : 'Projected balance due'}
        </p>
        <p className="mt-1 text-4xl sm:text-5xl font-semibold tabular-nums">{usd(Math.abs(computed.balance))}</p>
        <p className="mt-2 text-sm leading-relaxed">
          {computed.isRefund
            ? `You have paid ${usd(computed.totalPayments + computed.actc)} against a computed tax of ${usd(computed.totalTax)}.`
            : `Your computed tax of ${usd(computed.totalTax)} exceeds payments of ${usd(computed.totalPayments + computed.actc)}.`}{' '}
          Effective tax rate {pct(computed.effectiveRate)} of total income; top bracket {pct(computed.marginalRate)}.
        </p>
      </div>

      <div className="no-print">
        <ReviewPanel checks={checks} />
      </div>

      {checks.length > 0 && (
        <Card className="print-plain rounded-3xl border-md-outline-variant">
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Automatic checks</CardTitle>
            <CardDescription>Rule-based, run locally — no AI needed.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            {checks.map((ch) => (
              <div key={ch.id} className="flex gap-2.5 rounded-2xl bg-md-surface-1 p-3 text-sm">
                {ch.severity === 'warn' ? (
                  <TriangleAlert className="size-4 shrink-0 mt-0.5 text-md-error" aria-hidden />
                ) : (
                  <Info className="size-4 shrink-0 mt-0.5 text-md-primary" aria-hidden />
                )}
                <span>
                  <span className="font-medium">{ch.title}</span>
                  <span className="block text-md-on-surface-variant leading-relaxed">{ch.detail}</span>
                </span>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <Card className="print-plain rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Your return at a glance</CardTitle>
          <CardDescription>Simplified 1040-style summary.</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                <TableHead className="text-xs text-md-on-surface-variant">Line</TableHead>
                <TableHead className="text-right text-xs text-md-on-surface-variant">Amount</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map(([label, amount, note]) => (
                <TableRow key={label} className="hover:bg-transparent">
                  <TableCell className="py-2.5 text-sm">
                    {label}
                    {note && <span className="block text-xs text-md-on-surface-variant">{note}</span>}
                  </TableCell>
                  <TableCell className="py-2.5 text-right text-sm tabular-nums font-medium whitespace-nowrap">{amount}</TableCell>
                </TableRow>
              ))}
              <TableRow className="hover:bg-transparent border-t-2 border-md-outline-variant">
                <TableCell className="py-3 font-semibold">
                  {computed.isRefund ? 'Refund' : 'Amount you owe'}
                </TableCell>
                <TableCell className="py-3 text-right font-semibold tabular-nums whitespace-nowrap">
                  {computed.isRefund ? '+' : '−'}
                  {usd(Math.abs(computed.balance))}
                </TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card className="print-plain rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Where your tax comes from</CardTitle>
          <CardDescription>
            Taxable income {usd(computed.taxableIncome)} walked through the {filing.taxYear} brackets for{' '}
            {STATUS_LABELS[filing.status]}.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {computed.bracketRows
            .filter((r) => r.income > 0)
            .map((row) => (
              <div key={row.rate} className="space-y-1">
                <div className="flex items-baseline justify-between text-xs">
                  <span className="font-medium">
                    {(row.rate * 100).toFixed(0)}% bracket
                    <span className="ml-1.5 font-normal text-md-on-surface-variant">
                      {usd(row.lo)} – {row.hi == null ? 'above' : usd(row.hi)}
                    </span>
                  </span>
                  <span className="tabular-nums text-md-on-surface-variant">
                    {usd(row.income)} of income → {usd(row.tax)} tax
                  </span>
                </div>
                <div className="h-2 rounded-full bg-md-surface-2 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-md-primary"
                    style={{ width: `${computed.taxableIncome > 0 ? (row.income / computed.taxableIncome) * 100 : 0}%` }}
                  />
                </div>
              </div>
            ))}
          {computed.taxableIncome === 0 && (
            <p className="text-sm text-md-on-surface-variant">No taxable income — the standard deduction covered it all.</p>
          )}
        </CardContent>
      </Card>

      <div className="no-print flex flex-wrap gap-2">
        <Button onClick={() => window.print()} className="rounded-full h-11 gap-1.5">
          <Printer className="size-4" aria-hidden /> Print summary
        </Button>
        <Button variant="secondary" onClick={saveCfr} className="rounded-full h-11 gap-1.5">
          <Save className="size-4" aria-hidden /> Save .cfr
        </Button>
        <Button variant="outline" onClick={saveTxf} className="rounded-full h-11 gap-1.5">
          <FileDown className="size-4" aria-hidden /> Export TXF
        </Button>
        <Button variant="outline" onClick={saveTax} className="rounded-full h-11 gap-1.5">
          <Archive className="size-4" aria-hidden /> Export .tax (experimental)
        </Button>
      </div>

      <DisclaimerAlert className="no-print" />
    </section>
  )
}
