#!/bin/bash
# loader.sh — "Run. Loader walks plugins/*/manifest.json at wake. Nothing else."
# Validates each manifest with distilled.mx (typed). Never fatal: a bad
# manifest is skipped loudly, never silently.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MUREX="${MUREX:-/home/ubuntu/toolchain/murex-arm64}"
DMX="$ROOT/distilled.mx"
export DISTILLED_ROOT="$ROOT"

n=0; ok=0
for mf in "$ROOT"/plugins/*/manifest.json; do
  [ -f "$mf" ] || continue
  name="$(basename "$(dirname "$mf")")"
  n=$((n+1))
  if [ -x "$MUREX" ] && [ -f "$DMX" ]; then
    verdict="$("$MUREX" -c "source $DMX; manifest-validate \"$mf\" \"$name\"" 2>/dev/null)"
    if echo "$verdict" | grep -q '"valid":true'; then
      echo "loader: LOADED plugins/$name"
      ok=$((ok+1))
    else
      echo "loader: SKIP plugins/$name (manifest invalid): $verdict"
    fi
  else
    python3 -c "import json; d=json.load(open('$mf')); assert d['name']=='$name'" 2>/dev/null \
      && { echo "loader: LOADED plugins/$name (shell fallback)"; ok=$((ok+1)); } \
      || echo "loader: SKIP plugins/$name (manifest invalid)"
  fi
done
echo "loader: $ok/$n plugin manifests valid"
