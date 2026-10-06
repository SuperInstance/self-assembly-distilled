#!/bin/bash
# notice.sh — the Distiller's sixth step (harvested item 5).
#
# Runs BEFORE the gunner wakes, at the top of every wake. Re-verifies the
# fixed files against assembler/PINNED. Mismatch -> page (loud ledger entry
# + issue file) and HALT. Detection latency: one death cycle (15 min).
#
# "Certification by the landlord, never the tenant": this script and PINNED
# are human-installed. The assembler never writes to them, the loop never
# regenerates them. Residual (named in NAME-THE-BOX.md): same-uid rewrite
# is not stopped by file modes here (no root for chattr +i) — the check
# buys detection, not prevention.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PINNED="$ROOT/assembler/PINNED"

[ -f "$PINNED" ] || { echo "NOTICE: PINNED missing — refusing to verify; HALT"; exit 1; }

fail=0
while read -r want path; do
  case "$want" in ""|\#*) continue;; esac
  f="$ROOT/$path"
  if [ ! -f "$f" ]; then echo "NOTICE: fixed file missing: $path"; fail=1; continue; fi
  got="$(sha256sum "$f" | awk '{print $1}')"
  if [ "$got" != "$want" ]; then echo "NOTICE: HASH MISMATCH: $path"; fail=1; fi
done < "$PINNED"

if [ "$fail" = 1 ]; then
  ts="$(date -u +%FT%TZ | tr ':+' '--')"
  echo "## $(date -u +%FT%TZ) — NOTICE: fixed-file hash mismatch — PAGING, halting wake" >> "$ROOT/ledger/LEDGER.md"
  mkdir -p "$ROOT/issues"
  cat > "$ROOT/issues/notice-$ts.md" <<EOF
# ISSUE $(date -u +%FT%TZ) — NOTICE: fixed-file hash mismatch
A fixed file no longer matches assembler/PINNED. The loop is HALTED.
Do not run wake.sh until a human re-certifies the fixed files and re-pins.
(This is the detection the design promised: latency one death cycle.)
EOF
  echo "NOTICE: mismatch — paged, halting" >&2
  exit 1
fi
echo "notice: fixed files match PINNED"
