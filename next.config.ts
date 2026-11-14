import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  /* Type errors are now surfaced: `npx tsc --noEmit` is clean and runs in
   * CI (Stage-0 gate, ADV-ENG #6). If a build breaks on types, fix the
   * types — do not re-enable this flag. */
  typescript: {
    ignoreBuildErrors: false,
  },
  /* Strict mode is ON (ADR-010 closed 2026-11-14): Stage 1's web smoke
   * test exists (scripts/web_smoke.py — boots the standalone build in
   * headless Chromium, drives the sample return, and reloads mid-flow to
   * exercise the localStorage persist/rehydrate path that double-mounting
   * stresses in dev). */
  reactStrictMode: true,
};

export default nextConfig;
