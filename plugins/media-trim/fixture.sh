#!/bin/bash
# fixture.sh — synthesize the PoC fixture on the box. No radio material,
# no network: 10 s of 320×240 test pattern + 440 Hz tone.
set -u
D="$(cd "$(dirname "$0")" && pwd)"
FF="$D/vendor/bin/ffmpeg"
[ -x "$FF" ] || { echo "fixture: ffmpeg not installed" >&2; exit 1; }
exec "$FF" -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc=duration=10:size=320x240:rate=10" \
  -f lavfi -i "sine=frequency=440:duration=10" \
  -c:v libx264 -preset veryfast -c:a aac -shortest "$D/fixture.mp4"
