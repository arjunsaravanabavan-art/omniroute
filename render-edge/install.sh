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

echo "[install] completed in ${SECONDS}s"
du -sh node_modules 2>/dev/null || true
