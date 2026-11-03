/**
 * ClearFile AI — provider ladder with automatic step-down.
 *
 * Strategy (per product spec): always try the highest-performance free model
 * first; on inaccessibility or rate limits, step down to the next model.
 * Google AI Studio keys (Gemini family) and OpenRouter keys are supplied by
 * the user and stored locally in their browser only. Calls go directly from
 * the browser to the provider endpoint — no intermediate server. Both
 * endpoints send CORS headers, so browser-direct calls work.
 *
 * OpenRouter rungs use the free-tier lineup verified on 2026-11-03. Mistral
 * La Plateforme left this ladder when its free direct-inference tier ended
 * (2026-09-21); OpenRouter's free models now cover the fallback rungs. Free
 * lineups rotate often, so a withdrawn (404) or upstream-rate-limited (429)
 * model simply steps down to the next rung.
 *
 * The Google rungs were rebaselined the same day: Google retired the
 * Gemini 2.5 family for new users (the API's own error messages name the
 * successors), so the ladder now carries Gemini 3.1 Pro, 3.8 Flash, and
 * 3.5 Flash-Lite. All three model ids were confirmed live; generation from
 * the test environment is geo-restricted, so rung verification there was
 * structural (authentication + model existence + error classification).
 */

export type Provider = 'google' | 'openrouter'

export interface ModelSpec {
  id: string
  label: string
  provider: Provider
  rank: number // 1 = highest performance
  note: string
}

export const LADDER: ModelSpec[] = [
  { id: 'gemini-3.1-pro-preview', label: 'Gemini 3.1 Pro', provider: 'google', rank: 1, note: 'Flagship preview tier; the tightest free quota on the ladder.' },
  { id: 'gemini-3.8-flash', label: 'Gemini 3.8 Flash', provider: 'google', rank: 2, note: 'Newest Flash generation (successor to 2.5 Flash); balanced speed and reasoning.' },
  { id: 'gemini-3.5-flash-lite', label: 'Gemini 3.5 Flash-Lite', provider: 'google', rank: 3, note: 'Fastest, most permissive Google tier (successor to 2.5 Flash-Lite).' },
  {
    id: 'nvidia/nemotron-3.5-super-vl:free',
    label: 'Nemotron 3.5 Super VL',
    provider: 'openrouter',
    rank: 4,
    note: 'Newest Nemotron generation on OpenRouter free tier: sub-second replies, JSON-friendly, stayed strictly on provided numbers in task testing.',
  },
  {
    id: 'nvidia/nemotron-3-ultra-550b-a55b:free',
    label: 'Nemotron 3 Ultra (550B)',
    provider: 'openrouter',
    rank: 5,
    note: 'Heavyweight 550B-class fallback with a 1M-token context; slower replies.',
  },
  {
    id: 'openrouter/free',
    label: 'OpenRouter Free Router',
    provider: 'openrouter',
    rank: 6,
    note: "OpenRouter's own catch-all: routes each request to whichever free model is currently serving.",
  },
]

export type ErrorKind = 'rate-limit' | 'auth' | 'not-found' | 'network' | 'timeout' | 'other' | 'no-key'

export interface Attempt {
  model: string
  label: string
  provider: Provider
  ok: boolean
  ms: number
  text?: string
  error?: string
  errorKind?: ErrorKind
}

export class LadderError extends Error {
  attempts: Attempt[]
  noKeys: boolean
  constructor(message: string, attempts: Attempt[], noKeys = false) {
    super(message)
    this.name = 'LadderError'
    this.attempts = attempts
    this.noKeys = noKeys
  }
}

export const ERROR_KIND_LABEL: Record<ErrorKind, string> = {
  'rate-limit': 'Rate limit reached',
  auth: 'Key rejected or quota exceeded',
  'not-found': 'Model unavailable',
  network: 'Unreachable from browser (network/CORS)',
  timeout: 'Timed out',
  other: 'Provider error',
  'no-key': 'No key configured',
}

export interface LadderKeys {
  googleKey?: string
  openrouterKey?: string
}

export interface LadderSuccess {
  text: string
  model: string
  label: string
  ms: number
  attempts: Attempt[]
}

interface CallOptions {
  temperature?: number
  maxTokens?: number
  timeoutMs?: number
}

async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs: number): Promise<Response> {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), timeoutMs)
  try {
    return await fetch(url, { ...init, signal: controller.signal })
  } finally {
    clearTimeout(timer)
  }
}

function classifyHttpError(status: number, bodyText: string): { kind: ErrorKind; message: string } {
  const snippet = bodyText.slice(0, 200)
  if (status === 429) return { kind: 'rate-limit', message: `HTTP 429 — ${snippet}` }
  if (status === 401 || status === 403) return { kind: 'auth', message: `HTTP ${status} — ${snippet}` }
  if (status === 402) return { kind: 'auth', message: `HTTP 402 — credits or daily free allowance exhausted — ${snippet}` }
  if (status === 404) return { kind: 'not-found', message: `HTTP 404 — model id not available for this key — ${snippet}` }
  if (status === 400 && /location is not supported/i.test(bodyText)) {
    return {
      kind: 'other',
      message: 'HTTP 400 — API use is not supported from this network region; the key itself may be fine',
    }
  }
  if (status === 400) return { kind: 'auth', message: `HTTP 400 — usually an invalid key or malformed quota — ${snippet}` }
  return { kind: 'other', message: `HTTP ${status} — ${snippet}` }
}

