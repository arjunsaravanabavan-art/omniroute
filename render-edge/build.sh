#!/usr/bin/env bash
set -euo pipefail

# OmniRoute — Render free-tier build (512MB, 15-minute build window).
#
# Memory strategy:
#   - OMNIROUTE_BUILD_MEMORY_MB=3840 caps the Next.js webpack JS heap well
#     below the free instance's 512MB RAM.
#   - OMNIROUTE_USE_TURBOPACK=0 forces webpack. Turbopack's native Rust
#     memory is off the V8 heap and unbounded, so on a 512MB box it OOMs
#     even with a small --max-old-space-size. Webpack respects the cap.
#   - NEXT_TELEMETRY_DISABLED avoids a background telemetry process eating RAM.
#
# NOTE: OMNIROUTE_BUILD_BACKEND_ONLY=1 is intentionally NOT set — it stubs
# the dashboard UI. The full app (dashboard + API) is what we want.
#
# Cache: .build/next is gitignored, so the Turbopack/webpack cache does not
# need explicit pruning; rm -rf guarantees a fresh single build pass.

echo "[build] node $(node -v) / npm $(npm --version)"

export OMNIROUTE_BUILD_MEMORY_MB="${OMNIROUTE_BUILD_MEMORY_MB:-3840}"
export OMNIROUTE_USE_TURBOPACK=0
export NEXT_TELEMETRY_DISABLED=1

# Clear any previous build artifacts for a clean, deterministic build.
rm -rf .build dist

node scripts/build/build-next-isolated.mjs

echo "[build] next build completed in ${SECONDS}s"
du -sh .build 2>/dev/null || true

# Prune dev-only tooling now that the production bundle is emitted. Keeps the
# runtime footprint tiny on the 512MB free instance. Tailwind/PostCSS/TypeScript
# were only needed for the build itself.
npm prune --omit=dev --omit=optional --no-audit --no-fund

echo "[build] node_modules after prune:"
du -sh node_modules 2>/dev/null || true
