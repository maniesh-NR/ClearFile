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
| `src/` | The original **Next.js 16 web prototype**: a seven-step Material 3 tax interview (status → income → deductions → dependents → payments → review → results) with a deterministic TY2025 calculation engine, deterministic review findings, and an optional bring-your-own-key AI assistant. |
| `clearfile/` | The **Flutter 3.47 app**: the same interview, engine and AI cascade compiled to Android, iOS, macOS, Windows, Linux and Web from one Dart codebase. |
| `clearfile/test/` | 42 Dart tests — 20 calculator, 8 AI cascade, 9 CSV import, 3 JSON roundtrip, 3 widget — that pin the engine and UI behaviour. `flutter analyze` is clean and `flutter test` is 42/42 green. |
| `docs/reverse-engineering-protocol.md` | The **clean-room RE playbook** for studying legacy proprietary tax-file formats (`.tax`, `.tax[YYYY]`, `.LIF`, `.FIL`, `.RCD`, `.1PE`, `.3ME`, `.3PE`, `.DGC`, `.SCD`, `.THP`, `.TVL`, `.1PH`, `.TT[YYYY]STATE`). Read §2 before any RE session. |
| `docs/blueprint.pdf` | 17-page design blueprint for the prototype (interview flow, MD3 system, engine, AI cascade). |
| `download/` | Pre-built release bundles (web standalone, Flutter web build) for the current tag. |
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

## TY2025 calculation engine

The engine in `clearfile/lib/tax/calculator.dart` (and `src/lib/tax/` for
the web prototype) implements:

- Five filing statuses with the MFJ / MFS / QSS / Single schedules.
- Standard deduction with the **OBBBA senior deduction** (age 65+).
- Itemized deduction with **SALT 30% phase-down** above the MFJ $550k /
  MFS $275k thresholds (verified against the IRS's published example).
- Qualified-dividends tax bands (0% / 15%) with NIIT.
- **Child Tax Credit** with the $400k MFJ phase-out and the refundable
  ACTC.
- **Other Dependent Credit**.
- Student loan interest deduction with the MAGI phase-out (and the MFS
  exclusion).
- Charitable deduction capped at 60% of AGI.

Every parameter is a named constant with its source cited; every parameter
is pinned by a calculator test that hand-verifies the math.

## AI assistant (bring your own free key)

The AI cascade is **opt-in** and **bring-your-own-key**. No keys ship with
the app, no telemetry is sent, and the providers are called directly from
the user's device.

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
flutter test                      # 42/42 green
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