function classifyFetchError(err: unknown): { kind: ErrorKind; message: string } {
  if (err instanceof DOMException && err.name === 'AbortError') {
    return { kind: 'timeout', message: 'Request timed out' }
  }
  if (err instanceof TypeError) {
    return { kind: 'network', message: 'Network or CORS failure (browser could not reach the endpoint)' }
  }
  return { kind: 'other', message: err instanceof Error ? err.message : String(err) }
}

async function callGoogle(
  modelId: string,
  key: string,
  system: string,
  user: string,
  opts: CallOptions
): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(modelId)}:generateContent`
  const res = await fetchWithTimeout(
    url,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: 'user', parts: [{ text: user }] }],
        generationConfig: {
          temperature: opts.temperature ?? 0.2,
          maxOutputTokens: opts.maxTokens ?? 1024,
        },
      }),
    },
    opts.timeoutMs ?? 45000
  )
  if (!res.ok) {
    const body = await res.text().catch(() => '')
    const { kind, message } = classifyHttpError(res.status, body)
    throw Object.assign(new Error(message), { kind })
  }
  const data: unknown = await res.json()
  const candidates = (data as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> }).candidates
  const parts = candidates?.[0]?.content?.parts
  const text = parts?.map((p) => p.text ?? '').join('').trim()
  if (!text) {
    const block = (data as { promptFeedback?: { blockReason?: string } }).promptFeedback?.blockReason
    throw Object.assign(new Error(block ? `Blocked by provider: ${block}` : 'Empty response from model'), {
      kind: 'other',
    })
  }
  return text
}

async function callOpenrouter(
  modelId: string,
  key: string,
  system: string,
  user: string,
  opts: CallOptions
): Promise<string> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${key}`,
    'X-Title': 'ClearFile',
  }
  // OpenRouter reads this custom header for app attribution; using the real
  // page origin keeps it truthful. It is optional, so non-browser callers
  // (tests, shells) can omit it.
  if (typeof window !== 'undefined') headers['HTTP-Referer'] = window.location.origin
  const res = await fetchWithTimeout(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      method: 'POST',
      headers,
      body: JSON.stringify({
        model: modelId,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
        temperature: opts.temperature ?? 0.2,
        max_tokens: opts.maxTokens ?? 1024,
        // Nemotron-family free models are reasoning models: thinking tokens
        // count against max_tokens and can starve the visible content to an
        // empty string (verified during key testing). ClearFile's tasks need
        // transcription and JSON, not deliberation, so reasoning is switched
        // off on models that support the parameter; others ignore it.
        reasoning: { enabled: false },
      }),
    },
    // The 550B Ultra rung answered the largest task in ~47 s, so OpenRouter
    // rungs get a longer default budget than the Gemini rungs.
    opts.timeoutMs ?? 90000
  )
  if (!res.ok) {
    const body = await res.text().catch(() => '')
    const { kind, message } = classifyHttpError(res.status, body)
    throw Object.assign(new Error(message), { kind })
  }
  const data: unknown = await res.json()
  const content = (data as { choices?: Array<{ message?: { content?: string } }> }).choices?.[0]?.message?.content
  if (!content || !content.trim()) {
    throw Object.assign(new Error('Empty response from model'), { kind: 'other' })
  }
  return content.trim()
}

/** Run a task through the ladder: highest performance first, step down on failure. */
export async function runLadder(
  system: string,
  user: string,
  keys: LadderKeys,
  opts: CallOptions = {}
): Promise<LadderSuccess> {
  const attempts: Attempt[] = []
  const googleKey = keys.googleKey?.trim()
  const openrouterKey = keys.openrouterKey?.trim()

  if (!googleKey && !openrouterKey) {
    throw new LadderError('No AI provider keys configured', [], true)
  }

  for (const spec of [...LADDER].sort((a, b) => a.rank - b.rank)) {
    const key = spec.provider === 'google' ? googleKey : openrouterKey
    if (!key) {
      attempts.push({
        model: spec.id,
        label: spec.label,
        provider: spec.provider,
        ok: false,
        ms: 0,
        errorKind: 'no-key',
        error: 'No key configured for this provider',
      })
      continue
    }
    const started = performance.now()
    try {
      const text =
        spec.provider === 'google'
          ? await callGoogle(spec.id, key, system, user, opts)
          : await callOpenrouter(spec.id, key, system, user, opts)
      const ms = Math.round(performance.now() - started)
      attempts.push({ model: spec.id, label: spec.label, provider: spec.provider, ok: true, ms, text })
      return { text, model: spec.id, label: spec.label, ms, attempts }
    } catch (err) {
      const ms = Math.round(performance.now() - started)
      const classified =
        err && typeof err === 'object' && 'kind' in err && typeof (err as { kind: unknown }).kind === 'string'
          ? { kind: (err as { kind: ErrorKind }).kind, message: err instanceof Error ? err.message : String(err) }
          : classifyFetchError(err)
      attempts.push({
        model: spec.id,
        label: spec.label,
        provider: spec.provider,
        ok: false,
        ms,
        error: classified.message,
        errorKind: classified.kind,
      })
    }
  }

  throw new LadderError('All models on the ladder failed', attempts)
}

/** Tiny ping used by the Settings "Test connection" button. */
export async function testLadder(keys: LadderKeys): Promise<Attempt[]> {
  try {
    const res = await runLadder(
      'You are a connectivity test. Reply with exactly: OK',
      'ping',
      keys,
      { maxTokens: 8, temperature: 0, timeoutMs: 30000 }
    )
    return res.attempts
  } catch (err) {
    if (err instanceof LadderError) return err.attempts
    throw err
  }
}
