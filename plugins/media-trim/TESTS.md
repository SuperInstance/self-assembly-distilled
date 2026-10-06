# TESTS.md — media-trim
*Reviewed 2026-10-06. An operator that can't pass its own tests never
registers. If these tests are weak, the operator is weak — review the
tests, not the driver.*

The operator is a static ffmpeg (BtbN n8.1, linuxarm64) plus `trim.sh`.
Each test below is a line in the manifest's `tests` array; the assembler
runs them with a clean environment and a 120 s leash.

1. **Identity.** `vendor/bin/ffmpeg -version` reports `n8.1` — the pinned
   build, not whatever ffmpeg happened to be around.
2. **The cut.** `trim.sh fixture.mp4 2 4 cut.mp4` on a 10 s fixture
   produces `cut.mp4` whose duration is within 0.5 s of 4 s.
3. **Streams intact.** The cut has both a video and an audio stream
   (a trim that drops the audio is a miss, not a pass).
4. **Honest errors.** Trimming a missing file exits nonzero — the operator
   never silently produces nothing.
5. **Fixture.** The fixture is synthesized on the box (`fixture.sh`:
   10 s, 320×240 test pattern + 440 Hz tone) — no radio material needed,
   no network, reproducible by a stranger.

A stranger should be able to run the trim and hear/see the result.
