#!/usr/bin/env bash
set -euo pipefail

# OmniRoute — Render free-tier start (512MB RAM).
#
# The Next.js custom server (scripts/dev/run-next.mjs start) binds 0.0.0.0 on
# the dashboard port. Render's $PORT (10000) is forwarded, and the server
# picks it up via PORT as the dashboard port.
#
# Memory strategy:
#   - Node OOM killer on Render free has ~460MB of real RAM for the process.
#   - --max-old-space-size positions the V8 heap low enough to leave headroom
#     for SQLite WASM, native better-sqlite3, and request buffers.
#   - OMNIROUTE_MEMORY_MB=384 aligns the repo's own memory-gated features.
#   - NODE_OPTIONS is exported so a child process claiming to append a heap
#     flag only adds the same 384MB cap; nothing can clobber it back to 8GB.
#
# Reduce free-tier churn: DISABLE_SQLITE_AUTO_BACKUP=1 stops the DB backup
# job from waking up on the ephemeral free disk.

# Render injects PORT (default 10000). Keep our default for local smoke tests.
export PORT="${PORT:-10000}"

# Cap the V8 heap for the 512MB free instance.
export NODE_OPTIONS="--max-old-space-size=384"

# Align built-in memory-gated features (background jobs, caches, etc.).
export OMNIROUTE_MEMORY_MB=384

# No background DB backup on the ephemeral free disk.
export DISABLE_SQLITE_AUTO_BACKUP=1

# First boot: generate .env from the template if missing (bootstrapEnv reads it).
if [ ! -f ".env" ]; then
  cp .env.example .env
fi

exec node --max-old-space-size=384 scripts/dev/run-next.mjs start