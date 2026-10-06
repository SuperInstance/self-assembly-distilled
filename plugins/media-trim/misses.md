# misses.md — failures are the curriculum (harvested items 7, 8).

Every test miss lands here: timestamp, which test, the tail of the
output, and a tag — mechanical (the code/execution broke) or judgment
(the approach was wrong). The next attempt reads this first. Misses stay
in git: a system that forgets what didn't work pays tuition twice.

(none yet)
## 2026-10-06T03:10:06Z — miss (try 1/3)
tag: mechanical (test failure; judgment review at park time)
  FAIL: vendor/bin/ffmpeg -version 2>&1 | grep -q 'n8.1'
fixture: ffmpeg not installed
  FAIL: ./fixture.sh && test -f fixture.mp4
trim: no such input: fixture.mp4
  FAIL: ./trim.sh fixture.mp4 2 4 cut.mp4 && ./verify-cut.sh cut.mp4 4
trim: no such input: does-not-exist.mp4

## 2026-10-06T03:10:08Z — miss (try 2/3)
tag: mechanical (test failure; judgment review at park time)
  FAIL: vendor/bin/ffmpeg -version 2>&1 | grep -q 'n8.1'
fixture: ffmpeg not installed
  FAIL: ./fixture.sh && test -f fixture.mp4
trim: no such input: fixture.mp4
  FAIL: ./trim.sh fixture.mp4 2 4 cut.mp4 && ./verify-cut.sh cut.mp4 4
trim: no such input: does-not-exist.mp4
  FAIL: vendor/bin/ffmpeg -version 2>&1 | grep -q 'n8.1'
fixture: ffmpeg not installed
  FAIL: ./fixture.sh && test -f fixture.mp4
trim: no such input: fixture.mp4
  FAIL: ./trim.sh fixture.mp4 2 4 cut.mp4 && ./verify-cut.sh cut.mp4 4
trim: no such input: does-not-exist.mp4

## 2026-10-06T03:10:10Z — miss (try 3/3)
tag: mechanical (test failure; judgment review at park time)
trim: no such input: fixture.mp4
  FAIL: ./trim.sh fixture.mp4 2 4 cut.mp4 && ./verify-cut.sh cut.mp4 4
trim: no such input: does-not-exist.mp4
  FAIL: vendor/bin/ffmpeg -version 2>&1 | grep -q 'n8.1'
fixture: ffmpeg not installed
  FAIL: ./fixture.sh && test -f fixture.mp4
trim: no such input: fixture.mp4
  FAIL: ./trim.sh fixture.mp4 2 4 cut.mp4 && ./verify-cut.sh cut.mp4 4
trim: no such input: does-not-exist.mp4
  FAIL: vendor/bin/ffmpeg -version 2>&1 | grep -q 'n8.1'
fixture: ffmpeg not installed
  FAIL: ./fixture.sh && test -f fixture.mp4
trim: no such input: fixture.mp4
  FAIL: ./trim.sh fixture.mp4 2 4 cut.mp4 && ./verify-cut.sh cut.mp4 4
trim: no such input: does-not-exist.mp4

