name: Engine discrepancy report
description: >-
  The engines' output disagrees with a published IRS figure, form line, or
  worksheet example. Use this ONLY for arithmetic/parameter
  disagreements — UI bugs and enhancement ideas are regular issues.
title: "[discrepancy] "
labels: ["engine-discrepancy"]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for checking ClearFile's math against the source of
        truth. Before filing: this is **demonstration software** — a
        deliberate simplification of Form 1040 (see `docs/engine.md` §6,
        the limitations register). Simplifications already listed there
        are known and accepted; a *discrepancy* is when the engine
        disagrees with a published figure **inside its declared scope**.

  - type: input
    id: engine
    attributes:
      label: Which engine?
      placeholder: Flutter app / web prototype / both (if both disagree, say so — they should never differ)
    validations:
      required: true

  - type: input
    id: inputs
    attributes:
      label: The return inputs (exact numbers)
      description: Filing status, income lines, flags — everything needed to reproduce.
      placeholder: "MFJ, wages 100,000, QDI 30,000, 2 qualifying children, ..."
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: What ClearFile computed
      description: The line/field and value, from the Results summary.
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: The published value
      description: What the IRS-published source says it should be.
    validations:
      required: true

  - type: input
    id: citation
    attributes:
      label: IRS citation (URL or form + line/worksheet)
      description: The specific page, form line, or worksheet example the published value comes from. A secondary source (Tax Foundation etc.) is acceptable ONLY if you also name the IRS source it paraphrases.
      placeholder: "https://www.irs.gov/... (Form 1040 instructions, QDIVCG worksheet line 13)"
    validations:
      required: true

  - type: textarea
    id: derivation
    attributes:
      label: Your derivation (optional but decisive)
      description: The arithmetic you did to confirm the published value. Reports with a worked derivation get fixed fastest.
    validations:
      required: false
