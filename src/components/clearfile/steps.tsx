'use client'
// SPDX-License-Identifier: GPL-3.0-only

import * as React from 'react'
import {
  Plus, Trash2, Printer, Save, FileDown, Archive, ShieldCheck,
  FileCheck2, ArrowRight, TriangleAlert, Info, Sparkles, BadgeCheck, UserPlus,
} from 'lucide-react'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Switch } from '@/components/ui/switch'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useToast } from '@/hooks/use-toast'
import { useClearFile, filingFromStore } from '@/lib/store'
import {
  YEARS, usd, pct, STATUS_LABELS, STATUS_HELP, DEDUCTION_METHOD_LABELS,
  type FilingStatus, type DeductionMethod, type TaxYear,
} from '@/lib/tax/config'
import {
  compute, ruleChecks, totalWages, totalWithholding, bracketWalk,
  type RuleCheck, type TaxResult, type TaxReturnData, type W2Entry, type Dependent,
} from '@/lib/tax/engine'
import { KeyOnboardingCard, AutofillPanel, ReviewPanel } from './ai-ui'
import { serializeCfr, downloadText, downloadBytes } from '@/lib/files/cfr'
import { exportTxf } from '@/lib/files/txf'
import { exportTaxContainer } from '@/lib/files/taxfile'
import { cn } from '@/lib/utils'

/* ---------------------------------------------------------------- */

