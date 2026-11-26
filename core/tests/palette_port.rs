// SPDX-License-Identifier: GPL-3.0-only
//! The D44 palette-port corpus suite (chunk 2): the differential
//! verification of the tonal palettes, the `SchemeTonalSpot` palette
//! construction, and the 34 scheme roles against
//! `fixtures/palette/cases.json` — 33 seeds × 6 ladders × 101 tones +
//! 33 seeds × 2 modes × 34 roles, every expected value the MCU 0.13.0
//! reference's own output (integer ARGB parity — tolerance 0 by
//! construction; the corpus is NOT a golden fixture, see
//! `fixtures/palette/README.md`).
//!
//! The corpus is parsed with the core's own JSON codec
//! ([`Json`] — `crate::json`, N1 session 2); ARGB pins are integers
//! 0..=0xFFFFFFFF, read with [`Json::as_i64`] (whose integer-magnitude
//! ceiling 9.0e18 covers the whole `u32` range) and range-checked on the
//! `u32` cast.

use clearfile_core::json::Json;
use clearfile_core::palette::{scheme_role, scheme_tonal_spot_palettes, PaletteRole};

/// `fixtures/palette/cases.json` resolved from `CARGO_MANIFEST_DIR`
/// (core/), so the suite is CWD-independent.
fn corpus() -> Json {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../fixtures/palette/cases.json");
    let text = std::fs::read_to_string(&path)
        .expect("fixtures/palette/cases.json must be readable");
    Json::parse(&text).expect("the palette corpus must parse")
}

fn get<'a>(v: &'a Json, key: &str, what: &str) -> &'a Json {
    match v.get(key) {
        Some(x) => x,
        None => panic!("{what}: key `{key}` missing"),
    }
}

fn obj<'a>(v: &'a Json, what: &str) -> &'a [(String, Json)] {
    match v.as_obj() {
        Some(o) => o,
        None => panic!("{what} must be an object"),
    }
}

fn arr<'a>(v: &'a Json, what: &str) -> &'a [Json] {
    match v.as_arr() {
        Some(a) => a,
        None => panic!("{what} must be an array"),
    }
}

/// An ARGB pin: an integer in 0..=0xFFFFFFFF (`as_i64` already rejects
/// non-integers; the range check guards the `u32` cast).
fn argb(v: &Json, what: &str) -> u32 {
    match v.as_i64() {
        Some(n) if (0..=u32::MAX as i64).contains(&n) => n as u32,
        _ => panic!("{what} must be an in-range ARGB integer, got {v:?}"),
    }
}

/// One corpus case's seed ARGB.
fn seed_of(case: &Json) -> u32 {
    argb(get(case, "seed", "case"), "the case's seed")
}

#[test]
fn corpus_metadata_matches_the_contract() {
    let corpus = corpus();
    assert_eq!(
        get(&corpus, "kind", "corpus").as_str(),
        Some("clearfile-palette"),
        "the corpus's kind"
    );
    let cases = arr(get(&corpus, "cases", "corpus"), "the corpus cases");
    let seed_count = get(&corpus, "seedCount", "corpus")
        .as_i64()
        .expect("seedCount must be an integer");
    assert_eq!(
        seed_count,
        cases.len() as i64,
        "seedCount == the cases array length"
    );
    assert_eq!(seed_count, 33, "seedCount == 33");
    assert_eq!(
        get(&corpus, "roleCount", "corpus").as_i64(),
        Some(34),
        "roleCount == 34"
    );
    assert_eq!(
        get(&corpus, "paletteCount", "corpus").as_i64(),
        Some(6),
        "paletteCount == 6"
    );
    match get(&corpus, "mcuSha256", "corpus").as_str() {
        Some(s) if !s.is_empty() => {}
        other => panic!("mcuSha256 must be present and non-empty, got {other:?}"),
    }
}

#[test]
fn tonal_ladders_match_the_corpus() {
    let corpus = corpus();
    let cases = arr(get(&corpus, "cases", "corpus"), "the corpus cases");
    for case in cases {
        let seed = seed_of(case);
        let palettes = scheme_tonal_spot_palettes(seed);
        let ladders = obj(get(case, "ladders", "case"), "the case's ladders");
        assert_eq!(ladders.len(), 6, "seed {seed:#010x}: six ladders");
        for (name, palette) in [
            ("primary", &palettes.primary),
            ("secondary", &palettes.secondary),
            ("tertiary", &palettes.tertiary),
            ("neutral", &palettes.neutral),
            ("neutralVariant", &palettes.neutral_variant),
            ("error", &palettes.error),
        ] {
            let expected = match ladders.iter().find(|(k, _)| k == name) {
                Some((_, v)) => arr(v, "the ladder"),
                None => panic!("seed {seed:#010x}: ladder `{name}` missing"),
            };
            assert_eq!(
                expected.len(),
                101,
                "seed {seed:#010x} ladder {name}: tones 0..=100"
            );
            for (tone, want) in expected.iter().enumerate() {
                let want = argb(want, "the ladder value");
                let got = palette.tone(tone as u32);
                assert_eq!(
                    got, want,
                    "seed {seed:#010x} palette {name} tone {tone}: \
                     got {got:#010x}, want {want:#010x}"
                );
            }
        }
    }
}

#[test]
fn scheme_roles_match_the_corpus() {
    let corpus = corpus();
    let cases = arr(get(&corpus, "cases", "corpus"), "the corpus cases");
    for case in cases {
        let seed = seed_of(case);
        for dark in [false, true] {
            let roles = obj(
                get(case, if dark { "dark" } else { "light" }, "case"),
                "the case's roles",
            );
            assert_eq!(roles.len(), 34, "seed {seed:#010x} dark {dark}: 34 roles");
            for role in PaletteRole::ALL {
                let want = match roles.iter().find(|(k, _)| *k == role.name()) {
                    Some((_, v)) => argb(v, "the role value"),
                    None => panic!(
                        "seed {seed:#010x} dark {dark}: corpus role `{}` missing",
                        role.name()
                    ),
                };
                let got = scheme_role(seed, dark, role);
                assert_eq!(
                    got, want,
                    "seed {seed:#010x} role {} dark {dark}: \
                     got {got:#010x}, want {want:#010x}",
                    role.name()
                );
            }
        }
    }
}

#[test]
fn every_role_name_maps_to_a_corpus_key() {
    let corpus = corpus();
    let cases = arr(get(&corpus, "cases", "corpus"), "the corpus cases");
    for case in cases {
        let seed = seed_of(case);
        for mode in ["light", "dark"] {
            let roles = obj(get(case, mode, "case"), "the case's roles");
            assert_eq!(roles.len(), 34, "{mode} roles: exactly the 34 pinned keys");
            // Every variant's name() is a corpus key (a variant without a
            // key fails loudly).
            for role in PaletteRole::ALL {
                assert!(
                    roles.iter().any(|(k, _)| *k == role.name()),
                    "seed {seed:#010x}: role {} ({mode}) has no corpus key",
                    role.name()
                );
            }
            // Every corpus key is some variant's name (an unmapped role
            // fails loudly) — with 34 distinct variants on both sides, the
            // mapping is a bijection.
            for (k, _) in roles {
                assert!(
                    PaletteRole::ALL.iter().any(|r| r.name() == *k),
                    "seed {seed:#010x}: corpus role `{k}` ({mode}) maps to no \
                     PaletteRole variant"
                );
            }
        }
    }
}
