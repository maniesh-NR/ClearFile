# ClearFile

**A clean-room, demonstration US federal tax-return prototype.** ClearFile is
not IRS-authorized, cannot e-file, and must not be used to prepare a real tax
return. It exists to study — cleanly and reproducibly — what a simplified
TurboTax-class interview-and-calculation flow looks like under the hood, and
to ship that flow to every desktop and mobile platform from a single
codebase.

Licensed under [GPL-3.0](LICENSE).

---

## What is in this repository

| Path | What it is |
| --- | --- |
| `src/` | The original **Next.js 16 web prototype**: a seven-step Material 3 tax interview (status → income → deductions → dependents → payments → review → results) with a **simplified** TY2025/TY2026 calculation engine (see [Engine limitations](#engine-limitations)), deterministic review findings, and an optional bring-your-own-key AI assistant. |
| `clearfile/` | The **Flutter 3.47 app** — the full-featured implementation: the five-step interview, the complete TY2025 engine and the AI cascade, compiled to Android, iOS, macOS, Windows, Linux and Web from one Dart codebase. The two codebases share no code; the web prototype is the earlier, simplified model. |
| `clearfile/test/` | 47 Dart tests — 19 calculator, 8 AI cascade, 9 CSV import, 3 JSON roundtrip, 3 widget, 1 delete-regression, 4 privacy — that pin the engine, the UI behaviour and the AI-privacy contract. `flutter analyze` is clean and `flutter test` is green. |
| `docs/reverse-engineering-protocol.md` | The **clean-room RE playbook** for studying legacy proprietary tax-file formats (`.tax`, `.tax[YYYY]`, `.LIF`, `.FIL`, `.RCD`, `.1PE`, `.3ME`, `.3PE`, `.DGC`, `.SCD`, `.THP`, `.TVL`, `.1PH`, `.TT[YYYY]STATE`). Read §2 before any RE session. |
| `docs/blueprint.pdf` | 17-page design blueprint for the prototype (interview flow, MD3 system, engine, AI cascade). |
| [GitHub Releases](https://github.com/maniesh-NR/ClearFile/releases) | Pre-built binaries for every target platform. Release assets live on GitHub Releases, not in the repository tree. |
| `.github/workflows/` | CI: multi-platform release pipeline (Android APK armv7/armv8a, Linux, Windows, macOS, Web) triggered on tag push. |

## Clean-room line

ClearFile reproduces *function and field structure*, never *text, copy, or
expression*. That line is drawn by:

- **17 U.S.C. §102(b)** — the Idea-Expression Dichotomy: methods of
  operation, concepts, and procedures are not copyrightable.
- **The Merger Doctrine** — when an idea can only be expressed in one or a
  few ways, the expression merges with the idea and is unprotected.
- **Scènes à faire** — elements that any implementation of the same
  functional goal must necessarily share (here: the line items and
  calculation order dictated by the IRS's own published forms) are not
  protected.
- ***Computer Associates International, Inc. v. Altai, Inc.*, 982 F.2d 693
  (2d Cir. 1992)** — the Abstraction-Filtration-Comparison test for
  separating unprotectable ideas from protectable expression.
- ***Apple Computer, Inc. v. Microsoft Corp.*, 35 F.3d 1435 (9th Cir.
  1994)** — filtration applied to GUI elements; unprotectable ideas and
  merger/scènes-à-faire elements cannot ground an infringement claim.

Fuller treatment, including the DMCA §1201(f) interoperability research
exemption and the AES-layer handling of modern `.tax` files, is in
[`docs/reverse-engineering-protocol.md`](docs/reverse-engineering-protocol.md)
§2.

## Calculation engines

The repository contains **two independent implementations** (no shared
code). They intentionally disagree on scope — read this section and
[Engine limitations](#engine-limitations) before comparing their outputs.

### Flutter engine — `clearfile/lib/tax/calculator.dart` (TY2025)

The complete model. Implements:

- Five filing statuses with the MFJ / MFS / QSS / Single schedules.
- Standard deduction with the **OBBBA senior deduction** (age 65+).
- Itemized deduction with **SALT 30% phase-down** above the MFJ $550k /
  MFS $275k thresholds (verified against the IRS's published example).
- Qualified-dividends tax bands (0% / 15%) with NIIT.
- **Child Tax Credit** with the $400k MFJ phase-out (exact 5%-of-excess)
  and the refundable ACTC.
- **Other Dependent Credit**.
- Student loan interest deduction with the MAGI phase-out (and the MFS
  exclusion).
- Charitable deduction capped at 60% of AGI.

Every parameter is a named constant with its source cited; every parameter
is pinned by a calculator test that hand-verifies the math. Cross-engine
parity tests pinned to official IRS worked examples are Roadmap Stage 3
(`harness/memory/ROADMAP.md`).

### Web prototype engine — `src/lib/tax/engine.ts` (simplified)

The earlier, smaller model used by the Next.js prototype: **no**
qualified-dividend/LTCG preferential stacking, **no** NIIT, **no** SALT
cap, **no** OBBBA senior deduction, no student-loan-interest deduction;
itemized deductions are medical + other with no AGI ceilings; whole-dollar
rounding. It supports TY2025 and TY2026 year configs (TY2026 default), and
models the CTC phase-out in $50-per-$1,000 units rather than the Flutter
engine's exact 5%-of-excess. The same inputs can produce different refunds
between the two engines.

## Engine limitations

Both engines are demonstration-grade simplifications; neither is a
form-for-form 1040 implementation. In particular:

- **Flutter (TY2025)**: some parameters and phase-outs are modelled at a
  summary level rather than form-by-form (for example, no AMT, no
  Schedule SE/self-employment tax, no state returns, no estate/trust
  schedules); phase-outs apply the published formulas but do not replicate
  every worksheet's intermediate rounding.
- **Web prototype**: the gap list above — no QDI stacking, no NIIT, no SALT
  cap, no OBBBA senior deduction, no student-loan-interest deduction;
  whole-dollar rounding.
- **Neither engine** is validated against official IRS worked examples by
  automated parity tests yet (Roadmap Stage 3).
- The deterministic review layer flags missing or inconsistent entries
  but is not a substitute for review by a qualified preparer or
  IRS-authorized software.

## NOTICE — history contents

Early commits in this repository's history (before the 2026-11-14 hygiene
commit `df617e8`) accidentally included sandbox scaffolding, among it
`download/nitro_nissi/` — **an earlier iteration of this same project**
created by the same author under its working name, superseded by ClearFile
and retained in git history only. It is not part of the current tree, is
not maintained, and carries no license of its own beyond the repository's
GPL-3.0. Current `main` contains none of that scaffolding; the decision to
accept-and-document rather than rewrite history is recorded in
`harness/memory/DECISIONS.md` (ADR-008, ratified 2026-11-14).

## AI assistant (bring your own free key)

The AI cascade is **opt-in** and **bring-your-own-key**. No keys ship with
the app, no telemetry is sent, and the providers are called directly from
the user's device. In the Flutter app, return figures go to your chosen
provider **only when you opt in** (off by default) — tapping the assistant's
review button shares the same de-identified figures per request. In the
web prototype, the copilot panel always sees the summarized return
(de-identified: no names, SSNs, or employer names — the one exception is
text pasted into auto-fill, which is transmitted to your provider for
extraction).

> **Note on the v1.0.0 release binaries:** the Android and macOS binaries
> shipped with tag `v1.0.0` predate the network permission/entitlement and
> **cannot reach AI providers** — the assistant silently fails on them.
> Fixed in the repository; the next tagged release will carry the fix.

The default chain walks the strongest free tiers top-to-bottom and
auto-degrades on rate limits (429) and auth failures (401):

1. `gemini-3.1-pro-preview` (Google AI Studio)
2. `gemini-3.8-flash` (Google AI Studio)
3. `gemini-3.5-flash-lite` (Google AI Studio)
4. `nvidia/nemotron-3.5-super-vl:free` (OpenRouter)
5. `nvidia/nemotron-3-ultra-550b-a55b:free` (OpenRouter)
6. `openrouter/free` (OpenRouter's own free-pool router)

Old `mistral` entries in a saved settings file are silently dropped on load
— Mistral's free tier ended 2026-09-21. The model chain is fully editable
in-app; see `clearfile/lib/ai/settings.dart` for the
`AiSettings` / `AiModelSpec` / `AiSettingsStore` implementation and
`clearfile/test/cascade_test.dart` for the cascade behaviour contract.

## Running the Flutter app

```bash
# install SDK if you don't have it (any Flutter ≥ 3.47 channel stable)
git clone https://github.com/maniesh-NR/ClearFile.git
cd ClearFile/clearfile
flutter pub get
flutter run                       # picks the active device
flutter test                      # 47 tests green
flutter build apk --split-per-abi # Android armv7 / armv8a / x86_64
flutter build linux               # Linux x64
flutter build macos               # macOS universal
flutter build windows             # Windows x64
flutter build web                 # Static web assets
```

## Running the web prototype

```bash
cd ClearFile
npm install
npm run build      # next build (standalone output)
npm start          # serve the standalone build
```

The standalone build plus `cp -r .next/static .next/standalone/.next/` and
`cp -r public .next/standalone/` (already in `package.json` `build`
script) gives a self-hostable bundle.

## Demo disclaimer

ClearFile is **demonstration software**. The calculation engine is
simplified; some 2025 parameters and phase-outs are modelled at a summary
level rather than form-by-form. **Do not file a real return with it.** The
deterministic review layer flags missing or inconsistent entries but is
not a substitute for review by a qualified preparer or commercial
IRS-authorized software.
