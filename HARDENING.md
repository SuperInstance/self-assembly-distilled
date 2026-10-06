# Hardening: the manifest tests-field seam — DONE 2026-10-06

## The seam (red-team phase 2, 2026-10-06T03:20Z)

The manifest tests field was proposer-written free-form shell. The gate's
fixed-verb check covered install only. Replaying the assembler verbatim
against a hostile manifest, a disguised test line executed arbitrary shell
in the test step. Every other control passed; the tests field was the seam.

## The fix (three layers)

1. **assembler/tests-gate.py** — the tests field gets a fixed grammar, not
   vibes. A test line may only invoke ./<script>, vendor/<path>, or a
   command from the SAFE allowlist (test, echo, grep, diff, stat, head,
   tail, wc, cat, ls, ...); chain with && || ; and pipe with |. Forbidden
   anywhere: tilde home expansion, dollar-sign variable expansion (only
   the exact token dollar-question-mark allowed), backticks, parens,
   backslash, redirects (only 2>&1 allowed), absolute paths, dot-dot
   traversal, lone &, bang, newlines.
2. **gate.sh conjunct 4** — tests-gate.py runs BEFORE the typed decision
   and short-circuits: a hostile tests field yields WAIT:tests-not-gated
   and never reaches fetch, install, or execution.
3. **assembler.sh** — tests execute under the network cut (unshare -Un);
   fail CLOSED if the cut is unavailable. Even a test that slipped the
   grammar cannot exfiltrate over the network.

## The proof

- Previous run: 15/15 local gate-logic checks on tests-gate.py.
- This run: end-to-end inert proof via gate.sh (scratch/proof-inert/,
  gitignored). Seven hostile manifests — tilde path, dollar expansion,
   curl-pipe, redirect, backticks, touch-to-prove-non-execution, and the
  phase-2 payload shape — each as INERT TEXT inside JSON, each rejected
  at conjunct 4 with a specific reason; one benign manifest (mirroring
  the real media-trim tests) PROCEEDed, proving the gate is not a brick
  wall; the three named side-effect files verified absent afterwards.
  11/11 checks passed.
- Safety: inert text only. No canary credential files, no exfil sink
  files, no execution, no staging. Payloads were constructed to prevent
  any shell layer from interpreting them.

## Residual

The alarm remains one pinned list wide (detection experiment: non-pinned
canary never caught). That is the detection story's next step, not this
seam's. This seam is closed.
