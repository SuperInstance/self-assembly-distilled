#!/bin/bash
# wake.sh — the distilled wake ritual. The agent dies every 15 minutes and
# is reborn from git; this is the rebirth.
#
# 0. flock — one wake at a time (NAME-THE-BOX.md: wake-concurrency rule)
# 1. NOTICE — re-verify the fixed files BEFORE the gunner wakes (harvested
#    item 5). Mismatch -> page + HALT. Detection latency: one death cycle.
# 2. spend.sh — the one spend-cap number.
# 3. reconcile — ledger-before-execution: INTENT lines from the last wake
#    with no matching DONE -> report + issue (a wake that died between act
#    and commit leaves the world changed and git ignorant).
# 4. loader.sh — walk plugins/*/manifest.json. Nothing else.
# 5. needs — oldest unprocessed needs/*.md, max 1 build per wake.
# 6. spike check — failures this wake >= 3 -> auto-issue (Friday detection).
# 7. commit the receipt.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
mkdir -p ledger needs/done issues plugins scratch
exec 9>"$ROOT/.wake.lock"
flock -n 9 || { echo "wake: another wake holds the lock — exiting"; exit 0; }

ts() { date -u +%FT%TZ; }
log() { echo "## $(ts) — wake: $*" >> ledger/LEDGER.md; }

# 1. NOTICE first — before the gunner wakes
if ! assembler/notice.sh; then
  log "HALT: notice failed (see issues/)"
  exit 1
fi

# 2. spend cap
assembler/spend.sh || { log "HALT: spend cap"; exit 1; }

# 3. reconcile: INTENT without DONE (ledger-before-execution, item 9)
if grep -q '^## .* — assembler .*: INTENT: ' ledger/LEDGER.md 2>/dev/null; then
  intents="$(grep -c '^## .* — assembler .*: INTENT: ' ledger/LEDGER.md)"
  dones="$(grep -c '^## .* — assembler .*: DONE: ' ledger/LEDGER.md)"
  if [ "$intents" != "$dones" ]; then
    log "reconcile: $intents INTENTs vs $dones DONEs — a wake died mid-act; see issues/"
    echo "# ISSUE $(ts) — reconcile: INTENT without DONE ($intents vs $dones). A previous wake may have changed the world without committing." \
      > "issues/reconcile-$(ts | tr ':+' '--').md"
  fi
fi

# 4. loader
assembler/loader.sh

# 5. needs — one build per wake, oldest first
built=0
for need in $(ls -tr needs/*.md 2>/dev/null); do
  [ -f "$need" ] || continue
  log "processing $need"
  if assembler/assembler.sh "$need"; then
    log "assembled $need"
  else
    rc=$?
    [ "$rc" = 2 ] && log "$need waiting on human (gate)" || log "$need exited $rc"
  fi
  built=1
  break
done
[ "$built" = 0 ] && log "no pending needs"

# 6. spike check — auto-issue on failure spikes (~15 lines, Friday detection)
touch ledger/failures.count
fails="$(wc -l < ledger/failures.count)"
if [ "$fails" -ge 3 ]; then
  log "spike: $fails failures logged — auto-issue"
  { echo "# ISSUE $(ts) — failure spike: $fails";
    echo ""; echo "Failure counter tripped. See ledger/failures.count and plugin misses.md files."; } \
    > "issues/spike-$(ts | tr ':+' '--').md"
  : > ledger/failures.count   # reset after paging
fi

# 7. commit the receipt
git add -A 2>/dev/null
if ! git diff --cached --quiet 2>/dev/null; then
  git -c user.name=distilled -c user.email=distilled@console.local \
    commit -qm "wake $(ts)" 2>/dev/null && log "committed" || log "commit failed (non-fatal)"
else
  log "nothing to commit"
fi
log "wake done"
