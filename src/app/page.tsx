'use client'

import * as React from 'react'
import { ChevronLeft, ChevronRight, FileCheck2 } from 'lucide-react'
import { useClearFile, STEPS, STEP_COUNT } from '@/lib/store'
import { HeaderBar, StepRail, MobileStepper, FooterBar } from '@/components/clearfile/shell'
import {
  WelcomeStep, StatusStep, IncomeStep, DeductionsStep, DependentsStep, PaymentsStep, ResultsStep,
} from '@/components/clearfile/steps'
import { CopilotDrawer } from '@/components/clearfile/ai-ui'
import { SettingsDialog } from '@/components/clearfile/settings'
import { Button } from '@/components/ui/button'

function Splash() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="flex flex-col items-center gap-3 text-md-on-surface-variant">
        <span className="flex size-12 items-center justify-center rounded-3xl bg-md-primary text-md-on-primary animate-pulse" aria-hidden>
          <FileCheck2 className="size-6" />
        </span>
        <p className="text-sm font-medium">ClearFile</p>
      </div>
    </div>
  )
}

export default function Home() {
  const [mounted, setMounted] = React.useState(false)
  React.useEffect(() => setMounted(true), [])

  const step = useClearFile((s) => s.step)
  const next = useClearFile((s) => s.next)
  const back = useClearFile((s) => s.back)

  if (!mounted) return <Splash />

  const steps = [
    <WelcomeStep key="welcome" />,
    <StatusStep key="status" />,
    <IncomeStep key="income" />,
    <DeductionsStep key="deductions" />,
    <DependentsStep key="dependents" />,
    <PaymentsStep key="payments" />,
    <ResultsStep key="results" />,
  ]

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <HeaderBar />
      <MobileStepper />
      <div className="flex flex-1 items-stretch">
        <StepRail />
        <main className="flex-1 min-w-0 w-full">
          <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-10 py-6 sm:py-8">
            {steps[step]}

            <div className="no-print sticky bottom-0 -mx-4 sm:-mx-6 lg:-mx-10 mt-8 px-4 sm:px-6 lg:px-10 py-3 bg-background/90 backdrop-blur border-t border-md-outline-variant/60 flex items-center justify-between z-30">
              <Button
                variant="outline"
                onClick={back}
                disabled={step === 0}
                className="rounded-full h-11 gap-1"
              >
                <ChevronLeft className="size-4" aria-hidden /> Back
              </Button>
              <span className="text-xs text-md-on-surface-variant hidden sm:block">
                Step {step + 1} of {STEP_COUNT} — {STEPS[step].title}
              </span>
              <Button onClick={next} disabled={step === STEP_COUNT - 1} className="rounded-full h-11 gap-1">
                {step === STEP_COUNT - 1 ? 'Review complete' : 'Continue'}
                {step === STEP_COUNT - 1 ? null : <ChevronRight className="size-4" aria-hidden />}
              </Button>
            </div>
          </div>
        </main>
      </div>
      <FooterBar />
      <CopilotDrawer />
      <SettingsDialog />
    </div>
  )
}
