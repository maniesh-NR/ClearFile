// SPDX-License-Identifier: GPL-3.0-only
//! The fixture manifest (gate PROD-3): the ledger the harness_check join
//! reads mechanically. [`harness::FIXTURE_MANIFEST`] is a plain text list
//! of `"filename status reason"` lines (one per fixture) so a shell grep
//! can count `run` and `deferred` entries. The anchor matches the
//! manifest const's line shape (4-space indent, quoted filename) so prose
//! in doc comments cannot pollute the count:
//!
//! ```sh
//! # run count (17 in session 1):
//! grep -cE '^    "[0-9]{2}-[a-z0-9-]+\.json (run|deferred) ' core/tests/harness/mod.rs
//! # deferred count (0 in session 1):
//! grep -E '^    "[0-9]{2}-[a-z0-9-]+\.json (run|deferred) ' core/tests/harness/mod.rs | grep -c ' deferred '
//! ```
//!
//! Invariants asserted here:
//! 1. The manifest covers the fixture directory's `*.json` set EXACTLY
//!    (no drift, same as the skip-map guard).
//! 2. Every manifest status matches the skip map (`run` ↔
//!    [`harness::FixtureStatus::Run`], `deferred` ↔
//!    [`harness::FixtureStatus::Deferred`]).
//! 3. `run` entries carry reason `-`; `deferred` entries carry a
//!    `"<feature>: <reason>"` string naming the input feature.
//! 4. run count + deferred count == the directory's fixture count —
//!    i.e. green + `#[ignore]`d tests == 17, the session-1 shape.

mod harness;

/// Parse a manifest reason column into its `feature: reason` parts
/// (deferred entries only).
fn split_feature_reason(reason: &str) -> (String, String) {
    let (feature, reason) = reason
        .split_once(": ")
        .expect("deferred manifest reason must be '<feature>: <reason>'");
    (feature.to_owned(), reason.to_owned())
}

#[test]
fn manifest_covers_directory_exactly_and_matches_the_skip_map() {
    let dir_set = harness::directory_fixture_set();
    let entries = harness::manifest_entries();

    let manifest_files: std::collections::BTreeSet<&str> =
        entries.iter().map(|e| e.file).collect();
    let dir_files: std::collections::BTreeSet<&str> =
        dir_set.iter().map(|s| s.as_str()).collect();
    let map: Vec<(&'static str, harness::FixtureStatus)> = harness::skip_map();
    let map_files: std::collections::BTreeSet<&str> = map.iter().map(|(f, _)| *f).collect();

    assert_eq!(
        manifest_files, dir_files,
        "manifest must list the fixtures/tax directory exactly (no drift)"
    );
    assert_eq!(
        manifest_files, map_files,
        "manifest statuses and skip map must cover the same fixture set"
    );
    assert_eq!(
        entries.len(),
        dir_files.len(),
        "exactly one manifest line per fixture"
    );

    // Statuses match the skip map; reason columns are well-formed.
    for entry in &entries {
        let map_status = map
            .iter()
            .find(|(f, _)| *f == entry.file)
            .map(|(_, s)| s)
            .expect("skip map covers every manifest file");
        match (entry.status, map_status) {
            ("run", harness::FixtureStatus::Run) => {
                assert_eq!(
                    entry.reason, "-",
                    "run manifest line for {} must carry '-' as its reason",
                    entry.file
                );
            }
            ("deferred", harness::FixtureStatus::Deferred { reason: _, feature: _ }) => {
                assert_ne!(
                    entry.reason, "-",
                    "deferred manifest line for {} must carry a real reason",
                    entry.file
                );
                let (feature, reason) = split_feature_reason(entry.reason);
                assert!(
                    !feature.is_empty() && !reason.is_empty(),
                    "deferred manifest line for {} must be '<feature>: <reason>'",
                    entry.file
                );
            }
            (status, map_status) => panic!(
                "manifest status '{}' for {} does not match skip map {:?}",
                status, entry.file, map_status
            ),
        }
    }

    // The session shape: run + deferred == the fixture count (17 today),
    // i.e. green + ignored tests == the fixture directory count.
    let run_count = entries.iter().filter(|e| e.status == "run").count();
    let deferred_count = entries.iter().filter(|e| e.status == "deferred").count();
    assert_eq!(
        run_count + deferred_count,
        dir_files.len(),
        "green + ignored must equal the fixture count"
    );
}

/// A shell-side sanity anchor: exactly 17 fixtures, all `run` in session 1.
/// Hardcoding the count here is deliberate — the 16→17 erratum (gate
/// ENG-9/SEC-adv/PROD-7) is exactly the kind of silent drift this catches.
#[test]
fn fixture_count_is_17_and_session_1_runs_all() {
    assert_eq!(harness::FIXTURE_FILES.len(), 17);
    assert_eq!(harness::FIXTURE_MANIFEST.len(), 17);
    let run_count = harness::FIXTURE_MANIFEST
        .iter()
        .filter(|l| l.contains(" run "))
        .count();
    let deferred_count = harness::FIXTURE_MANIFEST
        .iter()
        .filter(|l| l.contains(" deferred "))
        .count();
    assert_eq!(run_count, 17, "session 1 runs all 17 fixtures");
    assert_eq!(deferred_count, 0, "no honest deferrals in session 1 (whole-port per ENG-4)");
}
