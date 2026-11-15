name: Format/documentation discrepancy report
description: >-
  A documented file format, schema, or spec statement disagrees with what
  the code actually reads/writes — or with a published spec the project
  claims to follow (TXF v042, the unified return format, the exchange
  container).
title: "[format] "
labels: ["format-discrepancy"]
body:
  - type: markdown
    attributes:
      value: |
        For disagreements between the documentation and the behaviour of
        a ClearFile file format: the unified return file
        (`docs/return-format.md`), the TXF import/export (spec v042), the
        `.tax` read-only inspection, or the ClearFile exchange container.
        Reverse-engineering of proprietary Intuit material has its own
        process (`docs/reverse-engineering-protocol.md`) — do NOT paste
        proprietary file contents here.

  - type: input
    id: doc
    attributes:
      label: The document/section
      placeholder: "docs/return-format.md §3 (migration matrix) / README bridges section"
    validations:
      required: true

  - type: textarea
    id: claim
    attributes:
      label: What the documentation says
    validations:
      required: true

  - type: textarea
    id: behavior
    attributes:
      label: What the code actually does (with the exact file/steps to reproduce)
    validations:
      required: true

  - type: input
    id: citation
    attributes:
      label: External spec citation (if the claim cites one)
      description: e.g. the TXF spec v042 record table, the ZIP APPNOTE. Only public, published specifications.
    validations:
      required: false
