# NAME-THE-BOX.md — what persists outside git (harvested item 11)

"Nothing persists except via git" is already false. Undocumented
persistence doesn't vanish when the design refuses to name it. This is
the inventory, for this box (Oracle ARM, Ubuntu 26.04).

## Persists outside git, by design

- **`plugins/*/vendor/`** — installed bits. Rebuildable from the manifest
  (source + sha256); gitignored on purpose. A fresh clone re-fetches.
- **`scratch/`** — downloads, test logs. Ephemeral; safe to delete.
- **`/tmp`** — canary files, temp reasons. Ephemeral; wiped on reboot.
- **`ledger/vault-calls.log`** — append-only spend counter (v2 seam).
  In git once created, but appended at runtime.

## Persists outside git, as ambient fact

- **The ubuntu user's credentials** (`~/.ssh/`, API keys in env at wake
  time). The loop never isolates the filesystem (see NETWORK-CUT.md):
  fetched code runs as ubuntu and can read what ubuntu can read. The
  answer is provenance + the human gate, not isolation theater.
- **The wake lock** (`.wake.lock`) — one wake at a time (flock).
- **DNS / network / clock** — ambient, uncut in v1.

## The trust bootstrap (named, not solved)

- `assembler/PINNED` + `assembler/notice.sh` are the landlord's cert, but
  the landlord and the tenant share a uid here: no root for `chattr +i`,
  so same-uid rewrite is possible and only *detected* (next wake), not
  *prevented*. The check buys detection with one-wake latency — which is
  exactly what the harvested list asked for — but it is not prevention,
  and this file says so out loud.
- "Trust the initial codebase" is the weakest assumption. The council
  called it a tautology in a hi-vis vest; it is also true. The first
  `git init` + PINNED is the human's act. Everything after is verified
  against it.

## Restore drill

Fresh clone → `assembler/notice.sh` → `assembler/loader.sh` → `wake.sh`:
vendor/ re-fetches from manifests, needs/ re-processes. (Run once for
real before calling this production.)
