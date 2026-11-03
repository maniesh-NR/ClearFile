'use client'

import * as React from 'react'
import { useTheme } from 'next-themes'
import {
  Moon, Sun, Sparkles, Settings2, ChevronDown, Check, FileCheck2, Users, Wallet,
  ReceiptText, Baby, Landmark, BadgeCheck, Rocket,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { STEPS, useClearFile } from '@/lib/store'
import { FileMenu } from './filemenu'
import { cn } from '@/lib/utils'

export const STEP_ICONS: Record<string, LucideIcon> = {
  welcome: Rocket,
  status: Users,
  income: Wallet,
  deductions: ReceiptText,
  dependents: Baby,
  payments: Landmark,
  results: BadgeCheck,
}

export function Logo() {
  return (
    <div className="flex items-center gap-2.5">
      <span className="flex size-9 items-center justify-center rounded-2xl bg-md-primary text-md-on-primary shadow-sm" aria-hidden>
        <FileCheck2 className="size-5" />
      </span>
      <span className="hidden sm:block leading-tight">
        <span className="block font-semibold tracking-tight">ClearFile</span>
        <span className="block text-[11px] text-md-on-surface-variant">clean-room tax assistant</span>
      </span>
      <span className="hidden lg:inline-flex items-center rounded-full border border-md-outline-variant px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide text-md-on-surface-variant">
        prototype
      </span>
    </div>
  )
}

export function HeaderBar() {
  const { resolvedTheme, setTheme } = useTheme()
  const taxYear = useClearFile((s) => s.taxYear)
  const setYear = useClearFile((s) => s.setYear)
  const googleKey = useClearFile((s) => s.googleKey)
  const mistralKey = useClearFile((s) => s.mistralKey)
  const setCopilotOpen = useClearFile((s) => s.setCopilotOpen)
  const setSettingsOpen = useClearFile((s) => s.setSettingsOpen)

  const hasKeys = Boolean(googleKey || mistralKey)
  const isDark = resolvedTheme === 'dark'

  return (
    <header className="no-print sticky top-0 z-40 border-b border-md-outline-variant/60 bg-background/85 backdrop-blur supports-[backdrop-filter]:bg-background/70">
      <div className="mx-auto flex h-16 max-w-6xl items-center gap-2 px-4 sm:px-6">
        <Logo />
        <div className="ml-auto flex items-center gap-1 sm:gap-2">
          <Select value={String(taxYear)} onValueChange={(v) => setYear(v === '2025' ? 2025 : 2026)}>
            <SelectTrigger className="h-10 rounded-full w-[4.6rem] sm:w-[5.5rem] text-sm" aria-label="Tax year">
              <SelectValue />
            </SelectTrigger>
            <SelectContent className="rounded-2xl">
              <SelectItem value="2026">TY 2026</SelectItem>
              <SelectItem value="2025">TY 2025</SelectItem>
            </SelectContent>
          </Select>
          <FileMenu />
          <Button
            variant="ghost"
            size="icon"
            className="rounded-full size-9 sm:size-10"
            onClick={() => setSettingsOpen(true)}
            aria-label="AI assistance settings"
          >
            <Settings2 className="size-4.5" aria-hidden />
          </Button>
          <Button
            variant="ghost"
            size="icon"
            className="rounded-full size-9 sm:size-10"
            onClick={() => setTheme(isDark ? 'light' : 'dark')}
            aria-label={isDark ? 'Switch to light theme' : 'Switch to dark theme'}
          >
            {isDark ? <Sun className="size-4.5" aria-hidden /> : <Moon className="size-4.5" aria-hidden />}
          </Button>
          <Button onClick={() => setCopilotOpen(true)} className="rounded-full h-9 sm:h-10 gap-1.5 px-3.5 sm:px-4">
            <Sparkles className="size-4" aria-hidden /> <span className="hidden sm:inline">Copilot</span>
            {hasKeys && <span className="ml-0.5 size-1.5 rounded-full bg-md-success" aria-hidden />}
          </Button>
        </div>
      </div>
    </header>
  )
}

export function StepRail() {
  const step = useClearFile((s) => s.step)
  const setStep = useClearFile((s) => s.setStep)

  return (
    <nav
      aria-label="Interview sections"
      className="no-print hidden lg:flex sticky top-16 h-[calc(100vh-4rem)] w-60 shrink-0 flex-col gap-1 overflow-y-auto scrollbar-slim border-r border-md-outline-variant/60 px-3 py-4"
    >
      {STEPS.map((s, i) => {
        const state = i < step ? 'done' : i === step ? 'current' : 'todo'
        const Icon = STEP_ICONS[s.id] ?? FileCheck2
        return (
          <button
            key={s.id}
            type="button"
            onClick={() => setStep(i)}
            aria-current={state === 'current' ? 'step' : undefined}
            className={cn(
              'flex items-center gap-3 rounded-full px-3.5 py-2.5 text-left text-sm transition-colors',
              state === 'current' && 'bg-md-secondary-container text-md-on-secondary-container font-semibold',
              state === 'done' && 'text-md-primary hover:bg-md-surface-1',
              state === 'todo' && 'text-md-on-surface-variant hover:bg-md-surface-1'
            )}
          >
            <span
              className={cn(
                'flex size-7 shrink-0 items-center justify-center rounded-full border text-xs font-semibold',
                state === 'current' && 'border-md-primary bg-md-primary text-md-on-primary',
                state === 'done' && 'border-md-primary text-md-primary',
                state === 'todo' && 'border-md-outline-variant text-md-on-surface-variant'
              )}
            >
              {state === 'done' ? <Check className="size-3.5" aria-hidden /> : i + 1}
            </span>
            <span className="flex items-center gap-2 truncate">
              <Icon className="size-4 shrink-0 opacity-70" aria-hidden />
              {s.title}
            </span>
          </button>
        )
      })}
      <p className="mt-auto px-3.5 py-3 text-[11px] leading-relaxed text-md-on-surface-variant">
        Your data stays in this browser. Nothing is uploaded — AI requests go directly to the provider you configure.
      </p>
    </nav>
  )
}

export function MobileStepper() {
  const step = useClearFile((s) => s.step)
  const setStep = useClearFile((s) => s.setStep)
  return (
    <div
      role="navigation"
      aria-label="Interview sections"
      className="no-print lg:hidden flex gap-1.5 overflow-x-auto scrollbar-slim border-b border-md-outline-variant/60 px-4 py-2"
    >
      {STEPS.map((s, i) => {
        const state = i < step ? 'done' : i === step ? 'current' : 'todo'
        return (
          <button
            key={s.id}
            type="button"
            onClick={() => setStep(i)}
            aria-current={state === 'current' ? 'step' : undefined}
            className={cn(
              'flex shrink-0 items-center gap-1.5 rounded-full px-3 py-1.5 text-xs transition-colors',
              state === 'current' && 'bg-md-primary text-md-on-primary font-semibold',
              state === 'done' && 'text-md-primary border border-md-outline-variant',
              state === 'todo' && 'text-md-on-surface-variant border border-md-outline-variant/60'
            )}
          >
            {state === 'done' ? <Check className="size-3" aria-hidden /> : <span className="font-semibold">{i + 1}</span>}
            {s.title}
          </button>
        )
      })}
    </div>
  )
}

export function FooterBar() {
  const taxYear = useClearFile((s) => s.taxYear)
  return (
    <footer className="no-print mt-auto border-t border-md-outline-variant/60 bg-md-surface-1/50">
      <div className="mx-auto flex max-w-6xl flex-col gap-1 px-4 sm:px-6 py-3 text-[11px] leading-relaxed text-md-on-surface-variant sm:flex-row sm:items-center sm:justify-between">
        <p>
          ClearFile prototype — demo calculations only. Not IRS-approved software; do not use it to file a real return.
        </p>
        <p className="sm:text-right">
          TY{taxYear} engine parameters from IRS Rev. Proc. 2025-32 / OBBBA · open .cfr format · MD3 UI
        </p>
      </div>
    </footer>
  )
}
