#!/bin/bash
# verify-cut.sh — assert a trimmed clip's duration and streams.
# Usage: verify-cut.sh <file> <expected-dur-sec>
set -u
D="$(cd "$(dirname "$0")" && pwd)"
FP="$D/vendor/bin/ffprobe"
f="$1"; want="$2"
dur="$("$FP" -v error -show_entries format=duration -of csv=p=0 "$f")"
kinds="$("$FP" -v error -show_entries stream=codec_type -of csv=p=0 "$f" | sort -u | tr '\n' ' ')"
python3 - "$dur" "$want" "$kinds" <<'EOF'
import sys
dur, want, kinds = float(sys.argv[1]), float(sys.argv[2]), sys.argv[3]
assert abs(dur - want) < 0.5, f"duration {dur}, want {want}"
assert "video" in kinds and "audio" in kinds, f"streams: {kinds}"
print(f"cut OK: {dur:.2f}s (want {want}s), streams: {kinds.strip()}")
EOF
