import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { DEFAULT_YEAR } from './tax/config'
import type { FilingData, Itemized, W2 } from './tax/engine'

const emptyItemized: Itemized = {
  medical: 0,
  taxesPaid: 0,
  mortgageInterest: 0,
  charity: 0,
  other: 0,
}

export const SAMPLE_FILING: FilingData = {
  taxYear: DEFAULT_YEAR,
  status: 'mfj',
  w2s: [
    { id: 'w2-1', employer: 'Acme Corp', wages: 52500, federalWithheld: 4200 },
    { id: 'w2-2', employer: 'Star Labs', wages: 18000, federalWithheld: 900 },
  ],
  interest: 320,
  dividends: 210,
  otherIncome: 0,
  adjustments: 0,
  itemized: { ...emptyItemized },
  qualifyingChildren: 2,
  otherDependents: 0,
  estimatedPayments: 500,
}

interface ClearFileStore extends FilingData {
  step: number
  copilotOpen: boolean
  settingsOpen: boolean
  googleKey: string
  mistralKey: string
  lastWorkingModel: string | null

  setStep: (step: number) => void
  next: () => void
  back: () => void
  setYear: (year: 2025 | 2026) => void
  setStatus: (status: FilingData['status']) => void
  addW2: (w2: Omit<W2, 'id'>) => void
  updateW2: (id: string, patch: Partial<Omit<W2, 'id'>>) => void
  removeW2: (id: string) => void
  setIncomeField: (key: 'interest' | 'dividends' | 'otherIncome' | 'adjustments' | 'estimatedPayments', value: number) => void
  setDependentField: (key: 'qualifyingChildren' | 'otherDependents', value: number) => void
  setItemizedField: (key: keyof Itemized, value: number) => void
  loadFiling: (filing: FilingData) => void
  resetFiling: () => void
  loadSample: () => void
  setGoogleKey: (key: string) => void
  setMistralKey: (key: string) => void
  setLastWorkingModel: (model: string | null) => void
  setCopilotOpen: (open: boolean) => void
  setSettingsOpen: (open: boolean) => void
}

const baseFiling: FilingData = {
  taxYear: DEFAULT_YEAR,
  status: 'single',
  w2s: [],
  interest: 0,
  dividends: 0,
  otherIncome: 0,
  adjustments: 0,
  itemized: { ...emptyItemized },
  qualifyingChildren: 0,
  otherDependents: 0,
  estimatedPayments: 0,
}

export const useClearFile = create<ClearFileStore>()(
  persist(
    (set) => ({
      ...baseFiling,
      step: 0,
      copilotOpen: false,
      settingsOpen: false,
      googleKey: '',
      mistralKey: '',
      lastWorkingModel: null,

      setStep: (step) => set({ step: Math.max(0, Math.min(STEP_COUNT - 1, step)) }),
      next: () => set((s) => ({ step: Math.min(STEP_COUNT - 1, s.step + 1) })),
      back: () => set((s) => ({ step: Math.max(0, s.step - 1) })),

      setYear: (taxYear) => set({ taxYear }),
      setStatus: (status) => set({ status }),
      addW2: (w2) =>
        set((s) => ({
          w2s: [...s.w2s, { ...w2, id: typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : `w2-${Date.now()}-${Math.random().toString(36).slice(2, 8)}` }],
        })),
      updateW2: (id, patch) =>
        set((s) => ({ w2s: s.w2s.map((w) => (w.id === id ? { ...w, ...patch } : w)) })),
      removeW2: (id) => set((s) => ({ w2s: s.w2s.filter((w) => w.id !== id) })),

      setIncomeField: (key, value) => set({ [key]: value } as Partial<ClearFileStore>),
      setDependentField: (key, value) => set({ [key]: Math.max(0, Math.round(value || 0)) } as Partial<ClearFileStore>),
      setItemizedField: (key, value) =>
        set((s) => ({ itemized: { ...s.itemized, [key]: value } })),

      loadFiling: (filing) =>
        set({
          ...baseFiling,
          ...filing,
          itemized: { ...emptyItemized, ...filing.itemized },
          w2s: filing.w2s ?? [],
          step: 1,
        }),
      resetFiling: () => set({ ...baseFiling, step: 0 }),
      loadSample: () => set({ ...SAMPLE_FILING, step: 1 }),

      setGoogleKey: (googleKey) => set({ googleKey }),
      setMistralKey: (mistralKey) => set({ mistralKey }),
      setLastWorkingModel: (lastWorkingModel) => set({ lastWorkingModel }),
      setCopilotOpen: (copilotOpen) => set({ copilotOpen }),
      setSettingsOpen: (settingsOpen) => set({ settingsOpen }),
    }),
    {
      name: 'clearfile-store-v1',
      partialize: (s) => ({
        taxYear: s.taxYear,
        status: s.status,
        w2s: s.w2s,
        interest: s.interest,
        dividends: s.dividends,
        otherIncome: s.otherIncome,
        adjustments: s.adjustments,
        itemized: s.itemized,
        qualifyingChildren: s.qualifyingChildren,
        otherDependents: s.otherDependents,
        estimatedPayments: s.estimatedPayments,
        step: s.step,
        googleKey: s.googleKey,
        mistralKey: s.mistralKey,
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

export function filingFromStore(s: ClearFileStore): FilingData {
  return {
    taxYear: s.taxYear,
    status: s.status,
    w2s: s.w2s,
    interest: s.interest,
    dividends: s.dividends,
    otherIncome: s.otherIncome,
    adjustments: s.adjustments,
    itemized: s.itemized,
    qualifyingChildren: s.qualifyingChildren,
    otherDependents: s.otherDependents,
    estimatedPayments: s.estimatedPayments,
  }
}
