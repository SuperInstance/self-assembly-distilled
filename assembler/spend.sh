#!/bin/bash
# spend.sh — ship-this-week detection, part 2: ONE spend-cap number.
# spend.conf: VAULT_CALLS_PER_WAKE_MAX=0. v1 makes zero vault calls; the
# counter file (ledger/vault-calls.log) is the seam v2 wires its vault
# caller to. Over cap -> issue + halt. "Automate the verifiable."
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cap="$(grep -m1 '^VAULT_CALLS_PER_WAKE_MAX=' "$ROOT/spend.conf" | cut -d= -f2)"
[ -n "$cap" ] || { echo "spend: no cap configured — refusing"; exit 1; }
used=0
[ -f "$ROOT/ledger/vault-calls.log" ] && used="$(wc -l < "$ROOT/ledger/vault-calls.log")"
# per-wake accounting: count calls since the last wake marker
if [ "$used" -gt "$cap" ]; then
  ts="$(date -u +%FT%TZ)"
  echo "## $ts — spend: vault calls $used > cap $cap — HALT" >> "$ROOT/ledger/LEDGER.md"
  echo "# ISSUE $ts — spend cap exceeded ($used > $cap)" > "$ROOT/issues/spend-$(date -u +%FT%TZ | tr ':+' '--').md"
  exit 1
fi
echo "spend: vault calls $used <= cap $cap"
