/*
 * SPDX-License-Identifier: GPL-3.0-only
 * The ClearFile macOS seam (N5): the wrapper umbrella header for the
 * ClearFileFFI C target — it includes the SAME committed flat C ABI
 * header (core-ffi/clearfile.h, the cbindgen-generated audit surface
 * with the config-emitted extern "C" guards) verbatim; nothing is
 * re-declared or copied (the symlink shape was rejected at the N5
 * gate — the CI asserts this include line and the build pins it; the
 * committed-header freshness check stays with the android job's
 * every-push check).
 */
#include "../../../../../core-ffi/clearfile.h"
