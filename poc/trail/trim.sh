#!/bin/bash
# trim.sh — the media-trim operator's friendly front end.
# Usage: trim.sh <in> <start-sec> <dur-sec> <out>
# Hand-built (harvested item 12: the first operator is hand-written).
# Re-encodes for sample-accurate cuts; exits nonzero on any failure.
set -u
D="$(cd "$(dirname "$0")" && pwd)"
FF="$D/vendor/bin/ffmpeg"
[ $# = 4 ] || { echo "usage: trim.sh <in> <start> <dur> <out>" >&2; exit 2; }
[ -f "$1" ] || { echo "trim: no such input: $1" >&2; exit 1; }
[ -x "$FF" ] || { echo "trim: ffmpeg not installed at $FF" >&2; exit 1; }
exec "$FF" -hide_banner -loglevel error -y -ss "$2" -i "$1" -t "$3" \
  -c:v libx264 -preset veryfast -c:a aac "$4"
