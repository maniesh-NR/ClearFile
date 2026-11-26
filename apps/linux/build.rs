// SPDX-License-Identifier: GPL-3.0-only
//! N2 session 2: compile `ui/app.slint` via slint-build (the standard
//! Slint split — markup in `ui/`, compiled here, consumed in `main.rs`
//! via `slint::include_modules!()`). The compiler is bound to the same
//! audited 1.19 series as the runtime crate.

fn main() {
    slint_build::compile("ui/app.slint")
        .expect("ui/app.slint could not be compiled by slint-build 1.19");
}
