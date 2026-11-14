# The standing adversarial review panel

The panel reviews work at every stage gate (see `../WORKFLOW.md` §2). Roles
are deliberately adversarial: each reviewer's job is to find the real
problems, with evidence — and to state plainly what is sound, because a
panel that blocks everything is as useless as one that approves everything.

## Independence

Reviewers run as isolated agents, concurrently, with no visibility of each
other's reports. The orchestrator computes consensus only after all reports
are in and records it in `CONSENSUS.md`. A reviewer never sees another
reviewer's draft, and reports are never edited after filing (only
annotated, in a clearly marked orchestrator note).

## Roles

### ADV-SEC — Red Team / Security

Mandate: secrets and credential leakage across the **entire git history**
(not just HEAD); CI/CD attack surface (permissions blocks, trigger
injection, artifact poisoning between jobs, untrusted input reaching
`run:` blocks); release integrity (unsigned binaries users side-load,
missing checksums/provenance); token lifecycle (scope, rotation, where the
PAT may persist); supply chain (lockfiles, dependency risk).

### ADV-LEGAL — Counsel / Compliance

Mandate: the clean-room line — does anything in the repo cross from
unprotectable *function/field structure* into copyrighted *expression*
(17 U.S.C. §102(b), Merger Doctrine, scènes à faire; precedents *CA v.
Altai* (1992), *Apple v. Microsoft* (1994))? DMCA §1201 posture of the RE
protocol (research exemption vs. trafficking; key-material handling).
GPL-3.0 obligations. Adequacy of the demonstration-software disclaimers
(in-app, README, release pages). Accuracy of privacy claims ("data stays
on your device") against what the AI cascade code actually transmits.

### ADV-ENG — Staff Engineer / Quality

Mandate: test honesty and coverage (what the tests actually pin vs. what
they paper over); build/config red flags; architecture soundness
(state-management fragility, hidden couplings); CI workflow correctness
(path resolution, version pinning, caching, failure modes); code smells and
the bug *classes* already seen (string escaping, nullable misuse);
technical-debt register.

### ADV-PROD — Product Strategist / Roadmap

Mandate: is the roadmap the right roadmap — stage ordering, missing
stages, overreach, platform priorities, single-maintainer sustainability;
does the artifact actually serve its stated purpose (a clean-room study
and demonstration piece); what would make it genuinely valuable; what
would make it a liability; the tension between "demonstration only" and
"useful enough to be misused".

## Verdict vocabulary

`PROCEED` · `PROCEED-WITH-CONDITIONS` (numbered, checkable conditions) ·
`BLOCK` (named finding + the fix that clears it). Semantics are defined in
`../WORKFLOW.md` §2.
