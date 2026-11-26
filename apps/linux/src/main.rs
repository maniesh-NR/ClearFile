// SPDX-License-Identifier: GPL-3.0-only
//! The ClearFile Linux native UI (N2, the ADR-017 epilogue's second
//! stage): Slint over `clearfile-core` (Linux links the crate DIRECTLY —
//! no FFI, per ADR-017's seam table).
//!
//! The N2 gate's session split: this scaffold lands in session 1 (the
//! crate + the guards + the lock); the window UI, the `--headless`
//! pipeline mode, the CI lane, and both smokes land in session 2.
//! The app's shape per the gate record: `argv[1]` = a `.clearfile.json`
//! envelope path (or a `.tax` exchange container); the pipeline is ONE
//! `load_and_compute(path)` shared structurally by the window and the
//! headless mode (ENG-6: a headless path that re-implements the pipeline
//! would drift silently); the theme is MD3-from-seed via the core's
//! palette module (D44, landed session 1).

fn main() {
    eprintln!("clearfile-linux: the N2 session-2 build (the window UI) lands next; this scaffold carries the crate + the guards.");
}
