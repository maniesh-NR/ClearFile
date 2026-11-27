/* SPDX-License-Identifier: GPL-3.0-only
 * The ClearFileFFI C target's one translation unit (SPM C targets
 * need at least one source file; the ABI itself lives in the Rust
 * cdylib — this file compiles to nothing, it only anchors the
 * target). */

typedef int clearfile_ffi_anchor_t; /* the one anchor declaration */
