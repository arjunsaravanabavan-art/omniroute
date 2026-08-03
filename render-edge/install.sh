#!/usr/bin/env bash
set -euo pipefail

# OmniRoute — Render free-tier install (512MB).
#
# Skips the ~2-3GB of optional ML/native packs (npm ci --omit=optional):
#   @huggingface/transformers, @tensorflow/tfjs, @atjsh/llmlingua-2,
#   js-tiktoken, wreq-js, tls-client-node, keytar
# while better-sqlite3 (now a regular dependency) still installs with
# its prebuilt Linux x64 binary.
#
# DevDependencies are KEPT here on purpose: Tailwind / PostCSS / TypeScript
# live in devDependencies and are required by Next.js's production CSS and
# type-check build steps. They are pruned after the build (see build.sh) so
# the runtime footprint stays small.
#
# Safety: every postinstall hook guards missing packages
# (fixTlsClientNodeBinary, fixWreqJsBinary, ensureLlmlinguaOptionals all
# early-return when node_modules/tls-client-node is absent), so this install
# completes cleanly without the optional packs.

echo "[install] node $(node -v) / npm $(npm --version)"

npm ci --omit=optional --no-audit --no-fund

# Next.js 16's config loader imports @parcel/watcher at startup (via the
# next-intl plugin chain), and next-intl lists @parcel/watcher as a REGULAR
# dependency — but @parcel/watcher's platform binary is itself an OPTIONAL
# dependency (@parcel/watcher-linux-x64-glibc), so the `npm ci --omit=optional`
# above installs the JS wrapper without its native binary and the build dies
# with "No prebuild or local build of @parcel/watcher found" before `next build`
# even starts. Re-installing @parcel/watcher (pinned to the lockfile resolution)
# pulls that one tiny napi binary back in (with --no-save, so package.json /
# package-lock.json stay untouched) WITHOUT restoring the ~2-3GB of optional
# ML/native packs (transformers, tfjs, tiktoken, keytar, ...) that
# --omit=optional is deliberately avoiding on the 512MB build instance.
npm install --no-save --no-audit --no-fund @parcel/watcher@2.5.6

echo "[install] completed in ${SECONDS}s"
du -sh node_modules 2>/dev/null || true
