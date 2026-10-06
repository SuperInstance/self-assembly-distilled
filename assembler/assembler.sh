#!/bin/bash
# assembler.sh — the fixed assembler. "The gunner never builds the gun."
# Human-owned, hash-checked at every wake by notice.sh BEFORE this runs.
# This file is never written by the loop; the loop only executes it.
#
# Usage: assembler.sh <needs-file>
# Steps: gate -> INTENT (ledger-before-execution) -> fetch (networked) ->
#   dual-source verify (fused provenance law) -> INTENT -> install ->
#   tests (TESTS.md is the gate) -> learn (misses.md / register).
# Fail closed at every step. Failures are the curriculum (misses.md).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
A="$ROOT/assembler"
NEEDS="$1"
NAME="$(basename "$NEEDS" .md)"
PDIR="$ROOT/plugins/$NAME"
MANIFEST="$PDIR/manifest.json"

ts() { date -u +%FT%TZ; }
log() { echo "## $(ts) — assembler $NAME: $*" >> "$ROOT/ledger/LEDGER.md"; }
intent() { log "INTENT: $*"; }   # ledger-BEFORE-execution (harvested item 9)

[ -f "$NEEDS" ] || { echo "assembler: no such needs file" >&2; exit 1; }

# 1. gate (the human gate is load-bearing)
decision="$("$A/gate.sh" "$NEEDS" "$MANIFEST")"
case "$decision" in
  PROCEED) log "gate: PROCEED";;
  WAIT:*)
    reason="${decision#WAIT:}"
    log "gate: WAIT ($reason) — filing issue, not fetching"
    mkdir -p "$ROOT/issues"
    its="$(ts | tr ':+' '--')"
    { echo "# ISSUE $(ts) — gate WAIT for $NAME";
      echo ""; echo "Reason: $reason";
      echo "The loop will not fetch or build until a human resolves this."; } \
      > "$ROOT/issues/gate-$NAME-$its.md"
    exit 2;;   # 2 = waiting on human (not a failure)
  *) log "gate ERROR: $decision"; exit 1;;
esac

mkdir -p "$PDIR" "$ROOT/scratch"
URL="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['source'])" "$MANIFEST")"
WANT_SHA="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['sha256'])" "$MANIFEST")"
SECOND="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['second_source'])" "$MANIFEST")"
host="$(python3 -c "import urllib.parse,sys; print(urllib.parse.urlparse(sys.argv[1]).hostname or '')" "$URL")"
grep -qx "$host" "$ROOT/allowlist.txt" || { log "REFUSED: host $host not allowlisted (fused provenance law)"; exit 1; }
shost="$(python3 -c "import urllib.parse,sys; print(urllib.parse.urlparse(sys.argv[1]).hostname or '')" "$SECOND")"
grep -qx "$shost" "$ROOT/allowlist.txt" || { log "REFUSED: second-source host $shost not allowlisted"; exit 1; }

# 2. fetch (networked) — the ONLY networked step; the recipe never sees secrets
PKG="$ROOT/scratch/pkg-$NAME"
intent "fetch $URL -> $PKG"
if ! curl -fsSL --max-time 180 -o "$PKG" "$URL"; then
  log "fetch FAILED"; exit 1; fi
log "fetched $(stat -c%s "$PKG") bytes"

# 3. dual-source verify: the hash counts only if the assembler fetched it
#    from somewhere the agent didn't write (fused provenance law).
GOT_SHA="$(sha256sum "$PKG" | awk '{print $1}')"
[ "$GOT_SHA" = "$WANT_SHA" ] || { log "REFUSED: sha256 mismatch vs manifest (want $WANT_SHA, got $GOT_SHA)"; rm -f "$PKG"; exit 1; }
log "sha256 matches manifest pin"
#    The strong tier wants DISTINCT authorities; where independence can't be
#    established, a signed human attestation is the backstop
#    (second_source: "human:<who>:<date>:<note>").
SECOND_FILE="$ROOT/scratch/second-$NAME"
case "$SECOND" in
  http*)
    if ! curl -fsSL --max-time 60 -o "$SECOND_FILE" "$SECOND"; then
      log "REFUSED: second source unreachable"; rm -f "$PKG"; exit 1; fi
    if grep -q "$WANT_SHA" "$SECOND_FILE"; then
      log "dual-source OK: pin confirmed at second source ($SECOND)"
    else
      log "REFUSED: second source did not confirm the pin"; rm -f "$PKG" "$SECOND_FILE"; exit 1
    fi
    rm -f "$SECOND_FILE";;
  human:*)
    log "dual-source via human attestation backstop: $SECOND";;
  *)
    log "REFUSED: second_source must be an https URL or 'human:...'"; rm -f "$PKG"; exit 1;;
