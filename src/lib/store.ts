// SPDX-License-Identifier: GPL-3.0-only
import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { DEFAULT_YEAR } from './tax/config'
import type { DeductionMethod, FilingStatus } from './tax/config'
import type { Dependent, TaxReturnData, W2Entry } from './tax/engine'

/** New ids for store-managed list rows (D6: identity keys, not value keys). */
function freshId(prefix: string): string {
  return typeof crypto !== 'undefined' && crypto.randomUUID
    ? crypto.randomUUID()
    : `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

export const SAMPLE_FILING: TaxReturnData = {
  taxYear: DEFAULT_YEAR,
  filingStatus: 'marriedJoint',
  taxpayer65OrOlder: false,
  spouse65OrOlder: false,
  taxpayerBlind: false,
  spouseBlind: false,
  w2s: [
    { id: 'w2-1', employer: 'Acme Corp', wages: 52500, withholding: 4200 },
    { id: 'w2-2', employer: 'Star Labs', wages: 18000, withholding: 900 },
  ],
  interestIncome: 320,
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
  estimatedPayments: 500,
  dependents: [
    { id: 'dep-1', name: 'Alex Sample', age: 12, relationship: 'son', qualifyingChild: true, otherDependentCredit: false },
    { id: 'dep-2', name: 'Sam Sample', age: 9, relationship: 'daughter', qualifyingChild: true, otherDependentCredit: false },
  ],
}

type IncomeField =
  | 'interestIncome'
  | 'ordinaryDividends'
  | 'qualifiedDividends'
  | 'longTermCapitalGains'
  | 'otherIncome'
  | 'studentLoanInterest'
  | 'stateLocalIncomeOrSalesTax'
  | 'realEstateTax'
  | 'mortgageInterest'
  | 'charitableCash'
  | 'charitableNonCash'
  | 'estimatedPayments'

type FlagField = 'taxpayer65OrOlder' | 'spouse65OrOlder' | 'taxpayerBlind' | 'spouseBlind'

interface ClearFileStore extends TaxReturnData {
  step: number
  copilotOpen: boolean
  settingsOpen: boolean
  googleKey: string
  openrouterKey: string
  lastWorkingModel: string | null

  setStep: (step: number) => void
  next: () => void
  back: () => void
  setStatus: (status: FilingStatus) => void
  setFlag: (flag: FlagField, value: boolean) => void
  setDeductionMethod: (method: DeductionMethod) => void
  addW2: (w2: Omit<W2Entry, 'id'>) => void
  updateW2: (id: string, patch: Partial<Omit<W2Entry, 'id'>>) => void
  removeW2: (id: string) => void
  setIncomeField: (key: IncomeField, value: number) => void
  addDependent: () => void
  updateDependent: (id: string, patch: Partial<Omit<Dependent, 'id'>>) => void
  removeDependent: (id: string) => void
  loadFiling: (filing: TaxReturnData) => void
  resetFiling: () => void
  loadSample: () => void
  setGoogleKey: (key: string) => void
  setOpenrouterKey: (key: string) => void
  setLastWorkingModel: (model: string | null) => void
  setCopilotOpen: (open: boolean) => void
  setSettingsOpen: (open: boolean) => void
}

const baseFiling: TaxReturnData = {
  taxYear: DEFAULT_YEAR,
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

// v1 → v2 persisted-shape migration (Stage-3 parity: the store now holds the
// reference TaxReturnData model). Mapping, conservative by design:
//  - interest → interestIncome; dividends → ordinaryDividends (never marked
//    qualified — the conservative direction: a wrong ordinary assumption
//    overtaxes slightly instead of undertaxing).
//  - adjustments / itemized.medical / itemized.other have no equivalent in
//    the reference model — dropped (re-enter once, in the new fields).
//  - itemized.taxesPaid → stateLocalIncomeOrSalesTax (SALT income side);
//    itemized.charity → charitableCash.
//  - qualifyingChildren / otherDependents counts → placeholder dependents so
//    the credits survive; names are re-entered in the Dependents step.
//  - statuses renamed to the reference's JSON names ('mfj'→'marriedJoint'
//    etc.); taxYear forced to 2025 — the engine is TY2025-only now.
const STATUS_V1_TO_V2: Record<string, FilingStatus> = {
  single: 'single',
  mfj: 'marriedJoint',
  mfs: 'marriedSeparate',
  hoh: 'headOfHousehold',
  marriedJoint: 'marriedJoint',
  marriedSeparate: 'marriedSeparate',
  headOfHousehold: 'headOfHousehold',
  survivingSpouse: 'survivingSpouse',
}

function migrateV1ToFilingShape(s: Record<string, unknown>): Record<string, unknown> {
  const o: Record<string, unknown> = { ...s }
  const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0)
  const int = (v: unknown): number => Math.max(0, Math.round(num(v)))

  o.status = STATUS_V1_TO_V2[String(o.status)] ?? 'single'
  o.taxYear = 2025

  if (Array.isArray(o.w2s)) {
    o.w2s = o.w2s
      .filter((w): w is Record<string, unknown> => !!w && typeof w === 'object')
      .map((w) => ({
        id: typeof w.id === 'string' ? w.id : undefined,
        employer: typeof w.employer === 'string' ? w.employer : '',
        wages: num(w.wages),
        withholding: num(w.federalWithheld),
      }))
  } else {
    delete o.w2s
  }

  o.interestIncome = num(o.interest)
  o.ordinaryDividends = num(o.dividends)
  delete o.interest
  delete o.dividends
  delete o.adjustments

  const item = o.itemized && typeof o.itemized === 'object' && !Array.isArray(o.itemized)
    ? (o.itemized as Record<string, unknown>)
    : {}
  o.stateLocalIncomeOrSalesTax = num(item.taxesPaid)
  o.mortgageInterest = num(item.mortgageInterest)
  o.charitableCash = num(item.charity)
  o.realEstateTax = 0
  o.charitableNonCash = 0
  delete o.itemized

  const kids = int(o.qualifyingChildren)
  const otherDeps = int(o.otherDependents)
  delete o.qualifyingChildren
  delete o.otherDependents
  const placeholders: Dependent[] = []
  for (let i = 0; i < kids; i++) placeholders.push({ name: '', age: 0, relationship: '', qualifyingChild: true, otherDependentCredit: false })
  for (let i = 0; i < otherDeps; i++) placeholders.push({ name: '', age: 0, relationship: '', qualifyingChild: false, otherDependentCredit: true })
  o.dependents = placeholders

  o.taxpayer65OrOlder = false
  o.spouse65OrOlder = false
  o.taxpayerBlind = false
  o.spouseBlind = false
  o.studentLoanInterest = 0
  o.qualifiedDividends = 0
  o.longTermCapitalGains = 0
  o.deductionMethod = 'auto'
  return o
}

export const useClearFile = create<ClearFileStore>()(
  persist(
    (set) => ({
      ...baseFiling,
      step: 0,
      copilotOpen: false,
      settingsOpen: false,
      googleKey: '',
      openrouterKey: '',
      lastWorkingModel: null,

      setStep: (step) => set({ step: Math.max(0, Math.min(STEP_COUNT - 1, step)) }),
      next: () => set((s) => ({ step: Math.min(STEP_COUNT - 1, s.step + 1) })),
      back: () => set((s) => ({ step: Math.max(0, s.step - 1) })),

      setStatus: (filingStatus) => set({ filingStatus }),
      setFlag: (flag, value) => set({ [flag]: value } as Partial<ClearFileStore>),
      setDeductionMethod: (deductionMethod) => set({ deductionMethod }),

      addW2: (w2) =>
        set((s) => ({ w2s: [...s.w2s, { ...w2, id: freshId('w2') }] })),
      updateW2: (id, patch) =>
        set((s) => ({ w2s: s.w2s.map((w) => (w.id === id ? { ...w, ...patch } : w)) })),
      removeW2: (id) => set((s) => ({ w2s: s.w2s.filter((w) => w.id !== id) })),

      setIncomeField: (key, value) => set({ [key]: value } as Partial<ClearFileStore>),

      addDependent: () =>
        set((s) => ({
          dependents: [
            ...s.dependents,
            { id: freshId('dep'), name: '', age: 0, relationship: '', qualifyingChild: false, otherDependentCredit: false },
          ],
        })),
      updateDependent: (id, patch) =>
        set((s) => ({ dependents: s.dependents.map((d) => (d.id === id ? { ...d, ...patch } : d)) })),
      removeDependent: (id) => set((s) => ({ dependents: s.dependents.filter((d) => d.id !== id) })),

      loadFiling: (filing) =>
        set({
          ...baseFiling,
          ...filing,
          w2s: filing.w2s ?? [],
          dependents: filing.dependents ?? [],
          step: 1,
        }),
      resetFiling: () => set({ ...baseFiling, step: 0 }),
      loadSample: () => set({ ...SAMPLE_FILING, step: 1 }),

      setGoogleKey: (googleKey) => set({ googleKey }),
      setOpenrouterKey: (openrouterKey) => set({ openrouterKey }),
      setLastWorkingModel: (lastWorkingModel) => set({ lastWorkingModel }),
      setCopilotOpen: (copilotOpen) => set({ copilotOpen }),
      setSettingsOpen: (settingsOpen) => set({ settingsOpen }),
    }),
    {
      // Same storage key, version bumped to 2: v1 persisted state is
      // migrated (see migrateV1ToFilingShape) instead of orphaned.
      name: 'clearfile-store-v1',
      version: 2,
      migrate: (persisted, version) => {
        const s = (persisted ?? {}) as Record<string, unknown>
        if (typeof s !== 'object' || s === null) {
          return undefined as unknown as ClearFileStore
        }
        if (version < 2) {
          return migrateV1ToFilingShape(s) as unknown as ClearFileStore
        }
        // Persisted state is untrusted input (any browser profile could hold
        // a hand-edited or corrupted blob), so container fields are shape-
        // checked (ADV-ENG Stage-0 #6 / Stage-1 finding 4): array fields
        // must be arrays of objects; wrong-typed fields are dropped and
        // zustand's defaults fill the gap on merge.
        for (const key of ['w2s', 'dependents']) {
          const v = s[key]
          if (v !== undefined && !Array.isArray(v)) delete s[key]
        }
        if (Array.isArray(s.w2s)) {
          s.w2s = s.w2s.filter((w): w is Record<string, unknown> => !!w && typeof w === 'object')
        }
        if (Array.isArray(s.dependents)) {
          s.dependents = s.dependents.filter((d): d is Record<string, unknown> => !!d && typeof d === 'object')
        }
        // Unknown fields are preserved for forward migrations; zustand merges
        // the result over defaults, so absent fields are safe.
        return s as unknown as ClearFileStore
      },
      partialize: (s) => ({
        taxYear: s.taxYear,
        filingStatus: s.filingStatus,
        taxpayer65OrOlder: s.taxpayer65OrOlder,
        spouse65OrOlder: s.spouse65OrOlder,
        taxpayerBlind: s.taxpayerBlind,
        spouseBlind: s.spouseBlind,
        w2s: s.w2s,
        interestIncome: s.interestIncome,
        ordinaryDividends: s.ordinaryDividends,
        qualifiedDividends: s.qualifiedDividends,
        longTermCapitalGains: s.longTermCapitalGains,
        otherIncome: s.otherIncome,
        studentLoanInterest: s.studentLoanInterest,
        deductionMethod: s.deductionMethod,
        stateLocalIncomeOrSalesTax: s.stateLocalIncomeOrSalesTax,
        realEstateTax: s.realEstateTax,
        mortgageInterest: s.mortgageInterest,
        charitableCash: s.charitableCash,
        charitableNonCash: s.charitableNonCash,
        estimatedPayments: s.estimatedPayments,
        dependents: s.dependents,
        step: s.step,
        googleKey: s.googleKey,
        openrouterKey: s.openrouterKey,
        lastWorkingModel: s.lastWorkingModel,
      }),
    }
  )
)

export const STEP_COUNT = 7

export const STEPS = [
  { id: 'welcome', title: 'Welcome' },
  { id: 'status', title: 'Filing status' },
  { id: 'income', title: 'Income' },
  { id: 'deductions', title: 'Deductions' },
  { id: 'dependents', title: 'Dependents' },
  { id: 'payments', title: 'Payments' },
  { id: 'results', title: 'Review & results' },
] as const

export function filingFromStore(s: ClearFileStore): TaxReturnData {
  return {
    taxYear: s.taxYear,
    filingStatus: s.filingStatus,
    taxpayer65OrOlder: s.taxpayer65OrOlder,
    spouse65OrOlder: s.spouse65OrOlder,
    taxpayerBlind: s.taxpayerBlind,
    spouseBlind: s.spouseBlind,
    w2s: s.w2s,
    interestIncome: s.interestIncome,
    ordinaryDividends: s.ordinaryDividends,
    qualifiedDividends: s.qualifiedDividends,
    longTermCapitalGains: s.longTermCapitalGains,
    otherIncome: s.otherIncome,
    studentLoanInterest: s.studentLoanInterest,
    deductionMethod: s.deductionMethod,
    stateLocalIncomeOrSalesTax: s.stateLocalIncomeOrSalesTax,
    realEstateTax: s.realEstateTax,
    mortgageInterest: s.mortgageInterest,
    charitableCash: s.charitableCash,
    charitableNonCash: s.charitableNonCash,
    estimatedPayments: s.estimatedPayments,
    dependents: s.dependents,
  }
}
