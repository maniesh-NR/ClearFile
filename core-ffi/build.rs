// SPDX-License-Identifier: GPL-3.0-only
//! The header generator (N3, ADR-017's FFI seam): cbindgen =0.29.4
//! (MPL-2.0, build-time-only) emits `clearfile.h` — the C99 flat C ABI
//! contract the N4 (Win32 C++) and N5 (SPM) consumers import. The
//! deterministic regeneration (the exact pin + cbindgen.toml) is the CI
//! freshness check's premise: regenerate-to-temp + diff against the
//! COMMITTED header fails on any drift.

use std::env;
use std::path::PathBuf;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    // The committed header lives at the crate root (the tracked contract
    // — NOT only in OUT_DIR; the N3 gate ruled it committed: it is the
    // N4/N5 import surface, reviewable in-tree, and the freshness check
    // diffs against it).
    let header = PathBuf::from(&crate_dir).join("clearfile.h");

    cbindgen::Builder::new()
        .with_crate(&crate_dir)
        .with_config(cbindgen::Config::from_root_or_default(&crate_dir))
        .generate()
        .expect("cbindgen must generate the flat C ABI header (the config + the exact pin are the deterministic premises)")
        .write_to_file(&header);

    // Also drop it in OUT_DIR so dependents can include it by cargo
    // metadata path if they ever want to (harmless; the tracked header is
    // the contract).
    let _ = std::fs::copy(&header, out_dir.join("clearfile.h"));
}
