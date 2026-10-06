# self-assembly-distilled

The distilled self-assembly loop (Design Council build order, 2026-10-06).
One page of machinery; the 15-minute death cycle does the rest.

**The essence:** the agent dies every wake and is reborn from git. The next
wake *is* the reload; `git revert` *is* the uninstall. What survives is a
directory of equipment, a receipt per tool (manifest.json: what was
fetched, with what hash), and one rule: **the gunner never builds the gun.**

## The loop

1. **Want.** Agent writes `needs/<name>.md` — capability + why.
2. **Gate.** PROCEED iff: source host in `allowlist.txt` (fused provenance
   law) AND install is the fixed verb AND the human approved. Else the gate
   files an issue and waits — the human gate is load-bearing.
3. **Build.** The fixed assembler (hash-checked at wake by `notice.sh`
   BEFORE anything runs) fetches the tarball, verifies sha256 against the
   manifest pin AND a second independently-fetched source, installs per the
   fixed verb, runs the manifest's tests.
4. **Learn.** Tests pass → commit; the loader picks it up next wake. Tests
   fail → the miss goes into `misses.md`, max 2 retries, then parked with
   an issue. Failures are the curriculum.
5. **Run.** The loader walks `plugins/*/manifest.json` at wake. Nothing
   else. No registry file — the directory is the registry.

## Files

- `wake.sh` — the ritual: flock → Notice → spend-cap → reconcile →
  loader → one need → spike check → commit.
- `assembler/` — the fixed files: `assembler.sh` (the gun), `notice.sh`
  (the landlord's hash check), `gate.sh`, `loader.sh`, `spend.sh`,
  `inspect.py`, `PINNED` (pinned hashes — the landlord's cert).
- `distilled.mx` — typed manifest validation + typed gate decisions
  (murex; typed pass/fail with reasons, no string-matching).
- `needs/` — wants; `needs/done/` — fulfilled.
- `plugins/<name>/` — `manifest.json` (the receipt), `TESTS.md` (the
  gate — review the tests, not the driver), `misses.md`, `vendor/`
  (installed bits, gitignored, re-fetchable), `BUILD.jsonl`.
- `issues/` — gate waits, parks, spikes, Notice pages.
- `ledger/LEDGER.md` — append-only; INTENT before every irreversible act.
- `poc/` — the Easter egg: the loop growing a real operator for the
  Radio Hour. Start at `poc/README.md`.

## The compass

"Automate the verifiable, gate the judgmental." Builds, tests, installs:
automated (checkable). Acquire, touch the world, extend the trust
boundary: human gate (judgment). See DESIGN.md.

## v2 north star

"Fetched code never runs in a job that can mint a vault token." This is
v1; the seam is visible and clean — see NETWORK-CUT.md for the experiment
that decides what v2 must build.
