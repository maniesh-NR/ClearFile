# fixtures/ai/ — synthetic AI provider fixtures (Stage-5 hardening)

Provenance: **synthetic — constructed by hand, no live capture.** Every body
in this directory was written from the providers' **documented public
formats** (Google Generative Language API `generateContent` response/error
objects; OpenRouter `chat/completions` response/error objects). No provider
was called while authoring them, no real key or quota state is recorded, and
no third-party text is copied beyond the error-message phrasing the
providers publish. The hostile fixture's injected instructions are our own
text simulating a compromised upstream; the attacker URL is an RFC 2606
reserved `.example` host and unreachable by construction.

These files exist so the AI cascade and the prompt-injection hardening can
be exercised in CI **offline**: `scripts/ai_cascade_fixture_test.mjs` and
`scripts/ai_injection_test.mjs` stub `globalThis.fetch` and replay
`JSON.stringify(body)` as the raw response text for the matching
(provider, model) request — nothing here ever touches the network.

## Schema (per file)

```json
{
  "name": "...",                                  // human-readable label
  "provider": "google" | "openrouter",
  "status": 200 | 429 | 401 | 400 | 402 | 503,
  "headers": { ... },                             // replayed response headers (subset)
  "body": { ... raw provider JSON body ... },
  "expect": {
    "kind": "rateLimit" | "quota" | "auth" | "modelNotFound" | "network" | "server" | "other" | "success",
    "shortReason": "..."                          // why the ladder maps it that way
  }
}
```

`expect.kind` is provider-agnostic semantics; the tests map it onto the
ladder's `ErrorKind` vocabulary:

| fixture kind    | ladder `ErrorKind` | note                                                  |
| --------------- | ------------------ | ----------------------------------------------------- |
| `rateLimit`     | `rate-limit`       | HTTP 429                                              |
| `quota`         | `auth`             | HTTP 402 classifies as auth ("credits or daily free allowance exhausted") |
| `auth`          | `auth`             | HTTP 401/403 (also plain 400: usually an invalid key) |
| `modelNotFound` | `not-found`        | HTTP 404 (withdrawn model id)                         |
| `network`       | `network`          | fetch-level failure (not replayable as HTTP)          |
| `server`        | `other`            | generic HTTP fallthrough (e.g. 503)                   |
| `other`         | `other`            | incl. the 400 geo-block branch (fixed message, no snippet) |
| `success`       | —                  | attempt `ok: true`, ladder stops                      |

## Inventory (exactly 8)

| file                                 | status | kind      |
| ------------------------------------ | ------ | --------- |
| `google_200_success.json`            | 200    | `success` |
| `google_429_quota.json`              | 429    | `rateLimit` |
| `google_401_invalid_key.json`        | 401    | `auth`    |
| `google_400_geo_block.json`          | 400    | `other`   |
| `openrouter_200_success.json`        | 200    | `success` |
| `openrouter_402_free_exhausted.json` | 402    | `quota`   |
| `openrouter_503.json`                | 503    | `server`  |
| `hostile_error_429.json`             | 429    | `rateLimit` |

## Authoring discipline

Mirrors `fixtures/tax/README.md`: never derive a fixture from a live run;
keep bodies faithful to the providers' documented shapes; if a provider's
documented format changes, update the fixture to the new documented shape
and note it here. All files are JSON text (the CI no-binary-blob assertion
applies).

## Dart-side classification note (2026-11-25)

The `expect.kind` column above records the WEB ladder's classification.
The Dart cascade deliberately sniffs the quota wording inside 429 bodies
(`AiFailureKind.quota` — the cascade treats it exactly like rate limiting),
so `google_429_quota.json` surfaces as `quota` on the Dart side and
`rate-limit` on the web side. Both runners assert their own side's truth;
the difference is recorded here so it never reads as drift.

## Plain-400 classification note (2026-11-26 gate, ADV-ENG)

The Dart classifier also sniffs 400 bodies (`api key`/`api_key` -> auth,
`quota` -> quota, else other — `providers.dart`), while the web ladder maps
any plain 400 flat to `auth` (`ladder.ts`). Both step down; the recorded
difference is the same class as the 429 note above. The geo-block fixture
(`google_400_geo_block.json`) pins the shared `other`/fall-through behavior
for the location-not-supported 400 on both sides.
