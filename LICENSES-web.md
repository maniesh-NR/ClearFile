# LICENSES-web.md — the web conveyance's third-party license manifest (D45)

**Status:** in force 2026-11-28 (landed fail-closed at the Stage-2 exit
close — LEGAL's condition 1; the release job refuses without this file
and ships it as a release asset) · Scope: the artifacts whose compute
serves through the Rust core's WASM build — the `clearfile-web-
standalone-*.tar.gz` asset and any future web distribution built on the
same core.

The GPL §6 discipline: the complete corresponding source for every
binary in a release is that release's own tagged public commit of this
repository, and the WASM module is built `--locked` from exactly that
tagged checkout (`core-ffi/Cargo.lock` is committed; the release
workflow's `nextjs-web` job builds `core-ffi` for
`wasm32-unknown-unknown` from the tagged tree — the same-tag
`--locked` rule, DEBT D45).

## The three rows (DEBT D45)

| Component | In the shipped artifact as | License | Provenance |
| --- | --- | --- | --- |
| **palette** (the Material You dynamic-palette module embedded in the core, `core/src/palette.rs`) | compiled into `public/clearfile-core.wasm` | **Apache-2.0** | the module's upstream basis and its translation are recorded in `core/src/palette.rs`'s header and `THIRD-PARTY-NOTICES.md`'s Apache-2.0 entry (the D44 record: the corpus verification + the upstream copyright note) |
| **Rust standard library** (statically linked into the same `.wasm` — the first Rust binary in this repo with a real distribution path, the /MT precedent's WASM form) | statically linked into `public/clearfile-core.wasm` | **MIT OR Apache-2.0** (the Rust std's dual license) | built by the pinned toolchain (`scripts/rust_toolchain_manifest`, the pinned dist tarballs, sha256-verified); the toolchain's own license texts ship with the pinned distribution |
| **shadcn/ui components** (the vendored set under `src/components/ui/`) | shipped as the web app's source (GPL v3 s6: the tagged commit IS the complete source) | **MIT** (the components' own license, carried verbatim in each file) | the vendored set recorded in `THIRD-PARTY-NOTICES.md` (the vendored-shadcn exclusion from the project's SPDX header rule) |

## Verification pointers

- The `.wasm` build's reproducibility contract: `--locked` against the
  committed lockfiles; the import-empty guard proves the module makes
  no external calls; the rustc >= 1.95 guard pins the toolchain era.
- The bundled asset assertion: the release job's bundle step fails
  closed if `public/clearfile-core.wasm` is missing from the tarball
  (the D46 guard) — this manifest and that asset ship together by
  construction.
- The general third-party notices (the app-level set) remain in
  `THIRD-PARTY-NOTICES.md`; this file adds only the web-conveyance rows
  the N6-exit reviewer required.
