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
