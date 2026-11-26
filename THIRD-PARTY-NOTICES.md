# Third-party notices

ClearFile is licensed GPL-3.0-only (see `LICENSE`). This file records the
third-party material included in the tree and under what terms, so the
aggregate distribution complies with those licenses' notice conditions.

## shadcn/ui components (MIT)

The directories `src/components/ui/` and `src/hooks/` contain UI components
and hooks derived from [shadcn/ui](https://ui.shadcn.com), which distributes
its component library under the MIT License. Those files are vendored copies
with local modifications and intentionally carry **no** `SPDX-License-Identifier`
marker — they are MIT-derived, not GPL-3.0-only, and are never relabelled.

The upstream license text is reproduced below as it applies to those
directories:

> MIT License
>
> Copyright (c) 2023 shadcn/ui
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of this software and associated documentation files (the "Software"),
> to deal in the Software without restriction, including without limitation
> the rights to use, copy, modify, merge, publish, distribute, sublicense,
> and/or sell copies of the Software, and to permit persons to whom the
> Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included
> in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
> THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
> OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
> ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
> OTHER DEALINGS IN THE SOFTWARE.

All other first-party code in this repository is GPL-3.0-only and carries
`SPDX-License-Identifier: GPL-3.0-only` headers (see
`harness/memory/DEBT.md` D14 for the header policy, including the deliberate
exclusion of the vendored paths above).

*Recorded 2026-11-14, Stage-2 entry gate condition LEGAL-2/ADV-LEGAL
(vendored-code attribution).*

## material_color_utilities formulas in the Rust core (Apache-2.0)

The Rust core's palette module `core/src/palette.rs` is a translation — a
derivative work, derived not vendored; no Google code text is copied — of
Google's Dart package
[material_color_utilities](https://pub.dev/packages/material_color_utilities)
0.13.0, distributed under the Apache License 2.0: the CAM16/HCT color math
and solver, the tonal palettes, and the Material You dynamic-color scheme
formulas (the `SchemeTonalSpot` palettes and the 34 scheme-role
declarations), each ported item citing its Dart source file. The
differential corpus `fixtures/palette/cases.json` pins the module's outputs
against that reference implementation's own. The Apache License 2.0 is
GPL-3.0-compatible; its text is available at
<https://www.apache.org/licenses/LICENSE-2.0>.

*Recorded at the D44 palette close, chunk 2 of 2 (task N2-S1-PALETTE-2,
derivative-work attribution per the LEGAL-2/ADV-LEGAL discipline).*

