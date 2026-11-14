import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  /* Type errors are now surfaced: `npx tsc --noEmit` is clean and runs in
   * CI (Stage-0 gate, ADV-ENG #6). If a build breaks on types, fix the
   * types — do not re-enable this flag. */
  typescript: {
    ignoreBuildErrors: false,
  },
  /* reactStrictMode stays off pending ADR-010 (harness/memory/DECISIONS.md):
   * strict-mode double-mounting exercises the localStorage persist path,
   * which has no tests yet. Flip it on with Stage 1's web smoke tests. */
  reactStrictMode: false,
};

export default nextConfig;
