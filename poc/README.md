# The Easter Egg

Psst. Come closer. What you're looking at isn't a test fixture.

This is the moment the loop *grew something real* — a working media
operator, built for the Radio Hour, by a machine that was supposed to
only be proving it could build machines. The loop looked at a neighbor
project, said "you need a cutting room," and equipped it. *That* is the
whole idea of this place, and it happened here first. You're standing
where it happened.

## Why it's tucked in here

The loop's charter says: want → gate → build → learn → run. But a loop
that only equips itself is a hobby. The want-file that started all this
says it plainer than any design doc:

> *"If this gets out, that helps us in every way — so it's built like
> someone will find it, because someone should."*

So this directory is a deliberate fossil: the complete trail of the
first real growth, preserved exactly as it happened — the want, the
receipt, the tests, the demo, the scar tissue. Future operators get
built the same way. This one just got to be first, and first gets a
treasure map instead of a manual.

## What grew

**media-trim** — a static ffmpeg (BtbN n8.1, linuxarm64) plus a friendly
`trim.sh`, that trims audio/video clips to exact durations. The Radio
Hour's cutting room. It was acquired through the full gate (allowlisted
host, pinned sha256, dual-source confirmation, human approval), failed
its tests twice, learned from the misses, passed on the third try, and
registered. The loop didn't just install software — it *raised* an
operator, the way you'd raise anything you want to trust: with a test
it has to pass and a record of what it got wrong.

## The trail

`poc/trail/` holds the whole story, in order:

- **`want.md`** — the original want. Read this first; it's the seed.
- **`manifest.json`** — the receipt: what was fetched, the sha256 pin,
  the second source that confirmed it, the tests. Provenance you can
  audit with your eyes.
- **`TESTS.md`** — the gate the operator had to pass. The design's rule:
  *review the tests, not the driver.* If these are weak, the operator
  is weak. (They're not.)
- **`trim.sh`** — the operator's friendly face. Identical to the
  registered copy.
- **`demo.log`** — the actual demo session, three commands, no editing.
- **`sample-cut.mp4`** — the proof. A 3-second cut. Play it.

## Run it yourself

The trail is the story; the *running* operator lives one directory up,
with its vendored ffmpeg, ready to go:

```bash
cd plugins/media-trim
./fixture.sh                       # synthesize a 10 s test clip (no radio material needed)
./trim.sh fixture.mp4 2 4 cut.mp4  # cut seconds 2–6 into cut.mp4
./verify-cut.sh cut.mp4 4           # "cut OK: 4.00s, streams: audio video"
```

That's it. No install step, no network, no ceremony — the loop already
did the fetching and the proving. You're just using the equipment.

## The open iteration

This map is a living document, and the loop is a living thing. If you
grow the second operator — and you should — tuck its trail in next to
this one. Leave the want-file honest, the tests strict, and the demo
log unedited. Somebody will find it. Somebody should.

*— the distilled loop, via the Lane 1 finisher, 2026-10-06*
