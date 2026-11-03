'use client'

import * as React from 'react'
import {
  KeyRound, Eye, EyeOff, ExternalLink, Loader2, ShieldCheck, Trash2, Sparkles, CheckCircle2, XCircle,
} from 'lucide-react'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'
import { useClearFile } from '@/lib/store'
import { LADDER, ERROR_KIND_LABEL, testLadder, type Attempt } from '@/lib/ai/ladder'

function KeyField({
  value,
  onChange,
  placeholder,
}: {
  value: string
  onChange: (v: string) => void
  placeholder: string
}) {
  const [show, setShow] = React.useState(false)
  return (
    <div className="relative">
      <KeyRound className="absolute left-3.5 top-1/2 -translate-y-1/2 size-4 text-md-on-surface-variant" aria-hidden />
      <Input
        type={show ? 'text' : 'password'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="pl-10 pr-11 rounded-full h-11 font-mono text-sm"
        autoComplete="off"
        spellCheck={false}
      />
      <button
        type="button"
        onClick={() => setShow((s) => !s)}
        className="absolute right-3 top-1/2 -translate-y-1/2 text-md-on-surface-variant hover:text-md-on-surface"
        aria-label={show ? 'Hide key' : 'Show key'}
      >
        {show ? <EyeOff className="size-4" aria-hidden /> : <Eye className="size-4" aria-hidden />}
      </button>
    </div>
  )
}

function ProviderCard({
  title,
  subtitle,
  steps,
  link,
  linkLabel,
  keyValue,
  onKeyChange,
}: {
  title: string
  subtitle: string
  steps: string[]
  link: string
  linkLabel: string
  keyValue: string
  onKeyChange: (v: string) => void
}) {
  return (
    <Card className="rounded-3xl border-md-outline-variant bg-md-surface-1/50">
      <CardHeader className="pb-2">
        <CardTitle className="text-base flex items-center gap-2">
          {title}
          {keyValue ? (
            <Badge className="rounded-full bg-md-success-container text-md-on-success-container hover:bg-md-success-container font-normal">
              connected
            </Badge>
          ) : (
            <Badge variant="outline" className="rounded-full font-normal text-md-on-surface-variant">
              not connected
            </Badge>
          )}
        </CardTitle>
        <CardDescription>{subtitle}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        <ol className="space-y-1.5 text-sm text-md-on-surface-variant list-decimal list-inside">
          {steps.map((s, i) => (
            <li key={i}>{s}</li>
          ))}
        </ol>
        <div className="flex flex-wrap items-center gap-2">
          <Button asChild variant="outline" className="rounded-full h-10">
            <a href={link} target="_blank" rel="noreferrer">
              Get a free key — {linkLabel} <ExternalLink className="size-3.5" aria-hidden />
            </a>
          </Button>
        </div>
        <KeyField value={keyValue} onChange={onKeyChange} placeholder="Paste your API key" />
      </CardContent>
    </Card>
  )
}

export function SettingsDialog() {
  const open = useClearFile((s) => s.settingsOpen)
  const setOpen = useClearFile((s) => s.setSettingsOpen)
  const googleKey = useClearFile((s) => s.googleKey)
  const openrouterKey = useClearFile((s) => s.openrouterKey)
  const setGoogleKey = useClearFile((s) => s.setGoogleKey)
  const setOpenrouterKey = useClearFile((s) => s.setOpenrouterKey)
  const setLastWorkingModel = useClearFile((s) => s.setLastWorkingModel)
  const { toast } = useToast()

  const [testing, setTesting] = React.useState(false)
  const [attempts, setAttempts] = React.useState<Attempt[] | null>(null)

  async function runTest() {
    setTesting(true)
    setAttempts(null)
    try {
      const res = await testLadder({ googleKey, openrouterKey })
      setAttempts(res)
      const ok = res.find((a) => a.ok)
      if (ok) {
        setLastWorkingModel(ok.model)
        toast({ title: `Connected via ${ok.label}`, description: `Responded in ${ok.ms} ms. This model will be tried first.` })
      } else {
        toast({
          title: 'No model responded',
          description: 'Check your keys below — each model that failed and why is listed in the ladder table.',
          variant: 'destructive',
        })
      }
    } catch (e) {
      toast({ title: 'Test failed', description: String(e), variant: 'destructive' })
    } finally {
      setTesting(false)
    }
  }

  function statusFor(modelId: string): { label: string; ok: boolean | null } {
    const a = attempts?.find((x) => x.model === modelId)
    if (!a) return { label: 'untested', ok: null }
    if (a.ok) return { label: `responded · ${a.ms} ms`, ok: true }
    if (a.errorKind === 'no-key') return { label: 'no key', ok: false }
    return { label: a.errorKind ? ERROR_KIND_LABEL[a.errorKind] : 'failed', ok: false }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="max-w-2xl rounded-3xl max-h-[85vh] overflow-y-auto scrollbar-slim">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl">
            <Sparkles className="size-5 text-md-primary" aria-hidden /> AI assistance settings
          </DialogTitle>
          <DialogDescription>
            Bring your own free keys. The ladder always tries the highest-performance free model first and steps down
            automatically when one is rate-limited or unreachable.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <ProviderCard
            title="Google AI Studio (Gemini)"
            subtitle="Free tier with generous limits. Browser-direct calls are supported (CORS-enabled endpoint)."
            steps={[
              'Open aistudio.google.com/apikey and sign in with a Google account.',
              'Click "Create API key" (pick or create a project when asked).',
              'Copy the key — it starts with "AIza" or "AQ.".',
              'Paste it below. Free-tier rate limits apply per model.',
            ]}
            link="https://aistudio.google.com/apikey"
            linkLabel="aistudio.google.com"
            keyValue={googleKey}
            onKeyChange={setGoogleKey}
          />

          <ProviderCard
            title="OpenRouter (free models)"
            subtitle="One key reaches many providers' free models (Nemotron, Gemma, and more). Browser-direct calls are supported (CORS-enabled endpoint)."
            steps={[
              'Open openrouter.ai and create a free account (email or Google sign-in).',
              'Go to Settings → Keys and click "Create Key".',
              'Copy the key — it starts with "sk-or-v1-".',
              'Paste it below. Free models are capped at 20 requests/minute and roughly 100 requests/day (1,000/day after a one-time $10 credit purchase).',
            ]}
            link="https://openrouter.ai/settings/keys"
            linkLabel="openrouter.ai"
            keyValue={openrouterKey}
            onKeyChange={setOpenrouterKey}
          />

          <Card className="rounded-3xl border-md-outline-variant">
            <CardHeader className="pb-2">
              <CardTitle className="text-base">Model ladder (highest performance first)</CardTitle>
              <CardDescription>
                On rate limits, invalid access, or network failure, the request automatically steps down to the next
                model. The last model that answered is remembered for status display.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center gap-2">
                <Button onClick={() => void runTest()} disabled={testing} className="rounded-full h-10">
                  {testing ? <Loader2 className="size-4 animate-spin" aria-hidden /> : <Sparkles className="size-4" aria-hidden />}
                  Test connection
                </Button>
                <span className="text-xs text-md-on-surface-variant">Sends a tiny "ping" through the whole ladder.</span>
              </div>
              <div className="rounded-2xl border border-md-outline-variant overflow-hidden">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-md-surface-1 text-left text-xs text-md-on-surface-variant">
                      <th className="px-3 py-2 font-medium">Try order</th>
                      <th className="px-3 py-2 font-medium">Model</th>
                      <th className="px-3 py-2 font-medium hidden sm:table-cell">Provider</th>
                      <th className="px-3 py-2 font-medium">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {LADDER.map((m) => {
                      const st = statusFor(m.id)
                      return (
                        <tr key={m.id} className="border-t border-md-outline-variant/60">
                          <td className="px-3 py-2 text-md-on-surface-variant">#{m.rank}</td>
                          <td className="px-3 py-2 font-medium">{m.label}</td>
                          <td className="px-3 py-2 text-md-on-surface-variant capitalize hidden sm:table-cell">{m.provider}</td>
                          <td className="px-3 py-2">
                            <span className="inline-flex items-center gap-1.5 text-xs">
                              {st.ok === true ? (
                                <CheckCircle2 className="size-3.5 text-md-success" aria-hidden />
                              ) : st.ok === false ? (
                                <XCircle className="size-3.5 text-md-error" aria-hidden />
                              ) : null}
                              <span className="text-md-on-surface-variant">{st.label}</span>
                            </span>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
              <p className="text-xs text-md-on-surface-variant">
                Browser-direct mode: both Google AI Studio and OpenRouter send CORS headers, so keys work straight from
                your browser. OpenRouter&apos;s free models run on shared community capacity — an upstream rate limit
                (429) simply steps the ladder down to the next model.
              </p>
            </CardContent>
          </Card>

          <Card className="rounded-3xl border-md-outline-variant bg-md-surface-1/50">
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <ShieldCheck className="size-4 text-md-primary" aria-hidden /> Privacy
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm text-md-on-surface-variant">
              <ul className="space-y-1.5 list-disc list-inside">
                <li>Keys are stored only in this browser (localStorage) and are never sent anywhere except directly to the provider.</li>
                <li>ClearFile never collects names, SSNs, or addresses — AI requests see only the summarized return shown in the copilot.</li>
                <li>OpenRouter&apos;s free endpoints run on hosts whose terms may allow prompt training (for example NVIDIA&apos;s free-tier terms). You can restrict that in your OpenRouter privacy settings; what ClearFile sends is already de-identified.</li>
                <li>Clearing your browser data removes the keys. No telemetry exists in this prototype.</li>
              </ul>
              <div className="flex flex-wrap gap-2 pt-1">
                <Button variant="outline" className="rounded-full h-9 text-md-error" onClick={() => setGoogleKey('')}>
                  <Trash2 className="size-3.5" aria-hidden /> Clear Google key
                </Button>
                <Button variant="outline" className="rounded-full h-9 text-md-error" onClick={() => setOpenrouterKey('')}>
                  <Trash2 className="size-3.5" aria-hidden /> Clear OpenRouter key
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  )
}
