# ADV-LEGAL — Counsel / Compliance · Stage-1 gate review (2026-11-14)

**Scope note:** compliance risk review by an adversarial reviewer, not a legal opinion. All evidence read from the working tree (including the 144-file staged index), git history, and — read-only — the live GitHub API. No files modified, no commits, no pushes.

**Sound posture (stated up front):** the privacy code fix is real and tested; the clean-room expression line remains honored in the Stage-1 delta; the key-material ban still holds across tree and full history under independent scans (token patterns + raw 64-hex blobs: zero genuine hits — only documentation references to pattern names); LICENSE is the unchanged canonical GPL-3.0; the network disclosures match the actual permission grants; `z-ai-web-dev-sdk` is gone.

## Stage-0 condition verification

**LEGAL-1 (provenance ADR before other Stage-1 commits) — VERIFIED.** ADR-008 ratified with owner decision recorded (`harness/memory/DECISIONS.md`); README NOTICE paragraph present describing `download/nitro_nissi/` as the owner's earlier iteration, retained in history only, with the ADR cross-reference. *Caveat (finding 5): the README NOTICE exists in the staged index, not yet in a commit or on GitHub.*

**LEGAL-2 (privacy copy matches code) — VERIFIED for code, defaults, tests, and in-app copy; PARTIAL for the blueprint PDF leg.**
- De-identification by construction: `buildReviewPrompt` serializes only counts and figures; the prompt text itself tells the model it is de-identified.
- Every transmission path re-traced independently: ambient chat (gated on `sendReturnContext`, never names); review (de-identified, disclosed in the switch copy and by design); user-typed chat (user-initiated); test-connection ping; the field-question builder is dead code; web `filingSummary` is counts+figures only; `extractPrompt` sends pasted raw text — the disclosed auto-fill exception. `displayName` and `W2Entry.employer` are never serialized into any prompt. **No path sends names, SSNs, addresses, or ages.** No SSN field exists anywhere in either data model.
- Default flip: constructor and `fromJson` both default OFF; the privacy test pins a pre-field settings file reading as off.
- Contract pinned by 4 genuinely strong tests (names absent regardless of switch state; counts present; default off; figures-only-when-sharing-on).
- In-app copy aligned in settings/welcome (Flutter) and ai-ui/settings (web settings (Flutter) (web).
- **Blueprint leg — PARTIAL:** regenerated and the corrected exception sentence is in the shipped PDF (verified by text extraction), but the generator diff touched exactly one sentence, leaving three other in-PDF claims that contradict it (finding 1).

**LEGAL-3 (release page disclaimer) — VERIFIED.** Workflow `body:` present; independently confirmed live via authenticated GET: the patched body carries the demo disclaimer, the no-advice line, the unsigned-binaries statement, and an honest "predates the SHA256SUMS manifest" note. 9 assets.

**LEGAL-4 (backup scope hardened) — VERIFIED.** `upload/` ignore resolves to the backup-scope block; guard widened with lockfile exclusions; PAT-sanitized push errors with 0600 mktemp+trap; branch guard and unpushed-commit check in place.

**LEGAL-5 (RE protocol §7 before tooling) — VERIFIED.** All five required rules present, plus the demand that the rule become a CI-checkable assertion. No Stage-2 tooling exists yet. **Retroactive audit:** no `docs/formats/` specs exist; the `.tax` sniffer is structural-only — no decryption, no key material, and no key material; the historical nitro_nissi importer explicitly refuses to circumvent encryption and contains no key material (full-history pattern scan: clean). No retroactive violations found.

**Stage-0 minor follow-up:** z-ai-web-dev-sdk — done; Google key in URL — correctly tracked to Stage 5; headers/SECURITY.md — Stage 1 pending, in plan; web auto-fill copy — applied; blueprint title — applied to `layout.tsx` only at review time (see finding 7).

## New findings

1. **[MINOR] The regenerated blueprint PDF still ships three privacy claims that contradict its own corrected sentence.** (§3 data-flow, §8 intro, Appendix B — "never collects those fields in the first place" style claims, false for the auto-fill payload.) Fix: correct the three sentences, regenerate, re-verify by text extraction.
2. **[MINOR] README and release-body "only when you opt in" / "figures you approved" don't disclose the review-button path, which sends figures without consulting `sendReturnContext`.** The tap-is-consent design is disclosed in-app next to the switch; the two widest-circulation surfaces state it more narrowly than the code behaves. Fix: one clause, or gate the review prompt on the switch.
3. **[MINOR] DECISIONS.md claims the v1.0.0 Android AI-dead fact is "noted in the NOTICE/limitations" — no such note exists anywhere user-visible.** Fix: one line in README or the live release description +1.
4. **[MINOR] `sendReturnContext` grandfathering: persisted `true` from the pre-fix default keeps transmitting under an "approved" narrative the user never affirmatively gave.** Fix: a one-time migration resetting the flag to false on first load of the new version (with a settings schema version), or an explicit in-app note; record in DECISIONS either way.
5. **[MINOR] The entire Stage-1 entry-condition fix set (144 files) is staged but uncommitted — the public repo does not yet contain any of it.** Sequencing (teardown backup is the designed mechanism), not violation — but the push must actually land and the gate record should say so explicitly.
6. **[NOTE] README test-count drift** (47 in the table, "42/42" in the run block). Fix the one number.
7. **[NOTE] Blueprint title still "Tax Filing Assistant"** in the PDF while the web title was de-"Filing"-ed. Fold into the same regeneration as finding 1.
8. **[NOTE] RE protocol doc drift** — "our web prototype's `ole_cfb.dart` already implements a reader" points at a file that exists only in history. Fix the pointer before Stage 2.
9. **[NOTE] `buildFieldQuestion` is dead code that would transmit raw field values if ever wired.** Delete it or reduce to field-title-only before wiring.
10. **[NOTE] Harness memory bookkeeping drift.** DEBT rows not closed for applied fixes; STATE.md stale lines; pubspec description still template text; 144 files with flipped modes. D19's harness_check is the designed fix.
11. **[NOTE] GPL §6 corresponding-source statement is implicit, not explicit.** Binaries and source sit on the same GitHub origin (satisfies §6(a) in practice); one explicit line in the release body template makes it airtight.
12. **[NOTE] Sound, verified, worth recording:** network disclosure matches the actual grants (only the AI providers are reachable); macOS grants network-client only; the web `filingSummary` never serializes employer strings; every remaining npm dependency is GPL-3.0-compatible; ADR-009's parity scope (pure functions, IRS-published parameters — government edicts, §105 — and TXF record codes as published-format facts) creates **no new legal surface** provided the engines keep the cite-the-source paraphrase discipline; the clean-room expression audit re-ran clean over the Stage-1 delta.

## Roadmap assessment (compliance seat)

- **Stage 1 (remainder):** correctly sequenced; fold in the cheap copy-accuracy items this gate surfaced (findings 1, 2, 3, 6, 7); record finding 4's migration decision; verify finding 5's push. gitleaks CI, action pinning, SHA256SUMS at next tag, SECURITY.md, GPL headers, harness self-check all remain correctly in scope; the header work should also fix the nested pubspec description.
- **Stage 2:** §7 is written, referenced, and retroactively clean — the condition's exact intent. Keep the full-depth gate with ADV-LEGAL weighted; make §7's no-binary-blob assertion an actual executable check; fix the stale reader pointer before tooling lands.
- **Stage 3 (ADR-009 parity):** lowest legal risk, highest value — pure-function port, IRS-example golden fixtures, TXF codes as facts. Optional: a web sendReturnContext-equivalent switch (or explicit README scoping of the opt-in sentence).
- **Stage 4:** the hosted build must carry the prominent disclaimer; ensure the copy fixes land before any Pages deploy.
- **Stage 5:** key-in-URL fix and disclosure-generated-from-transmission correctly sequenced; the review-path exception (finding 2) should NOT wait for Stage 5 — it corrects current claims.

## Verdict

**PROCEED-WITH-CONDITIONS** — nothing in the current tree or history rises to a GPL, DMCA, or clean-room violation; the Stage-0 legal conditions are genuinely implemented in code and copy (one leg partially); the new findings are accuracy-of-disclosure and sequencing items, not legality items. Conditions:

1. **Blueprint accuracy:** correct the three remaining over-broad privacy sentences, regenerate `docs/blueprint.pdf`, verify by text extraction that no shipped sentence contradicts the auto-fill exception; fold in the title change.
2. **Opt-in wording scope:** README and the release-body template must state the review-button exception (or gate the review prompt on `sendReturnContext`); the v1.0.0 AI-broken fact must appear user-visible (README NOTICE or the live release description) — DECISIONS.md currently records a disclosure that does not exist.
3. **Publication sequencing:** the staged fix set must be committed and pushed (end-of-plan backup) before Stage-1 feature work proceeds, with verification that `origin/main` carries the NOTICE and privacy changes.
4. **Grandfathered-consent posture decided and recorded:** a one-time `sendReturnContext` reset-to-false migration (with a settings schema version) or an explicit in-app note — recorded in DECISIONS.md either way.