function useFilingComputed(): { filing: TaxReturnData; computed: TaxResult } {
  const store = useClearFile()
  const filing = filingFromStore(store)
  const params = YEARS[filing.taxYear as TaxYear] ?? YEARS[2025]
  const computed = compute(filing, params)
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

function FlagRow({
  checked,
  onChange,
  title,
  hint,
}: {
  checked: boolean
  onChange: (v: boolean) => void
  title: string
  hint?: string
}) {
  return (
    <div className="flex items-center justify-between gap-4 py-3">
      <div className="min-w-0">
        <p className="text-sm font-medium">{title}</p>
        {hint && <p className="mt-0.5 text-xs leading-relaxed text-md-on-surface-variant">{hint}</p>}
      </div>
      <Switch
        checked={checked}
        onCheckedChange={onChange}
        aria-label={title}
      />
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
        verified TY2025 federal parameters, but it is simplified (no AMT, self-employment tax, or state returns) and is
        not IRS e-file software. Do not use it to file a real return.
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

const STATUS_ORDER: FilingStatus[] = [
  'single', 'marriedJoint', 'marriedSeparate', 'headOfHousehold', 'survivingSpouse',
]

export function StatusStep() {
  const status = useClearFile((s) => s.filingStatus)
  const setStatus = useClearFile((s) => s.setStatus)
  const setFlag = useClearFile((s) => s.setFlag)
  const taxpayer65 = useClearFile((s) => s.taxpayer65OrOlder)
  const spouse65 = useClearFile((s) => s.spouse65OrOlder)
  const taxpayerBlind = useClearFile((s) => s.taxpayerBlind)
  const spouseBlind = useClearFile((s) => s.spouseBlind)
  const { computed } = useFilingComputed()
  const hasSpouse = status === 'marriedJoint'

  return (
    <section aria-labelledby="status-heading">
      <StepHeader
        title="How were you set up at the end of the year?"
        sub="Your filing status sets your standard deduction and your tax brackets. Pick the status that matched your situation on December 31, 2025."
      />
      <RadioGroup
        value={status}
        onValueChange={(v) => setStatus(v as FilingStatus)}
        className="grid gap-3 sm:grid-cols-2"
      >
        {STATUS_ORDER.map((st) => (
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
                Standard deduction: {usd(YEARS[2025].standardDeduction[st])}
              </span>
            </span>
          </label>
        ))}
      </RadioGroup>

      <Card className="mt-5 rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-2">
          <CardTitle className="text-base">About you{hasSpouse ? ' (and your spouse)' : ''}</CardTitle>
          <CardDescription>
            Each person who is 65 or older or legally blind adds an extra standard-deduction amount.
          </CardDescription>
        </CardHeader>
        <CardContent className="divide-y divide-md-outline-variant/50">
          <FlagRow
            checked={taxpayer65}
            onChange={(v) => setFlag('taxpayer65OrOlder', v)}
            title="I was 65 or older on Dec 31, 2025"
            hint="Adds an extra standard deduction amount for each person 65+."
          />
          <FlagRow checked={taxpayerBlind} onChange={(v) => setFlag('taxpayerBlind', v)} title="I am legally blind" />
          {hasSpouse && (
            <>
              <FlagRow checked={spouse65} onChange={(v) => setFlag('spouse65OrOlder', v)} title="My spouse was 65 or older" />
              <FlagRow checked={spouseBlind} onChange={(v) => setFlag('spouseBlind', v)} title="My spouse is legally blind" />
            </>
          )}
        </CardContent>
      </Card>

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

function W2Card({ w2 }: { w2: W2Entry }) {
  const updateW2 = useClearFile((s) => s.updateW2)
  const removeW2 = useClearFile((s) => s.removeW2)
  return (
    <div className="rounded-3xl border border-md-outline-variant bg-card p-4 space-y-3">
      <div className="flex items-center gap-2">
        <Input
          value={w2.employer}
          onChange={(e) => updateW2(w2.id ?? '', { employer: e.target.value })}
          placeholder="Employer name"
          className="rounded-xl h-10"
          aria-label="Employer name"
        />
        <Button
          variant="ghost"
          size="icon"
          className="rounded-full size-10 shrink-0 text-md-error hover:bg-md-error-container/40"
          onClick={() => removeW2(w2.id ?? '')}
          aria-label={`Remove W-2 for ${w2.employer || 'this employer'}`}
        >
          <Trash2 className="size-4" aria-hidden />
        </Button>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <MoneyInput
          label="Box 1 — Wages, tips, other comp"
          value={w2.wages}
          onChange={(v) => updateW2(w2.id ?? '', { wages: v })}
        />
        <MoneyInput
          label="Box 2 — Federal income tax withheld"
          value={w2.withholding}
          onChange={(v) => updateW2(w2.id ?? '', { withholding: v })}
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
        sub="Start with your W-2s, then bank interest, dividends, and capital gains. ClearFile adds everything up as you go."
      />
      <div className="space-y-4">
        <Card className="rounded-3xl border-md-outline-variant">
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center justify-between gap-2">
              W-2 forms
              <Badge variant="outline" className="rounded-full font-normal text-md-on-surface-variant">
                wages {usd(totalWages(filing))}
              </Badge>
            </CardTitle>
            <CardDescription>Box 1 and Box 2 from each form.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {w2s.map((w) => (
              <W2Card key={w.id ?? w.employer} w2={w} />
            ))}
            <Button
              variant="secondary"
              onClick={() => addW2({ employer: '', wages: 0, withholding: 0 })}
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
              label="Interest (1099-INT, Box 1)"
              value={filing.interestIncome}
              onChange={(v) => setIncomeField('interestIncome', v)}
              hint="Bank and brokerage interest."
            />
            <MoneyInput
              label="Ordinary dividends (1099-DIV, Box 1a)"
              value={filing.ordinaryDividends}
              onChange={(v) => setIncomeField('ordinaryDividends', v)}
              hint="The part NOT taxed at lower rates. Add qualified dividends separately."
            />
            <MoneyInput
              label="Qualified dividends (1099-DIV, Box 1b)"
              value={filing.qualifiedDividends}
              onChange={(v) => setIncomeField('qualifiedDividends', v)}
              hint="Taxed at the lower capital-gains rates."
            />
            <MoneyInput
              label="Long-term capital gains"
              value={filing.longTermCapitalGains}
              onChange={(v) => setIncomeField('longTermCapitalGains', v)}
              hint="Assets held more than one year."
            />
            <MoneyInput
              label="Other income"
              value={filing.otherIncome}
              onChange={(v) => setIncomeField('otherIncome', v)}
              hint="Self-employment, gig platforms, prizes, etc."
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
  const setIncomeField = useClearFile((s) => s.setIncomeField)
  const setDeductionMethod = useClearFile((s) => s.setDeductionMethod)
  const { filing, computed } = useFilingComputed()
  const methods = ['auto', 'standard', 'itemized'] as const

  return (
    <section aria-labelledby="deductions-heading">
      <StepHeader
        title="Deductions"
        sub="Two ways to lower your taxable income. If you let ClearFile compare, it uses whichever is larger — you cannot lose by trying itemized."
      />

      <Card className="rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Deduction method</CardTitle>
        </CardHeader>
        <CardContent>
          <RadioGroup
            value={filing.deductionMethod}
            onValueChange={(v) => setDeductionMethod(v as DeductionMethod)}
            className="grid gap-3"
          >
            {methods.map((m) => (
              <label
                key={m}
                className={cn(
                  'flex cursor-pointer items-center gap-3 rounded-3xl border p-4 transition-colors',
                  filing.deductionMethod === m
                    ? 'border-md-primary bg-md-primary-container/35'
                    : 'border-md-outline-variant hover:bg-md-surface-1'
                )}
              >
                <RadioGroupItem value={m} />
                <span className="text-sm font-medium">{DEDUCTION_METHOD_LABELS[m]}</span>
              </label>
            ))}
          </RadioGroup>
        </CardContent>
      </Card>

      <div className="mt-4 flex flex-wrap gap-2">
        <Badge variant="outline" className="rounded-full h-9 px-4 font-normal text-md-on-surface-variant">
          Standard {usd(computed.standardDeductionTotal)}
        </Badge>
        <Badge variant="outline" className="rounded-full h-9 px-4 font-normal text-md-on-surface-variant">
          Itemized {usd(computed.itemizedDeductionTotal)}
        </Badge>
        <Badge className="rounded-full h-9 px-4 bg-md-primary text-md-on-primary hover:bg-md-primary">
          {computed.deductionMethodUsed === 'itemized' ? 'Itemizing is larger' : 'Standard deduction is larger'}
        </Badge>
      </div>

      <Card className="mt-4 rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">If you itemize</CardTitle>
          <CardDescription>
            Only needed when you itemize or let ClearFile compare. The state-and-local tax combination is subject to
            the SALT cap, and charitable gifts are capped at 60% / 30% of AGI.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2">
          <MoneyInput
            label="State & local income or sales tax (SALT)"
            value={filing.stateLocalIncomeOrSalesTax}
            onChange={(v) => setIncomeField('stateLocalIncomeOrSalesTax', v)}
          />
          <MoneyInput
            label="Real estate taxes"
            value={filing.realEstateTax}
            onChange={(v) => setIncomeField('realEstateTax', v)}
          />
          <MoneyInput
            label="Home mortgage interest (1098, Box 1)"
            value={filing.mortgageInterest}
            onChange={(v) => setIncomeField('mortgageInterest', v)}
          />
          <MoneyInput
            label="Charitable gifts — cash"
            value={filing.charitableCash}
            onChange={(v) => setIncomeField('charitableCash', v)}
          />
          <MoneyInput
            label="Charitable gifts — non-cash (thrift-store value)"
            value={filing.charitableNonCash}
            onChange={(v) => setIncomeField('charitableNonCash', v)}
          />
        </CardContent>
      </Card>

      <Card className="mt-4 rounded-3xl border-md-outline-variant">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Adjustments to income</CardTitle>
        </CardHeader>
        <CardContent>
          <MoneyInput
            label="Student loan interest (1098-E, Box 1)"
            value={filing.studentLoanInterest}
            onChange={(v) => setIncomeField('studentLoanInterest', v)}
            hint="Deductible up to $2,500, phasing out at higher income (not available when married filing separately)."
          />
        </CardContent>
      </Card>
    </section>
  )
}

/* ---------------------------------------------------------------- */
/* Dependents                                                        */
/* ---------------------------------------------------------------- */

function DependentCard({ d }: { d: Dependent }) {
  const updateDependent = useClearFile((s) => s.updateDependent)
  const removeDependent = useClearFile((s) => s.removeDependent)
  const id = d.id ?? ''
  return (
    <div className="rounded-3xl border border-md-outline-variant bg-card p-4 space-y-3">
      <div className="flex items-center gap-2">
        <Input
          value={d.name}
          onChange={(e) => updateDependent(id, { name: e.target.value })}
          placeholder="First and last name"
          className="rounded-xl h-10"
          aria-label="Dependent name"
        />
        <Button
          variant="ghost"
          size="icon"
          className="rounded-full size-10 shrink-0 text-md-error hover:bg-md-error-container/40"
          onClick={() => removeDependent(id)}
          aria-label={`Remove ${d.name || 'this dependent'}`}
        >
          <Trash2 className="size-4" aria-hidden />
        </Button>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1.5">
          <Label className="text-sm font-normal text-md-on-surface-variant">Age at the end of 2025</Label>
          <Input
            type="number"
            min={0}
            value={d.age === 0 ? '' : d.age}
            placeholder="0"
            onChange={(e) => updateDependent(id, { age: Math.max(0, Math.round(Number(e.target.value) || 0)) })}
            className="rounded-xl h-12 text-sm tabular-nums"
            aria-label="Dependent age"
          />
        </div>
        <Input
          value={d.relationship}
          onChange={(e) => updateDependent(id, { relationship: e.target.value })}
          placeholder="Relationship (son, parent, niece...)"
          className="rounded-xl h-12"
          aria-label="Relationship"
        />
      </div>
      <div className="divide-y divide-md-outline-variant/50 rounded-2xl border border-md-outline-variant/60 px-4">
        <FlagRow
          checked={d.qualifyingChild}
          onChange={(v) => updateDependent(id, { qualifyingChild: v })}
          title="Qualifying child under 17"
          hint="Child Tax Credit, $2,200 per child."
        />
        <FlagRow
          checked={d.otherDependentCredit}
          onChange={(v) => updateDependent(id, { otherDependentCredit: v })}
          title="Qualifies for the other-dependent credit"
          hint="$500 credit — for example a parent or a child 17+."
        />
      </div>
    </div>
  )
}

export function DependentsStep() {
  const addDependent = useClearFile((s) => s.addDependent)
  const dependents = useClearFile((s) => s.dependents)
  const { computed } = useFilingComputed()
  const kids = computed.qualifyingChildren
  const threshold = useClearFile((s) => (s.filingStatus === 'marriedJoint' || s.filingStatus === 'survivingSpouse' ? 400000 : 200000))
  const nearPhaseout = computed.agi > threshold * 0.9

  return (
    <section aria-labelledby="dependents-heading">
      <StepHeader
        title="Dependents"
        sub="People you support can lower your tax — the child tax credit is worth up to $2,200 per qualifying child, part of it refundable."
      />
      <div className="space-y-3">
        {dependents.map((d) => (
          <DependentCard key={d.id ?? d.name} d={d} />
        ))}
        {dependents.length === 0 && (
          <div className="rounded-3xl border border-md-outline-variant bg-md-surface-1/50 p-4 text-sm text-md-on-surface-variant">
            No dependents. Skip this step if nobody depends on you.
          </div>
        )}
        <Button variant="secondary" onClick={addDependent} className="rounded-full h-10">
          <UserPlus className="size-4" aria-hidden /> Add dependent
        </Button>
      </div>

      <Card className="mt-4 rounded-3xl border-md-outline-variant bg-md-surface-1/50">
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Credit estimate</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-md-on-surface-variant">Child tax credit (after phase-out)</span>
            <span className="font-semibold tabular-nums">{usd(Math.max(0, computed.nonRefundableCredits))}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-md-on-surface-variant">Refundable portion (ACTC)</span>
            <span className="font-semibold tabular-nums">{usd(computed.refundableCredits)}</span>
          </div>
          {nearPhaseout && (
            <p className="flex gap-2 rounded-2xl bg-md-tertiary-container/40 p-3 text-xs leading-relaxed">
              <Info className="size-4 shrink-0 mt-0.5 text-md-tertiary" aria-hidden />
              The credits phase out above {usd(threshold)} of AGI for your filing status (your AGI: {usd(computed.agi)}
              ) — the phase-out is 5% of the excess, rounded up to each $1,000 ({kids} qualifying child
              {kids === 1 ? '' : 'ren'} on file).
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

  const coveredRatio = computed.totalTax > 0 ? (computed.totalPayments + computed.refundableCredits) / computed.totalTax : 1
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
                {usd(totalWithholding(filing))}
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
              <span>Paid so far: {usd(computed.totalPayments + computed.refundableCredits)}</span>
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
  const checks: RuleCheck[] = ruleChecks(filing, computed)
  const refund = computed.refund
  const isRefundNow = refund > 0
  const balance = refund - computed.amountOwed
  const params = YEARS[filing.taxYear as TaxYear] ?? YEARS[2025]
  const ordinaryTaxable = computed.taxableIncome - computed.preferentialIncome
  const bracketRows = bracketWalk(ordinaryTaxable, params.ordinaryBrackets[filing.filingStatus])

  const rows: [string, string, string?][] = [
    ['Total income', usd(computed.totalIncome), 'Wages + interest + dividends + gains + other'],
    ...(computed.studentLoanDeduction > 0
      ? ([['Student loan interest deduction', `−${usd(computed.studentLoanDeduction)}`]] as [string, string][])
      : []),
    ['Adjusted gross income (AGI)', usd(computed.agi)],
    [
      `Deduction — ${computed.deductionMethodUsed}`,
      `−${usd(computed.deductionUsed)}`,
      computed.deductionMethodUsed === 'itemized'
        ? 'Itemized total after the SALT cap (incl. senior deduction)'
        : `Standard deduction for ${STATUS_LABELS[filing.filingStatus]} (incl. 65+/blind additions${computed.seniorDeduction > 0 ? ' and the senior deduction' : ''})`,
    ],
    ['Taxable income', usd(computed.taxableIncome)],
    ['Tax on ordinary income', usd(computed.ordinaryTax), 'Bracket walk on the ordinary slice'],
    ...(computed.preferentialTax > 0
      ? ([['Tax on qualified dividends & long-term gains', usd(computed.preferentialTax), '0% / 15% / 20% stacking']] as [string, string, string?][])
      : []),
    ...(computed.niit > 0 ? ([['Net investment income tax', usd(computed.niit), '3.8%']] as [string, string, string?][]) : []),
    ...(computed.nonRefundableCredits > 0
      ? ([['Non-refundable credits', `−${usd(computed.nonRefundableCredits)}`, 'CTC + other-dependent credit, after phase-out']] as [string, string, string?][])
      : []),
    ['Total tax', usd(computed.totalTax)],
    ...(computed.refundableCredits > 0
      ? ([['Additional child tax credit (refundable)', `+${usd(computed.refundableCredits)}`, '15% of earned income above $2,500']] as [string, string, string?][])
      : []),
    ['Withholding + estimated payments', `+${usd(computed.totalPayments)}`],
  ]

  function saveCfr() {
    downloadText(`clearfile-${filing.taxYear}-return.cfr`, serializeCfr(filing))
    toast({ title: 'Return saved', description: 'Open .cfr file — keep it anywhere, reopen it here anytime.' })
  }
  function saveTxf() {
    downloadText(`clearfile-${filing.taxYear}.txf`, exportTxf(filing), 'application/octet-stream')
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
          Tax year {filing.taxYear} · {STATUS_LABELS[filing.filingStatus]} · Demo output — not for filing. Generated locally in
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
          isRefundNow ? 'bg-md-success-container text-md-on-success-container' : 'bg-md-error-container text-md-on-error-container'
        )}
      >
        <p className="text-sm font-medium uppercase tracking-wide">
          {isRefundNow ? 'Projected refund' : 'Projected balance due'}
        </p>
        <p className="mt-1 text-4xl sm:text-5xl font-semibold tabular-nums">{usd(Math.abs(balance))}</p>
        <p className="mt-2 text-sm leading-relaxed">
          {isRefundNow
            ? `You have paid ${usd(computed.totalPayments + computed.refundableCredits)} against a computed tax of ${usd(computed.totalTax)}.`
            : `Your computed tax of ${usd(computed.totalTax)} exceeds payments of ${usd(computed.totalPayments + computed.refundableCredits)}.`}{' '}
          Effective tax rate {pct(computed.effectiveRate)} of AGI; top ordinary bracket {pct(computed.marginalRate)}.
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
                  {isRefundNow ? 'Refund' : 'Amount you owe'}
                </TableCell>
                <TableCell className="py-3 text-right font-semibold tabular-nums whitespace-nowrap">
                  {isRefundNow ? '+' : '−'}
                  {usd(Math.abs(balance))}
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
            Ordinary taxable income {usd(ordinaryTaxable)} walked through the {filing.taxYear} brackets for{' '}
            {STATUS_LABELS[filing.filingStatus]}
            {computed.preferentialIncome > 0
              ? `; qualified dividends and long-term gains (${usd(computed.preferentialIncome)}) stack on top at their own rates.`
              : '.'}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {bracketRows
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
                    style={{ width: `${ordinaryTaxable > 0 ? (row.income / ordinaryTaxable) * 100 : 0}%` }}
                  />
                </div>
              </div>
            ))}
          {computed.taxableIncome === 0 && (
            <p className="text-sm text-md-on-surface-variant">No taxable income — your deductions covered it all.</p>
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