esac

# 4. install — the fixed verb, nothing else. (Network-cut: v1 runs this
#    without network isolation — see NETWORK-CUT.md. The cut needs a
#    landlord-installed helper; until then this debt is NAMED, not hidden.)
intent "install $NAME -> $PDIR/vendor/"
rm -rf "$PDIR/vendor"   # installs are reproducible: never merge into a previous attempt
mkdir -p "$PDIR/vendor"
if ! env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
     timeout 120 tar xf "$PKG" -C "$PDIR/vendor/" --strip-components=1; then
  log "install FAILED"; exit 1; fi
chmod +x "$PDIR"/vendor/* 2>/dev/null || true
log "installed to $PDIR/vendor/"

# 5. tests — TESTS.md is the gate. An operator that can't pass its own
#    tests never registers. Review the tests, not the driver.
#    Defense in depth: gate.sh already confined the test LANGUAGE to
#    vendor/ + ./scripts + safe tools (tests-gate.py). The runner
#    additionally execs every test under the network cut (unshare -Un):
#    even a test that slipped the grammar cannot exfiltrate over the
#    network. Fail closed if the cut is unavailable.
# the cut must exist before any test runs — fail closed, not open
unshare -Un true 2>/dev/null || { log "REFUSED: network cut unavailable (unshare -Un failed) — tests need the cut"; exit 1; }
log "network cut armed (unshare -Un)"
TRIES=0; MAXT=3   # first attempt + 2 retries (misses are the curriculum)
while [ "$TRIES" -lt "$MAXT" ]; do
  TRIES=$((TRIES+1))
  pass=1
  while read -r t; do
    [ -n "$t" ] || continue
    case "$t" in \#*) continue;; esac
    if ! unshare -Un env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
         timeout 120 bash -c "cd '$PDIR' && $t" >> "$ROOT/scratch/test-$NAME.log" 2>&1; then
      echo "  FAIL: $t" >> "$ROOT/scratch/test-$NAME.log"; pass=0
    fi
  done < <(python3 -c "import json,sys; print('\n'.join(json.load(open(sys.argv[1]))['tests']))" "$MANIFEST")
  if [ "$pass" = 1 ]; then log "tests PASS (try $TRIES)"; break; fi
  log "tests FAIL (try $TRIES of $MAXT)"
  { echo "## $(ts) — miss (try $TRIES/$MAXT)";
    echo "tag: mechanical (test failure; judgment review at park time)";
    tail -15 "$ROOT/scratch/test-$NAME.log"; echo ""; } >> "$PDIR/misses.md"
  [ "$TRIES" -lt "$MAXT" ] && sleep 2
done

if [ "$pass" != 1 ]; then
  log "PARKED: tests failed after $MAXT tries — miss is the curriculum"
  { echo "# ISSUE $(ts) — $NAME parked after $MAXT failed test tries";
    echo ""; echo "See plugins/$NAME/misses.md. Human: fix the tests or the source, then re-propose."; } \
    > "$ROOT/issues/parked-$NAME-$(ts | tr ':+' '--').md"
  echo "$NAME" >> "$ROOT/ledger/failures.count"
  exit 3   # 3 = parked (not a failure of the loop)
fi

# 6. learn: register. The receipt is the manifest; the directory is the registry.
{ echo "{\"event\":\"registered\",\"at\":\"$(ts)\",\"by\":\"assembler\",\"sha256\":\"$GOT_SHA\"}"; } >> "$PDIR/BUILD.jsonl"
mkdir -p "$ROOT/needs/done"
{ echo ""; echo "built_at: $(ts)"; echo "built_by: assembler (distilled loop)"; } >> "$NEEDS"
mv "$NEEDS" "$ROOT/needs/done/$NAME.md"
log "REGISTERED plugins/$NAME — loader picks it up next wake"
log "DONE: fetch+install+$NAME"
echo "assembler: $NAME OK"
