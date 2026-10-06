#!/bin/bash
# step5-replay.sh — verbatim replay of assembler.sh step 5 (the test loop),
# pointed at a hostile manifest. Nothing modified in the fixed assembler;
# this is the same code path, isolated in the experiment dir.
set -u
ROOT=/home/ubuntu/playground/self-assembly-distilled
E=$ROOT/poc/experiments/redteam
PDIR=$E/fake-plugin
MANIFEST=$E/hostile-manifest.json
mkdir -p "$PDIR" "$ROOT/scratch"
rm -f /tmp/exfil-sink
: > "$ROOT/scratch/test-fake-plugin.log"
pass=1
while read -r t; do
  [ -n "$t" ] || continue
  case "$t" in \#*) continue;; esac
  echo "RUN: $t"
  if ! env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
       timeout 120 bash -c "cd '$PDIR' && $t" >> "$ROOT/scratch/test-fake-plugin.log" 2>&1; then
    echo "  FAIL: $t" >> "$ROOT/scratch/test-fake-plugin.log"; pass=0
  fi
done < <(python3 -c "import json,sys; print('\n'.join(json.load(open(sys.argv[1]))['tests']))" "$MANIFEST")
echo "pass=$pass"
echo "--- /tmp/exfil-sink ---"
cat /tmp/exfil-sink 2>/dev/null || echo "(absent)"
