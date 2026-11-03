'use client'

import * as React from 'react'
import {
  Save, FileUp, FileDown, FileSearch, Archive, RotateCcw, ChevronDown, TriangleAlert,
} from 'lucide-react'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { useToast } from '@/hooks/use-toast'
import { useClearFile, filingFromStore } from '@/lib/store'
import { YEARS } from '@/lib/tax/config'
import { compute } from '@/lib/tax/engine'
import { serializeCfr, parseCfr, downloadText, downloadBytes, CfrParseError } from '@/lib/files/cfr'
import { exportTxf } from '@/lib/files/txf'
import { analyzeTaxFile, exportTaxContainer, type TaxAnalysis } from '@/lib/files/taxfile'

export function FileMenu() {
  const { toast } = useToast()
  const resetFiling = useClearFile((s) => s.resetFiling)
  const loadFiling = useClearFile((s) => s.loadFiling)

  const cfrInputRef = React.useRef<HTMLInputElement>(null)
  const taxInputRef = React.useRef<HTMLInputElement>(null)
  const [analysis, setAnalysis] = React.useState<TaxAnalysis | null>(null)
  const [analysisOpen, setAnalysisOpen] = React.useState(false)
  const [resetOpen, setResetOpen] = React.useState(false)

  function snapshot() {
    const s = useClearFile.getState()
    return { filing: filingFromStore(s), year: s.taxYear }
  }

  function saveReturn() {
    const { filing, year } = snapshot()
    downloadText(`clearfile-${year}-return.cfr`, serializeCfr(filing))
    toast({ title: 'Return saved', description: `clearfile-${year}-return.cfr — open JSON format (.cfr)` })
  }

  async function openCfr(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    try {
      const text = await file.text()
      const { filing, warnings } = parseCfr(text)
      loadFiling(filing)
      toast({
        title: 'Return opened',
        description: warnings.length ? `${warnings.length} field${warnings.length === 1 ? '' : 's'} reset to defaults: ${warnings[0]}` : `${filing.w2s.length} W-2 form(s) loaded.`,
      })
    } catch (err) {
      toast({
        title: 'Could not open file',
        description: err instanceof CfrParseError ? err.message : 'Unexpected file contents.',
        variant: 'destructive',
      })
    }
  }

  function exportTxfAction() {
    const { filing } = snapshot()
    const computed = compute(filing, YEARS[filing.taxYear])
    downloadText(`clearfile-${filing.taxYear}.txf`, exportTxf(filing, computed), 'application/octet-stream')
    toast({
      title: 'TXF exported',
      description: 'Wages and federal withholding only (demo scope). Verify after importing into the receiving software.',
    })
  }

  function exportTaxAction() {
    const { filing, year } = snapshot()
    downloadBytes(`clearfile-${year}-exchange.tax`, exportTaxContainer(filing))
    toast({
      title: '.tax container exported (experimental)',
      description: 'Open ZIP container using the .tax extension — not Intuit format. Re-importable here.',
    })
  }

  async function analyzeTax(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return
    const buf = new Uint8Array(await file.arrayBuffer())
    setAnalysis(analyzeTaxFile(buf))
    setAnalysisOpen(true)
  }

  function importFromAnalysis() {
    if (analysis?.filing) {
      loadFiling(analysis.filing)
      setAnalysisOpen(false)
      toast({ title: 'Return imported', description: 'Loaded from the ClearFile exchange container.' })
    }
  }

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="outline" className="rounded-full h-9 sm:h-10 gap-1.5">
            File <ChevronDown className="size-3.5 hidden sm:block" aria-hidden />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="rounded-2xl w-64">
          <DropdownMenuLabel>Return file</DropdownMenuLabel>
          <DropdownMenuItem onClick={saveReturn}>
            <Save className="size-4" aria-hidden /> Save return (.cfr)
          </DropdownMenuItem>
          <DropdownMenuItem onClick={() => cfrInputRef.current?.click()}>
            <FileUp className="size-4" aria-hidden /> Open return…
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuLabel>Export</DropdownMenuLabel>
          <DropdownMenuItem onClick={exportTxfAction}>
            <FileDown className="size-4" aria-hidden /> TXF (tax exchange)
          </DropdownMenuItem>
          <DropdownMenuItem onClick={exportTaxAction}>
            <Archive className="size-4" aria-hidden /> .tax container (experimental)
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuLabel>Experimental</DropdownMenuLabel>
          <DropdownMenuItem onClick={() => taxInputRef.current?.click()}>
            <FileSearch className="size-4" aria-hidden /> Analyze a .tax file…
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => setResetOpen(true)} className="text-md-error focus:text-md-error">
            <RotateCcw className="size-4" aria-hidden /> Start over (clear all)
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <input
        ref={cfrInputRef}
        type="file"
        accept=".cfr,application/json,.json"
        className="hidden"
        onChange={(e) => void openCfr(e)}
        aria-hidden
      />
      <input
        ref={taxInputRef}
        type="file"
        accept=".tax,.tax2026,.tax2025,.tax2024,application/octet-stream"
        className="hidden"
        onChange={(e) => void analyzeTax(e)}
        aria-hidden
      />

      <Dialog open={analysisOpen} onOpenChange={setAnalysisOpen}>
        <DialogContent className="max-w-xl rounded-3xl max-h-[80vh] overflow-y-auto scrollbar-slim">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <FileSearch className="size-5 text-md-primary" aria-hidden /> .tax file analysis
            </DialogTitle>
            <DialogDescription>
              Best-effort inspection. Intuit&apos;s .tax internals are undocumented — see the engineering blueprint for
              the reverse-engineering workstream that would enable true import.
            </DialogDescription>
          </DialogHeader>
          {analysis && (
            <div className="space-y-4 text-sm">
              <p>{analysis.summary}</p>
              {analysis.clearfileContainer && (
                <Button onClick={importFromAnalysis} className="rounded-full h-10">
                  Import this return
                </Button>
              )}
              {analysis.entries.length > 0 && (
                <div className="rounded-2xl border border-md-outline-variant overflow-hidden">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="bg-md-surface-1 text-left text-md-on-surface-variant">
                        <th className="px-3 py-2 font-medium">Entry</th>
                        <th className="px-3 py-2 font-medium">Size</th>
                        <th className="px-3 py-2 font-medium">Type</th>
                      </tr>
                    </thead>
                    <tbody>
                      {analysis.entries.map((en, i) => (
                        <tr key={i} className="border-t border-md-outline-variant/60 align-top">
                          <td className="px-3 py-2 font-mono break-all">{en.name}</td>
                          <td className="px-3 py-2 whitespace-nowrap">{en.size.toLocaleString()} B</td>
                          <td className="px-3 py-2">
                            <Badge variant="outline" className="rounded-full font-normal">
                              {en.preview ? 'stored / readable' : 'stored'}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
              {analysis.entries.some((en) => en.preview) && (
                <div className="space-y-2">
                  {analysis.entries
                    .filter((en) => en.preview)
                    .slice(0, 3)
                    .map((en, i) => (
                      <div key={i} className="rounded-2xl bg-md-surface-1 p-3">
                        <p className="font-mono text-xs font-semibold mb-1 break-all">{en.name}</p>
                        <pre className="font-mono text-[11px] leading-relaxed whitespace-pre-wrap break-all max-h-32 overflow-y-auto scrollbar-slim text-md-on-surface-variant">
                          {en.preview}
                        </pre>
                      </div>
                    ))}
                </div>
              )}
              {analysis.warnings.length > 0 && (
                <div className="rounded-2xl bg-md-surface-1 p-3 space-y-1">
                  {analysis.warnings.map((w, i) => (
                    <p key={i} className="text-xs text-md-on-surface-variant flex gap-1.5">
                      <TriangleAlert className="size-3.5 shrink-0 mt-0.5 text-md-tertiary" aria-hidden /> {w}
                    </p>
                  ))}
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>

      <AlertDialog open={resetOpen} onOpenChange={setResetOpen}>
        <AlertDialogContent className="rounded-3xl">
          <AlertDialogHeader>
            <AlertDialogTitle>Clear this return and start over?</AlertDialogTitle>
            <AlertDialogDescription>
              Every entry in the current interview will be removed (your AI keys in Settings are kept). Save a .cfr file
              first if you want a copy.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel className="rounded-full">Keep my return</AlertDialogCancel>
            <AlertDialogAction
              className="rounded-full bg-md-error text-md-on-error hover:bg-md-error/90"
              onClick={() => {
                resetFiling()
                toast({ title: 'Return cleared', description: 'The interview was reset. AI keys are untouched.' })
              }}
            >
              Clear everything
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
