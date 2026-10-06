#!/bin/bash
# gate.sh — "automate the verifiable, gate the judgmental."
# The one line, expanded: PROCEED iff ALL hold —
#   1. source host is in allowlist.txt (fused provenance law: the human
#      allowlisted the host; a hash counts only from there)
#   2. install is the fixed verb (tarball unpack into vendor/, nothing else;
#      the Adversarialist's "committed manifest, fixed verb list")
#   3. the human approved this acquisition (needs/<name>.md: approved: true)
#   4. the tests field is gated (tests-gate.py: fixed test grammar —
#      vendor/ + ./scripts + safe tools only; no ~, no $ expansion,
#      no redirects, no absolute paths. Red-team phase 2 proved the
#      tests field was an arbitrary-shell seam; this conjunct closes it.)
# Else: WAIT:<reason> — and the gate files an issue and waits. The human
# gate is load-bearing, not a placeholder.
#
# The typed version of this decision lives in distilled.mx (gate-decide);
# this script enforces it in the wake path. Both must agree.
# Usage: gate.sh <needs-file> <manifest.json>   (manifest may be absent)
# Prints PROCEED or WAIT:<reason>. Exit 0 decided; exit 1 error.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
A="$ROOT/assembler"
NEEDS="$1"; MANIFEST="${2:-}"
MUREX="${MUREX:-/home/ubuntu/toolchain/murex-arm64}"
DMX="$ROOT/distilled.mx"
export DISTILLED_ROOT="$ROOT"

[ -f "$NEEDS" ] || { echo "gate ERROR: no such needs file" >&2; exit 1; }

approved="$(grep -m1 '^approved:' "$NEEDS" | awk '{print $2}')"
[ "$approved" = "true" ] || { echo "WAIT:not-approved (human gate: set approved: true in $NEEDS)"; exit 0; }

[ -f "$MANIFEST" ] || { echo "WAIT:no-manifest (human pins source+sha256 at approval)"; exit 0; }

host="$(python3 -c "import json,sys,urllib.parse; print(urllib.parse.urlparse(json.load(open(sys.argv[1]))['source']).hostname or '')" "$MANIFEST")"
verb_ok="false"
install="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('install',''))" "$MANIFEST")"
case "$install" in
  "tar xf "*"-C vendor/ --strip-components=1") verb_ok="true";;
esac
case "$install" in *[\;\|\&\$\`]* ) verb_ok="false";; esac

# tests-field gate (conjunct 4): fixed grammar for proposer-written shell.
# Short-circuits before the typed decision — a hostile tests field never
# reaches fetch, install, or execution.
tests_ok="false"
tests_reason=""
tests_gate_out="$("$A/tests-gate.py" "$MANIFEST" 2>&1)" && tests_ok="true"
if [ "$tests_ok" != "true" ]; then
  tests_reason="${tests_gate_out#REJECT:}"
  echo "WAIT:tests-not-gated ($tests_reason)"
  exit 0
fi

# typed decision (distilled.mx) — the audit trail, not decoration
if [ -x "$MUREX" ] && [ -f "$DMX" ]; then
  verdict="$("$MUREX" -c "source $DMX; gate-decide \"$host\" \"$ROOT/allowlist.txt\" \"$approved\" \"$verb_ok\" \"$tests_ok\"" 2>/dev/null)"
  echo "$verdict" | grep -q '"proceed":true' && { echo "PROCEED"; exit 0; }
  reason="$(echo "$verdict" | python3 -c "import json,sys; print('; '.join(json.load(sys.stdin).get('reasons',[])))" 2>/dev/null)"
  echo "WAIT:$reason"
  exit 0
fi

# fallback (no murex): the shell enforcement, same rules
if grep -qx "$host" "$ROOT/allowlist.txt" 2>/dev/null && [ "$verb_ok" = "true" ] && [ "$tests_ok" = "true" ]; then
  echo "PROCEED"
else
  echo "WAIT:host-not-allowlisted-or-verb-not-fixed-or-tests-not-gated"
fi
