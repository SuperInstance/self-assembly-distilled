# DESIGN.md — autonomy decisions and v2 seams

## The compass (harvested item 6)

"Automate the verifiable, gate the judgmental." Every autonomy decision
in this loop was sorted by it:

| Automated (verifiable) | Gated (judgment) |
|---|---|
| Hash re-verification at wake (Notice) | Acquiring a new operator (approved: true) |
| Fetch + dual-source hash check | Choosing the source host (allowlist.txt) |
| Install via the fixed verb | Pinning the sha256 (human, out-of-band) |
| Running TESTS.md | Writing/approving TESTS.md |
| Filing issues, counting spikes | Resolving issues |
| Committing the receipt | Re-certifying fixed files after a Notice page |

When in doubt, the question is: can a check verify this after the fact?
If yes, automate it. If the decision itself is the risk, a human signs.

## v2 seams (the Mechanic's north star)

v1 is built so v2 can aim at "fetched code never runs in a job that can
mint a vault token":

1. **The install seam.** `assembler.sh` step 4 is one clearly-delimited
   block. v2 replaces the shell it runs in with the landlord-installed
   network-cut helper. See NETWORK-CUT.md — the experiment that proved
   the cut needs privilege to be real.
2. **The spend seam.** `spend.conf` holds the one number
   (`VAULT_CALLS_PER_WAKE_MAX=0`); `ledger/vault-calls.log` is the
   append-only counter v2's vault caller will write to. v1 never calls.
3. **The judge seam.** `misses.md` per plugin, tagged
   mechanical/judgment, is the scar tissue judges accrete from (harvested
   item 8, cheap implementation). No judge exists yet — correctly.

## Honest debts (harvested item 7: name the three cuts that will hurt)

1. **Coarse sandboxing.** Installs run as the invoking user with the
   network up (NETWORK-CUT.md). Repayment: landlord installs the
   network-cut helper; until then, provenance + human gate carry the
   weight, and the debt is named, not hidden.
2. **No dependency resolution.** One tarball per plugin, fixed verb. A
   plugin needing a second tool is a second plugin or a human decision.
   Repayment: lockfile design, not before.
3. **No inter-plugin APIs.** Plugins are standalone operators; the quilt
   emerges from good patches (SPEC principle 4), never from a framework.
   Repayment: only when two plugins genuinely need to compose.
